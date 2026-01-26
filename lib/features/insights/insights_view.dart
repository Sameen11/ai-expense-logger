// import 'package:ai_expense_logger/common/colors.dart';
import 'package:ai_expense_logger/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:ai_expense_logger/navigation/nav_manager.dart';
import '../../services/export_service.dart';
import '../../services/gemini_service.dart';
import '../../utils/currency_utils.dart';
import '../../widgets/data_picker_dialog.dart';
import '../../widgets/export_bottom_sheet.dart';
import '../../widgets/notification_bar.dart';
import '../authentication/provider/auth_provider.dart';
import '../expenses/expenses_view.dart';
import 'all_categories_screen.dart';
import 'category_progress_item.dart';
import 'monthly_bar_chart.dart';
import 'category_detail_card.dart'; // Correctly placed import

class InsightsView extends StatefulWidget {
  const InsightsView({super.key});

  @override
  State<InsightsView> createState() => _InsightsViewState();
}

class _InsightsViewState extends State<InsightsView> {
  // State for AI Insights
  String? _aiAnalysis;
  String? _aiTip;
  int? _aiScore;
  bool _isLoadingAI = false;

  @override
  void initState() {
    super.initState();
    // Fetch initial insights after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAIInsights();
    });
  }

  // Trend Chart State
  bool _showCumulative = false;
  bool _showComparison = false;

  bool _isExporting = false;
  String _selectedCurrency = 'USD'; // Default currency

  @override
  void didUpdateWidget(covariant InsightsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final provider = context.read<ExpenseProvider>();
    // Refetch if the month changed
    if (provider.selectedMonth !=
        context.read<ExpenseProvider>().selectedMonth) {
      _fetchAIInsights();
    }
  }

  Future<void> _selectMonth(
    BuildContext context,
    ExpenseProvider provider,
  ) async {
    final DateTime? picked = await showCustomDatePicker(
      context: context,
      initialDate: provider.selectedMonth,
    );

    if (picked != null) {
      final newMonth = DateTime(picked.year, picked.month);
      if (newMonth != provider.selectedMonth) {
        provider.updateSelectedMonth(newMonth);
        _fetchAIInsights(); // Fetch new insights for new month
      }
    }
  }

  Future<void> _showExportOptions() async {
    final expenseProvider = context.read<ExpenseProvider>();
    final ExportFormat? format = await showExportBottomSheet(context);

    if (format == null || !mounted) return;

    setState(() {
      _isExporting = true;
    });

    try {
      final expenses = expenseProvider.expensesForSelectedMonth;
      if (expenses.isEmpty) {
        SnackBarUtils.showSuccess(context, 'No data to export for this month.');
        return;
      }

      final monthName = DateFormat(
        'yyyy-MM',
      ).format(expenseProvider.selectedMonth);

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Exporting ${expenses.length} expenses to ${format.name.toUpperCase()}...',
        );
      }

      await ExportService().exportExpenses(expenses, monthName, format);

      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Successfully exported to ${format.name.toUpperCase()}!',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Error exporting file: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
      }
    }
  }

  Future<void> _fetchAIInsights() async {
    final provider = context.read<ExpenseProvider>();
    final authProvider = context.read<AuthProvider>();

    if (provider.expensesForSelectedMonth.isEmpty) {
      setState(() {
        _aiAnalysis = "No expenses recorded for this month yet.";
        _aiTip = "Start tracking your spending to get AI-powered insights!";
        _aiScore = null;
      });
      return;
    }

    setState(() {
      _isLoadingAI = true;
    });

    try {
      final budget = authProvider.userProfile?.budget ?? 5000.0;
      final result = await GeminiService.generateSpendingInsights(
        provider.expensesForSelectedMonth,
        budget,
        _selectedCurrency,
      );

      if (mounted) {
        setState(() {
          if (result != null) {
            _aiAnalysis = result['analysis'];
            _aiTip = result['tip'];
            _aiScore = result['score'];
          } else {
            _aiAnalysis = "Could not generate insights at this time.";
            _aiTip = "Please check your internet connection and try again.";
            _aiScore = null;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _aiAnalysis = "Error generating insights.";
          _aiTip = "Please try again later.";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAI = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final expenseProvider = context.watch<ExpenseProvider>();
    final authProvider = context.watch<AuthProvider>();

    // Calculate total spent for the selected currency
    final totalSpent =
        expenseProvider.totalSpentByCurrency[_selectedCurrency] ?? 0.0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Insights',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Currency Switcher if multiple currencies exist
          if (expenseProvider.totalSpentByCurrency.keys.length > 1)
            PopupMenuButton<String>(
              icon: Icon(Icons.swap_horiz, color: theme.colorScheme.primary),
              tooltip: "Switch Currency",
              initialValue: _selectedCurrency,
              onSelected: (String newValue) {
                setState(() {
                  _selectedCurrency = newValue;
                  _fetchAIInsights();
                });
              },
              itemBuilder: (BuildContext context) {
                return expenseProvider.totalSpentByCurrency.keys.map((
                  String choice,
                ) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(choice),
                  );
                }).toList();
              },
            ),
          IconButton(
            icon: Icon(
              Icons.ios_share_rounded,
              color: theme.colorScheme.primary,
            ),
            onPressed: _showExportOptions,
            tooltip: "Export Report",
          ),
        ],
      ),
      body: _isExporting
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 20),
                  Text(
                    "Generating Export...",
                    style: theme.textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildAIAnalysisCard(
                    context,
                    expenseProvider,
                    authProvider,
                    _selectedCurrency,
                    totalSpent,
                  ),
                  const SizedBox(height: 24),
                  _buildCurrencyReportSection(
                    context,
                    expenseProvider,
                    authProvider,
                    _selectedCurrency,
                    totalSpent,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  // ⭐️ NEW: AI Analysis Card
  Widget _buildAIAnalysisCard(
    BuildContext context,
    ExpenseProvider provider,
    AuthProvider authProvider,
    String currency,
    double totalSpent,
  ) {
    final theme = Theme.of(context);

    // Trigger fetch if we have data but no insights yet (and not loading)
    if (_aiAnalysis == null &&
        !_isLoadingAI &&
        provider.expensesForSelectedMonth.isNotEmpty) {
      // Debounce or simple check to avoid infinite loops handled by _isLoadingAI
      // But better to trigger on significant changes. For now, manual refresh or init is safer.
    }

    // Default/Fallback Logic if AI fails or is loading
    String message = _aiAnalysis ?? "Analyzing your spending habits...";
    String tip = _aiTip ?? "Please wait while we crunch the numbers.";
    IconData icon = Icons.auto_awesome;
    Color color = theme.colorScheme.primary;

    if (_aiScore != null) {
      if (_aiScore! >= 8) {
        icon = Icons.star_rounded;
        color = Colors.green;
      } else if (_aiScore! >= 5) {
        icon = Icons.trending_up;
        color = Colors.orange;
      } else {
        icon = Icons.warning_amber_rounded;
        color = Colors.red;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.05),
            theme.cardColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: _isLoadingAI
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: color,
                            ),
                          )
                        : Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Financial Analyst',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _fetchAIInsights,
                tooltip: "Refresh Insights",
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingAI && _aiAnalysis == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                "Gathering your transaction data...",
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else ...[
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.secondary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 18,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      tip,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrencyReportSection(
    BuildContext context,
    ExpenseProvider expenseProvider,
    AuthProvider authProvider,
    String currency,
    double totalSpent,
  ) {
    final categorySpending = expenseProvider.getCategorySpending(currency);
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final daysInMonth = DateUtils.getDaysInMonth(
      expenseProvider.selectedMonth.year,
      expenseProvider.selectedMonth.month,
    );
    final dailyAverage = totalSpent / (daysInMonth > 0 ? daysInMonth : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTotalSpendingCard(
          totalSpent,
          authProvider,
          expenseProvider,
          currency,
        ),
        const SizedBox(height: 24),
        const SizedBox(height: 24),
        // 1. Trend Chart (Line Chart - Enhanced)
        _buildAdvancedTrendChart(context, expenseProvider, currency),
        const SizedBox(height: 24),
        // 2. Monthly Bar Chart (New)
        _buildMonthlyHistoryCard(context, expenseProvider, currency),
        const SizedBox(height: 24),
        // 3. Pie Chart (Donut)
        _buildPieChartCard(context, expenseProvider, currency, totalSpent),
        const SizedBox(height: 24),
        // 4. Category List (New Separate Cards)
        _buildDetailedCategoryList(context, expenseProvider, currency),
        const SizedBox(height: 24),
        _buildTopMerchantsCard(context, expenseProvider, currency),
        const SizedBox(height: 24),
        _buildSummaryCard(dailyAverage, expenseProvider.topMerchant, currency),
      ],
    );
  }

  Widget _buildTotalSpendingCard(
    double totalSpent,
    AuthProvider authProvider,
    ExpenseProvider expenseProvider,
    String currency,
  ) {
    final theme = Theme.of(context);
    final budget = authProvider.userProfile?.budget ?? 5000.0;
    final saved = budget - totalSpent;
    final selectedMonth = expenseProvider.selectedMonth;
    final symbol = CurrencyUtils.getCurrencySymbol(currency);

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.brightness == Brightness.dark
                ? theme.colorScheme.primary.withOpacity(0.8)
                : const Color(0xFF6B4EFF), // Purple
            theme.brightness == Brightness.dark
                ? theme.colorScheme.secondary.withOpacity(0.8)
                : const Color(0xFF9981FF), // Light Purple
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Overview',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              InkWell(
                onTap: () => _selectMonth(context, expenseProvider),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_today,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('MMMM yyyy').format(selectedMonth),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),

          // ⭐️ NEW: Budget Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(totalSpent / (budget > 0 ? budget : 1) * 100).clamp(0, 100).toStringAsFixed(0)}% of Budget',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    NumberFormat.simpleCurrency(name: currency).format(budget),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (totalSpent / (budget > 0 ? budget : 1)).clamp(
                    0.0,
                    1.0,
                  ),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    totalSpent > budget
                        ? Colors.redAccent
                        : (totalSpent > budget * 0.75
                              ? Colors.orangeAccent
                              : Colors.white),
                  ),
                  minHeight: 8,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Spent',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(
                        symbol: symbol,
                        decimalDigits: 0,
                      ).format(totalSpent),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saved',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      NumberFormat.currency(
                        symbol: symbol,
                        decimalDigits: 0,
                      ).format(saved),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ADVANCED TREND CHART ---
  Widget _buildAdvancedTrendChart(
    BuildContext context,
    ExpenseProvider provider,
    String currency,
  ) {
    final theme = Theme.of(context);

    // Get Data based on toggles
    final dailySpots = provider.getDailyTrendPoints(currency);
    final cumulativeSpots = provider.getCumulativeTrendPoints(currency);
    final comparisonSpots = provider.getLastMonthTrendPoints(currency);

    final currentSpots = _showCumulative ? cumulativeSpots : dailySpots;

    // Gradient Setup
    final lineGradient = LinearGradient(
      colors: [
        theme.colorScheme.primary,
        const Color(0xFF5856D6),
      ], // Blue to Purple
    );
    final areaGradient = LinearGradient(
      colors: [
        theme.colorScheme.primary.withOpacity(0.3),
        theme.colorScheme.primary.withOpacity(0.0),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    // Max Y Calc
    double maxY = 0;
    if (currentSpots.isNotEmpty) {
      maxY = currentSpots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    }
    // Check comparison max Y if showing
    if (_showComparison && !_showCumulative && comparisonSpots.isNotEmpty) {
      final compMax = comparisonSpots
          .map((e) => e.y)
          .reduce((a, b) => a > b ? a : b);
      if (compMax > maxY) maxY = compMax;
    }
    final double yInterval = maxY > 0 ? maxY / 5 : 10;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Trend',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Toggles
              Row(
                children: [
                  // Cumulative Toggle
                  IconButton(
                    icon: Icon(
                      _showCumulative ? Icons.show_chart : Icons.bar_chart,
                      color: _showCumulative
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() {
                      _showCumulative = !_showCumulative;
                      // Comparison only makes sense for daily view usually, or pure cumulative comparison
                      // Let's keep comparison active for now
                    }),
                    tooltip: _showCumulative
                        ? "Switch to Daily View"
                        : "Switch to Cumulative View",
                  ),
                  // Comparison Toggle
                  IconButton(
                    icon: Icon(
                      Icons.compare_arrows,
                      color: _showComparison
                          ? theme.colorScheme.secondary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () =>
                        setState(() => _showComparison = !_showComparison),
                    tooltip: "Toggle Last Month Comparison",
                  ),
                ],
              ),
            ],
          ),

          Text(
            _showCumulative ? "Cumulative Growth" : "Daily Activity",
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: 32),

          SizedBox(
            height: 240,
            child: currentSpots.isEmpty
                ? Center(
                    child: Text(
                      'No data',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: yInterval > 0 ? yInterval : 10,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: theme.dividerColor.withOpacity(0.05),
                          strokeWidth: 1,
                          dashArray: [5, 5],
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              if (value < 1 || value > 31)
                                return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(top: 10.0),
                                child: Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 1,
                      maxX: 31,
                      minY: 0,
                      maxY: maxY * 1.2,
                      lineBarsData: [
                        // Comparison Line (Last Month)
                        if (_showComparison &&
                            !_showCumulative &&
                            comparisonSpots.isNotEmpty)
                          LineChartBarData(
                            spots: comparisonSpots,
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: theme.colorScheme.secondary.withOpacity(0.3),
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            dashArray: [5, 5],
                          ),

                        // Current Line
                        LineChartBarData(
                          spots: currentSpots,
                          isCurved: true,
                          curveSmoothness: _showCumulative ? 0.2 : 0.35,
                          gradient: lineGradient,
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: _showCumulative
                                ? false
                                : true, // Show dots on peaks for daily
                            checkToShowDot: (spot, barData) => spot.y == maxY,
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: areaGradient,
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) =>
                              theme.colorScheme.surfaceVariant,
                          tooltipRoundedRadius: 8,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final isComp =
                                  spot.barIndex == 0 &&
                                  _showComparison &&
                                  !_showCumulative &&
                                  comparisonSpots
                                      .isNotEmpty; // Assuming comp is first if present
                              return LineTooltipItem(
                                '${CurrencyUtils.getCurrencySymbol(currency)}${spot.y.toStringAsFixed(0)}',
                                TextStyle(
                                  color: isComp
                                      ? theme.colorScheme.secondary
                                      : theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
          ),

          // Legend
          if (_showComparison)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(
                    context,
                    "Current",
                    theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 16),
                  _buildLegendItem(
                    context,
                    "Last Month",
                    theme.colorScheme.secondary.withOpacity(0.5),
                    isDashed: true,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
    BuildContext context,
    String label,
    Color color, {
    bool isDashed = false,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            // Simple dash simulation not easy here without custom painter, line is enough
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  // --- MONTHLY HISTORY CARD ---
  Widget _buildMonthlyHistoryCard(
    BuildContext context,
    ExpenseProvider provider,
    String currency,
  ) {
    final theme = Theme.of(context);
    final monthlyData = provider.getSixMonthTrend(currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly History',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        MonthlyBarChart(monthlyData: monthlyData, currency: currency),
      ],
    );
  }

  Widget _buildDetailedCategoryList(
    BuildContext context,
    ExpenseProvider provider,
    String currency,
  ) {
    final theme = Theme.of(context);
    final stats = provider.getCategoryDetails(currency);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Categories',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => NavigationManager.push(
                context,
                AllCategoriesScreen(currency: currency),
              ),
              child: const Text("View All"),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...stats
            .take(5)
            .map((stat) => CategoryDetailCard(stat: stat, currency: currency)),
      ],
    );
  }

  Widget _buildCatStatItem(BuildContext context, IconData icon, String text) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildPieChartCard(
    BuildContext context,
    ExpenseProvider provider,
    String currency,
    double totalSpent, // ⭐️ ADDED: totalSpent parameter
  ) {
    // Only show if there's data
    final pieData = provider.getPieChartData(currency);
    final theme = Theme.of(context);

    if (pieData.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Composition',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250, // Increased height
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 4, // Gap between sections
                    centerSpaceRadius: 60, // Larger donut hole
                    startDegreeOffset: -90,
                    sections: pieData
                        .map(
                          (section) => section.copyWith(
                            titlePositionPercentageOffset:
                                2.0, // Move titles further out
                            showTitle: true,
                            radius: 30, // Thickness of the ring
                            titleStyle: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                // ⭐️ NEW: Center Widget
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Total',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      CurrencyUtils.formatAmount(totalSpent, currency),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopMerchantsCard(
    BuildContext context,
    ExpenseProvider expenseProvider,
    String currency,
  ) {
    final theme = Theme.of(context);
    // Get ALL top merchants instead of limiting to 1
    // Combine lists or logic as needed. For now, let's just show top 5 frequent ones.
    // Or we can query by amount for the carousel which is probably more interesting.
    final topByAmount = expenseProvider.getTopMerchantsByAmount(
      currency,
      limit: 10,
    );

    if (topByAmount.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate total for percentage bars
    final totalAmount = topByAmount.fold(0.0, (sum, item) => sum + item.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Merchants',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Filter/Sort button could go here
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 130, // Height for the carousel
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            scrollDirection: Axis.horizontal,
            itemCount: topByAmount.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final merchantName = topByAmount[index].key;
              final amount = topByAmount[index].value;
              final percentage = totalAmount > 0 ? (amount / totalAmount) : 0.0;
              final color = Colors
                  .primaries[merchantName.hashCode % Colors.primaries.length];

              return Container(
                width: 100,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.dividerColor.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withOpacity(0.2)),
                      ),
                      child: Text(
                        merchantName.isNotEmpty
                            ? merchantName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      merchantName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    // Mini progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: theme.dividerColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      CurrencyUtils.formatAmount(amount, currency),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 10,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    double dailyAverage,
    String topMerchant,
    String currency,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            title: 'Average Daily',
            value: CurrencyUtils.formatAmount(dailyAverage, currency),
            icon: Icons.calendar_today_rounded,
            iconColor: Colors.orange,
            theme: theme,
          ),
          if (topMerchant.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Divider(
                height: 32,
                color: theme.dividerColor.withOpacity(0.1),
              ),
            ),
            _buildSummaryRow(
              title: 'Top Merchant',
              value: topMerchant,
              icon: Icons.store_rounded,
              iconColor: Colors.blue,
              theme: theme,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
