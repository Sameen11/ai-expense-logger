import 'package:ai_expense_logger/common/colors.dart';
import 'package:ai_expense_logger/providers/category_provider.dart';
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
import 'all_categories_screen.dart';
import 'category_progress_item.dart';

class InsightsView extends StatefulWidget {
  const InsightsView({super.key});

  @override
  State<InsightsView> createState() => _InsightsViewState();
}

class _InsightsViewState extends State<InsightsView> {
  /// Shows the month picker dialog
  bool _isExporting = false;
  String _selectedCurrency = 'USD'; // Default currency

  Future<void> _selectMonth(
      BuildContext context, ExpenseProvider provider) async {
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

      final monthName =
      DateFormat('yyyy-MM').format(expenseProvider.selectedMonth);

      // Show progress message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exporting ${expenses.length} expenses to ${format.name.toUpperCase()}...'),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      await ExportService().exportExpenses(expenses, monthName, format);

      if (mounted) {
        SnackBarUtils.showSuccess(
            context, 'Successfully exported to ${format.name.toUpperCase()}!');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, 'Error exporting file: ${e.toString()}');
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
    return Consumer2<ExpenseProvider, CategoryProvider>(
      builder: (context, expenseProvider, categoryProvider, child) {
        final selectedMonth = expenseProvider.selectedMonth;
        final totalSpentByCurrency = expenseProvider.totalSpentByCurrency;

        // Build list of available currencies, ensuring USD is always present
        final Set<String> availableCurrencies = {'USD'};
        availableCurrencies.addAll(totalSpentByCurrency.keys);
        final currencyList = availableCurrencies.toList()..sort();

        // Ensure selected currency is valid
        if (!availableCurrencies.contains(_selectedCurrency)) {
          // If current selection became invalid (e.g. no data), revert to USD or first available
          _selectedCurrency = 'USD'; 
        }
        
        final totalSpent = totalSpentByCurrency[_selectedCurrency] ?? 0.0;

        return Scaffold(
          backgroundColor: AppColors.bgColor,
          appBar: AppBar(
            backgroundColor: Colors.grey[100],
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: InkWell(
              onTap: () => _selectMonth(context, expenseProvider),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('MMMM yyyy').format(selectedMonth),
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.grey[800]),
                ],
              ),
            ),
            centerTitle: true,
            actions: [
              _isExporting
                  ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
                  : IconButton(
                icon: Icon(Icons.download_outlined,
                    color: Colors.grey[800]),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCurrency,
                      icon: const Icon(Icons.keyboard_arrow_down),
                      isExpanded: true,
                      items: currencyList.map((String code) {
                        final symbol = CurrencyUtils.getCurrencySymbol(code);
                        return DropdownMenuItem<String>(
                          value: code,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  symbol,
                                  style: const TextStyle(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$code Report',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
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

                // --- Selected Currency Report ---
                _buildCurrencyReportSection(
                  context, 
                  expenseProvider, 
                  categoryProvider, 
                  _selectedCurrency, 
                  totalSpent
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrencyReportSection(
      BuildContext context,
      ExpenseProvider expenseProvider,
      CategoryProvider categoryProvider,
      String currency,
      double totalSpent) {

    final categorySpending = expenseProvider.getCategorySpending(currency);
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final daysInMonth = DateUtils.getDaysInMonth(expenseProvider.selectedMonth.year, expenseProvider.selectedMonth.month);
    final dailyAverage = totalSpent / (daysInMonth > 0 ? daysInMonth : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTotalSpendingCard(totalSpent, currency),
        const SizedBox(height: 24),
        _buildSpendingByCategoryCard(
          context,
          sortedCategories,
          totalSpent,
          categoryProvider,
          expenseProvider,
          currency,
        ),
        const SizedBox(height: 24),
        _buildTopMerchantsCard(
          context,
          expenseProvider,
          currency,
        ),
        const SizedBox(height: 24),
        _buildSummaryCard(dailyAverage, expenseProvider.topMerchant, currency),
      ],
    );
  }

  Widget _buildTotalSpendingCard(double totalSpent, String currency) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Spending',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyUtils.formatAmount(totalSpent, currency),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '--%',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'vs last month',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSpendingByCategoryCard(
      BuildContext context,
      List<MapEntry<String, double>> sortedCategories,
      double totalSpent,
      CategoryProvider categoryProvider,
      ExpenseProvider expenseProvider,
      String currency,
      ) {
    final colors = [
      Colors.blue[600]!,
      Colors.green[600]!,
      Colors.purple[600]!,
    ];

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category', // Removed ($currency) as it's now globally selected
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          if (sortedCategories.isEmpty)
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text('No spending this month',
                    style: TextStyle(color: Colors.grey[600])),
              ),
            )
          else
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: expenseProvider.getPieChartData(currency),
                ),
              ),
            ),
          const SizedBox(height: 24),

          ...sortedCategories.take(3).toList().asMap().entries.map(
                  (indexedEntry) {
                final index = indexedEntry.key;
                final categoryName = indexedEntry.value.key;
                final amount = indexedEntry.value.value;
                final category = categoryProvider.getCategory(categoryName);
                final percentage = (totalSpent > 0) ? amount / totalSpent : 0.0;

                return CategoryProgressItem(
                  icon: category.iconData,
                  title: categoryName,
                  amount: amount,
                  percentage: percentage,
                  color: colors[index % colors.length],
                  currency: currency,
                );
              }),
          const SizedBox(height: 16),
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
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.blue[700],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTopMerchantsCard(
      BuildContext context,
      ExpenseProvider expenseProvider,
      String currency) {
    final topByCount = expenseProvider.getTopMerchantsByCount(currency, limit: 5);
    final topByAmount = expenseProvider.getTopMerchantsByAmount(currency, limit: 5);
    
    if (topByCount.isEmpty && topByAmount.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Merchants',
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          
          // Top by Receipt Count
          if (topByCount.isNotEmpty) ...[
            Text(
              'By Receipt Count',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...topByCount.asMap().entries.map((entry) {
              final index = entry.key;
              final merchant = entry.value.key;
              final count = entry.value.value;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchant,
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$count receipt${count > 1 ? 's' : ''}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
          
          // Top by Amount
          if (topByAmount.isNotEmpty) ...[
            Text(
              'By Total Amount',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...topByAmount.asMap().entries.map((entry) {
              final index = entry.key;
              final merchant = entry.value.key;
              final amount = entry.value.value;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.green[600]!.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: Colors.green[600],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            merchant,
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            CurrencyUtils.formatAmount(amount, currency),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(double dailyAverage, String topMerchant, String currency) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            title: 'Average Daily',
            value: CurrencyUtils.formatAmount(dailyAverage, currency),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow(
            title: 'Top Merchant',
            value: topMerchant,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({required String title, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
