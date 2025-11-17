import 'package:ai_expense_logger/common/colors.dart';
import 'package:ai_expense_logger/providers/category_provider.dart';
import 'package:ai_expense_logger/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'package:ai_expense_logger/navigation/nav_manager.dart';
import '../../services/export_service.dart';
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

  // --- UPDATED: Swapped native picker for custom picker ---
  Future<void> _selectMonth(
      BuildContext context, ExpenseProvider provider) async {
    final DateTime? picked = await showCustomDatePicker(
      context: context,
      initialDate: provider.selectedMonth,
    );

    if (picked != null) {
      // We only care about the month and year
      final newMonth = DateTime(picked.year, picked.month);
      if (newMonth != provider.selectedMonth) {
        provider.updateSelectedMonth(newMonth);
      }
    }
  }

  Future<void> _showExportOptions() async {
    // Get the provider once
    final expenseProvider = context.read<ExpenseProvider>();

    // Show the bottom sheet and wait for a result
    final ExportFormat? format = await showExportBottomSheet(context);

    // Do nothing if the user dismissed the sheet
    if (format == null || !mounted) return;

    // Start loading
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

      // Call the single export service
      await ExportService().exportExpenses(expenses, monthName, format);

      // Show success (optional)
      SnackBarUtils.showSuccess(
          context, 'Successfully exported to ${format.name.toUpperCase()}!');
    } catch (e) {
      // Show error
      SnackBarUtils.showError(context, 'Error exporting file: ${e.toString()}');
    } finally {
      // Stop loading
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
        final totalSpent = expenseProvider.totalSpentForSelectedMonth;

        final categorySpending = expenseProvider.spendingByCategory;
        final sortedCategories = categorySpending.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final dailyAverage = expenseProvider.averageDailySpending;
        final topMerchant = expenseProvider.topMerchant;

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
                _buildTotalSpendingCard(totalSpent),
                const SizedBox(height: 24),
                _buildSpendingByCategoryCard(
                  context,
                  sortedCategories,
                  totalSpent,
                  categoryProvider,
                  expenseProvider, // <-- Pass expenseProvider for chart data
                ),
                const SizedBox(height: 24),
                _buildSummaryCard(dailyAverage, topMerchant),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTotalSpendingCard(double totalSpent) {
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
            NumberFormat.currency(symbol: '\$').format(totalSpent),
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

  /// Card for the "Spending by Category" section
  Widget _buildSpendingByCategoryCard(
      BuildContext context,
      List<MapEntry<String, double>> sortedCategories,
      double totalSpent,
      CategoryProvider categoryProvider,
      ExpenseProvider expenseProvider, // <-- NEW parameter
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
            'Spending by Category',
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          // --- REPLACED PIE CHART PLACEHOLDER ---
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
          // Actual Pie Chart
            SizedBox(
              height: 150,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Handle touch events if you want interactive slices
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2, // Space between slices
                  centerSpaceRadius: 40, // Size of the center hole
                  sections:
                  expenseProvider.pieChartData, // <-- Data from provider
                ),
              ),
            ),
          const SizedBox(height: 24),

          // --- Dynamic Category List (Top 3) ---
          ...sortedCategories.take(3).toList().asMap().entries.map(
                  (indexedEntry) {
                debugPrint("Entry: ${indexedEntry.key}");
                final index = indexedEntry.key;
                final categoryName = indexedEntry.value.key;
                final amount = indexedEntry.value.value;
                final category = categoryProvider.getCategory(categoryName);
                final percentage = (totalSpent > 0) ? amount / totalSpent : 0.0;
                // emoji

                return CategoryProgressItem(
                  icon: category.iconData,
                  title: categoryName,
                  amount: amount,
                  percentage: percentage,
                  color: colors[index % colors.length],
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

  Widget _buildSummaryCard(double dailyAverage, String topMerchant) {
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
            value: NumberFormat.currency(symbol: '\$').format(dailyAverage),
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