import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Import Provider
import 'package:intl/intl.dart';

import '../../common/colors.dart';
import '../../models/expense.dart';
import '../../navigation/nav_manager.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../snap/add_expense.dart';
import 'expense_detail.dart';

class ExpensesView extends StatelessWidget {
  const ExpensesView({super.key});

  // Helper function to check if two DateTime objects are on the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Colors.white; // Flat white background

    // We wrap the main UI in a Consumer
    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
        // --- 1. HANDLE LOADING & ERROR STATES ---
        if (provider.isLoading) {
          return const Scaffold(
            backgroundColor: backgroundColor,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (provider.error != null) {
          return Scaffold(
            backgroundColor: backgroundColor,
            body: Center(child: Text("Error: ${provider.error}")),
          );
        }

        // --- 2. PROCESS LIVE DATA ---
        final allExpenses = provider.expenses;

        final double totalSpent = allExpenses.fold(
          0.0,
              (sum, item) => sum + item.amount,
        );

        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        final List<Expense> todayExpenses =
        allExpenses.where((e) => _isSameDay(e.date, now)).toList();
        final List<Expense> yesterdayExpenses =
        allExpenses.where((e) => _isSameDay(e.date, yesterday)).toList();
        final List<Expense> olderExpenses =
        allExpenses.where((e) => e.date.isBefore(yesterday) && !_isSameDay(e.date, yesterday)).toList();

        // --- 3. BUILD THE UI ---
        return Scaffold(
          backgroundColor: backgroundColor,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: backgroundColor,
                expandedHeight: 220.0,
                floating: false,
                surfaceTintColor: Colors.transparent,
                pinned: true,
                elevation: 0,
                iconTheme: IconThemeData(color: Colors.grey[800]),
                actionsIconTheme: IconThemeData(color: Colors.grey[800]),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      DateFormat('MMMM yyyy').format(DateTime.now()),
                      style: TextStyle(
                        color: Colors.grey[800],
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: Colors.grey[800]),
                  ],
                ),
                centerTitle: true,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.search, size: 28),
                    onPressed: () {},
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: backgroundColor,
                    child: Padding(
                      padding: const EdgeInsets.only(top: kToolbarHeight),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Total Spent',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            // <-- UPDATED: Use calculated total
                            NumberFormat.currency(symbol: '\$').format(totalSpent),
                            style: TextStyle(
                              color: Colors.grey[900],
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1.0),
                  child: Container(
                    color: Colors.grey[200],
                    height: 1.0,
                  ),
                ),
              ),

              // --- 4. HANDLE EMPTY LIST ---
              if (allExpenses.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(48.0),
                    child: Center(
                      child: Text(
                        "No expenses yet. Tap '+' to add one!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                ),

              // "TODAY" Header (only if there are expenses)
              if (todayExpenses.isNotEmpty) _DateHeader(title: 'TODAY'),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return _ExpenseListItem(expense: todayExpenses[index]);
                  },
                  childCount: todayExpenses.length, // <-- UPDATED
                ),
              ),

              // "YESTERDAY" Header (only if there are expenses)
              if (yesterdayExpenses.isNotEmpty) _DateHeader(title: 'YESTERDAY'),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return _ExpenseListItem(expense: yesterdayExpenses[index]);
                  },
                  childCount: yesterdayExpenses.length, // <-- UPDATED
                ),
              ),

              // "OLDER" Header (only if there are expenses)
              if (olderExpenses.isNotEmpty) _DateHeader(title: 'OLDER'),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return _ExpenseListItem(expense: olderExpenses[index]);
                  },
                  childCount: olderExpenses.length, // <-- UPDATED
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              // <-- UPDATED: Navigate to your add screen
              NavigationManager.push(
                context,
                const AddExpenseManuallyScreen(),
                type: TransitionType.platform, // Modal slide-up is nice here
              );
            },
            backgroundColor: AppColors.primaryColor,
            elevation: 6,
            child: const Icon(Icons.add, color: Colors.white, size: 30),
          ),
        );
      },
    );
  }
}

// Private widget for the date headers (TODAY, YESTERDAY)
class _DateHeader extends StatelessWidget {
  final String title;
  const _DateHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(
            top: 24.0, bottom: 8.0, left: 18.0, right: 18.0),
        color: Colors.white,
        child: Text(
          title,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Private widget for a single expense item
class _ExpenseListItem extends StatelessWidget {
  final Expense expense; // <-- UPDATED: Uses the new model

  const _ExpenseListItem({
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final category = context.watch<CategoryProvider>()
        .getCategory(expense.category.toLowerCase());
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.0),
          ),
          // <-- UPDATED: Use the helper function
          child: Icon(
              category.iconData,
            color: AppColors.primaryColor,
            size: 24,
          ),
        ),
        title: Text(
          expense.merchant,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
        subtitle: Text(
          expense.category,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 13,
          ),
        ),
        trailing: Text(
          NumberFormat.currency(symbol: '\$').format(expense.amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.grey[800],
          ),
        ),
        onTap: () {
          // This should still work, assuming ExpenseDetailScreen
          // was also updated to use the new Expense model.
          NavigationManager.push(
            context,
            ExpenseDetailScreen(expense: expense),
            type: TransitionType.platform,
          );
        },
      ),
    );
  }
}