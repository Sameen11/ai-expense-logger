import 'package:ai_expense_logger/common/colors.dart';
import 'package:ai_expense_logger/providers/category_provider.dart';
import 'package:ai_expense_logger/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
// --- NEW IMPORT ---
import 'package:fl_chart/fl_chart.dart';

import 'package:ai_expense_logger/navigation/nav_manager.dart';
import '../../services/csv_exporter.dart';
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
  Future<void> _selectMonth(
      BuildContext context, ExpenseProvider provider) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: provider.selectedMonth,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryColor, // Header background
              onPrimary: Colors.white, // Header text
              onSurface: Color(0xFF1D1D1F), // Calendar text
            ),
            dialogBackgroundColor: Colors.white,

            // *** THE FIX IS HERE ***
            // It's 'DialogThemeData', not 'DialogTheme'
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),

            // *** I've also corrected this for you ***
            // It's 'TextButtonThemeData', not 'TextButtonTheme'
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF4A90E2), // OK/Cancel button color
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != provider.selectedMonth) {
      provider.updateSelectedMonth(picked);
    }
  }

  // --- NEW FUNCTION to handle the export logic ---
  Future<void> _handleExport(ExpenseProvider provider) async {
    setState(() { _isExporting = true; });

    try {
      final expenses = provider.expensesForSelectedMonth;
      if (expenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No data to export for this month.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final monthName = DateFormat('yyyy-MM').format(provider.selectedMonth);

      // Call our service
      await CsvExporter().exportExpenses(expenses, monthName);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error exporting file: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Ensure the loading spinner always stops
      setState(() { _isExporting = false; });
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
                icon: Icon(Icons.download_outlined, color: Colors.grey[800]),
                onPressed: () => _handleExport(expenseProvider),
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
                  sections: expenseProvider.pieChartData, // <-- Data from provider
                ),
              ),
            ),
          const SizedBox(height: 24),

          // --- Dynamic Category List (Top 3) ---
          ...sortedCategories.take(3).toList().asMap().entries.map((indexedEntry) {
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