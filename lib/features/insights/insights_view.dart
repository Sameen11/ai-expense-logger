// import 'package:ai_expense_logger/common/colors.dart';
import 'package:ai_expense_logger/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:ai_expense_logger/navigation/nav_manager.dart';
import '../../services/export_service.dart';
import '../../utils/currency_utils.dart';
import '../../widgets/data_picker_dialog.dart';
import '../../widgets/export_bottom_sheet.dart';
import '../../widgets/notification_bar.dart';
import '../authentication/provider/auth_provider.dart';
import 'all_categories_screen.dart';
import 'category_progress_item.dart';

class InsightsView extends StatefulWidget {
  const InsightsView({super.key});

  @override
  State<InsightsView> createState() => _InsightsViewState();
}

class _InsightsViewState extends State<InsightsView> {
  bool _isExporting = false;
  String _selectedCurrency = 'USD'; // Default currency

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // 2. Consume both ExpenseProvider and AuthProvider
    return Consumer2<ExpenseProvider, AuthProvider>(
      builder: (context, expenseProvider, authProvider, child) {
        final totalSpentByCurrency = expenseProvider.totalSpentByCurrency;

        // Build list of available currencies, ensuring USD is always present
        final Set<String> availableCurrencies = {'USD'};
        availableCurrencies.addAll(totalSpentByCurrency.keys);
        final currencyList = availableCurrencies.toList()..sort();

        // Ensure selected currency is valid
        if (!availableCurrencies.contains(_selectedCurrency)) {
          _selectedCurrency = 'USD';
        }

        final totalSpent = totalSpentByCurrency[_selectedCurrency] ?? 0.0;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.primaryColor.withOpacity(0.05),
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            // 3. Simplified title since date picker is now in the card
            title: Text(
              'Insights',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            actions: [
              _isExporting
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.download_outlined,
                        color: theme.iconTheme.color,
                      ),
                      onPressed: _showExportOptions,
                    ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // --- Currency Dropdown Selector ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: theme.dividerColor.withOpacity(0.2),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCurrency,
                      isExpanded: true,
                      borderRadius: BorderRadius.circular(14),
                      icon: Icon(
                        Icons.expand_more_rounded,
                        color: theme.iconTheme.color?.withOpacity(0.5),
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      dropdownColor: theme.cardColor,
                      items: currencyList.map((String code) {
                        final symbol = CurrencyUtils.getCurrencySymbol(code);
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      theme.colorScheme.primary.withOpacity(
                                        0.15,
                                      ),
                                      theme.colorScheme.primary.withOpacity(
                                        0.05,
                                      ),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  symbol,
                                  style: TextStyle(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    code,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                    ),
                                  ),
                                  Text(
                                    'Currency Report',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCurrency = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const SizedBox(height: 24),

                // --- ⭐️ AI Smart Analysis Card ---
                _buildAIAnalysisCard(
                  context,
                  expenseProvider,
                  authProvider,
                  _selectedCurrency,
                  totalSpent,
                ),

                const SizedBox(height: 24),

                // --- Selected Currency Report ---
                _buildCurrencyReportSection(
                  context,
                  expenseProvider,
                  authProvider, // Pass auth provider
                  _selectedCurrency,
                  totalSpent,
                ),
              ],
            ),
          ),
        );
      },
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
    final percentageChange = provider.getPercentageChange(currency);
    final budget = authProvider.userProfile?.budget ?? 5000.0;
    final isOverBudget = totalSpent > budget;

    // Determine the message and icon based on data
    String message = "Keep tracking your expenses to get smart insights!";
    IconData icon = Icons.auto_awesome;
    Color color = theme.colorScheme.primary;

    if (percentageChange != null) {
      if (percentageChange > 0) {
        message =
            "You've spent ${percentageChange.abs().toStringAsFixed(1)}% more than last month. Check your 'Food' spending!";
        icon = Icons.trending_up;
        color = Colors.orange;
      } else {
        message =
            "Great job! You've spent ${percentageChange.abs().toStringAsFixed(1)}% less than last month.";
        icon = Icons.trending_down;
        color = Colors.green;
      }
    }

    if (isOverBudget) {
      message =
          "Alert: You've exceeded your monthly budget. Try cutting back on non-essentials.";
      icon = Icons.warning_amber_rounded;
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Insight',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
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
        // 1. Trend Chart (Line Chart)
        // 1. Trend Chart (Line Chart)
        _buildTrendChartCard(context, expenseProvider, currency),
        const SizedBox(height: 24),
        // 2. Pie Chart (Donut)
        _buildPieChartCard(context, expenseProvider, currency, totalSpent),
        const SizedBox(height: 24),
        // 3. Category List (Circular Progress)
        _buildCategoryListCard(context, sortedCategories, totalSpent, currency),
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

  Widget _buildTrendChartCard(
    BuildContext context,
    ExpenseProvider provider,
    String currency,
  ) {
    final theme = Theme.of(context);
    final spots = provider.getDailyTrendPoints(currency);
    final gradientColors = [
      theme.colorScheme.primary.withOpacity(0.3),
      theme.colorScheme.primary.withOpacity(0.0),
    ];
    final lineGradient = LinearGradient(
      colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
    );

    // Calculate nice max Y for padding
    double maxY = 0;
    if (spots.isNotEmpty) {
      maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spending Trend',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Daily',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 240,
            child: spots.isEmpty
                ? Center(
                    child: Text(
                      'No data available',
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
                        horizontalInterval: yInterval > 0 ? yInterval : 100,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: theme.dividerColor.withOpacity(
                              0.05,
                            ), // Fainter grid
                            strokeWidth: 1,
                            dashArray: [5, 5],
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: 5,
                            getTitlesWidget: (value, meta) {
                              if (value == 0 || value > 31)
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
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ), // Clean look, hide Y axis labels labels or keep minimal
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 1,
                      maxX: spots.isNotEmpty ? spots.last.x : 31,
                      minY: 0,
                      maxY: maxY * 1.2, // Add 20% top padding
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          // color: theme.colorScheme.primary,
                          gradient: lineGradient, // Gradient Line
                          barWidth: 4, // Thicker line
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            checkToShowDot: (spot, barData) {
                              return spot.y ==
                                  maxY; // Only show dot for max peak
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: gradientColors,
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) =>
                              theme.colorScheme.surfaceVariant,
                          tooltipRoundedRadius: 8,
                          tooltipPadding: const EdgeInsets.all(8),
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              return LineTooltipItem(
                                '${CurrencyUtils.getCurrencySymbol(currency)}${spot.y.toStringAsFixed(0)}',
                                TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              );
                            }).toList();
                          },
                        ),
                        getTouchedSpotIndicator:
                            (LineChartBarData barData, List<int> spotIndexes) {
                              return spotIndexes.map((spotIndex) {
                                return TouchedSpotIndicatorData(
                                  FlLine(
                                    color: theme.colorScheme.primary
                                        .withOpacity(0.5),
                                    strokeWidth: 2,
                                    dashArray: [5, 5],
                                  ),
                                  FlDotData(
                                    getDotPainter:
                                        (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 6,
                                            color: theme.colorScheme.surface,
                                            strokeWidth: 3,
                                            strokeColor:
                                                theme.colorScheme.primary,
                                          );
                                        },
                                  ),
                                );
                              }).toList();
                            },
                      ),
                    ),
                  ),
          ),
        ],
      ),
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

  Widget _buildCategoryListCard(
    BuildContext context,
    List<MapEntry<String, double>> sortedCategories,
    double totalSpent,
    String currency,
  ) {
    final theme = Theme.of(context);
    // We recycle colors for the progress bars
    final colors = [
      Colors.blue[600]!,
      Colors.green[600]!,
      Colors.purple[600]!,
      Colors.orange[600]!,
      Colors.red[600]!,
    ];

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
            'Categories',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          if (sortedCategories.isEmpty)
            Center(
              child: Text(
                'No categories yet',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),

          ...sortedCategories.take(5).toList().asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value.key;
            final amount = entry.value.value;
            final percentage = totalSpent > 0 ? amount / totalSpent : 0.0;
            return CategoryProgressItem(
              icon: Icons
                  .category, // Not used in new design but required constant
              title: category,
              amount: amount,
              percentage: percentage,
              color: colors[index % colors.length],
              currency: currency,
            );
          }),

          const SizedBox(height: 12),
          Center(
            child: TextButton(
              onPressed: () {
                NavigationManager.push(
                  context,
                  AllCategoriesScreen(
                    sortedCategories: sortedCategories,
                    totalSpent: totalSpent,
                  ),
                  type: TransitionType.platform,
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All Categories',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
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
