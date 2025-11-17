import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../common/colors.dart';
import '../../models/expense.dart';
import '../../navigation/nav_manager.dart';
import '../../providers/expense_provider.dart';
import '../../widgets/data_picker_dialog.dart';
import '../snap/add_expense.dart';
import 'expense_detail.dart';

class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  bool _isSearching = false;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  // Helper function to check if two DateTime objects are on the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- UPDATED: Function to show the *custom* month picker ---
  Future<void> _selectMonth(BuildContext context) async {
    // Use read here as we are in a method, not rebuilding
    final provider = context.read<ExpenseProvider>();
    final initialDate = provider.selectedMonth;

    // --- UPDATED: Call new custom picker ---
    final pickedDate = await showCustomDatePicker(
      context: context,
      initialDate: initialDate,
    );

    if (pickedDate != null) {
      // We only care about the month and year
      provider.updateSelectedMonth(DateTime(pickedDate.year, pickedDate.month));
    }
  }

  // --- (All other code remains the same) ---

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autofocus: true,
      decoration: InputDecoration(
        hintText: 'Search merchant, category...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.grey[600]),
      ),
      style: TextStyle(color: Colors.grey[800], fontSize: 18),
      onChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
      },
    );
  }

  Widget _buildTitle(BuildContext context, DateTime selectedMonth) {
    return InkWell(
      onTap: () => _selectMonth(context), // This now calls the updated function
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('MMMM yyyy').format(selectedMonth),
            style: TextStyle(
              color: Colors.grey[800],
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Icon(Icons.arrow_drop_down, color: Colors.grey[800]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color backgroundColor = Colors.white; // Flat white background

    return Consumer<ExpenseProvider>(
      builder: (context, provider, child) {
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

        final double totalSpent = provider.totalSpentForSelectedMonth;
        final List<Expense> expensesForMonth = provider.expensesForSelectedMonth;

        final List<Expense> filteredExpenses;
        if (_isSearching && _searchQuery.isNotEmpty) {
          final query = _searchQuery.toLowerCase();
          filteredExpenses = expensesForMonth.where((e) {
            final merchant = e.merchant.toLowerCase();
            final category = e.category.toLowerCase();
            return merchant.contains(query) || category.contains(query);
          }).toList();
        } else {
          filteredExpenses = expensesForMonth;
        }

        final now = DateTime.now();
        final yesterday = now.subtract(const Duration(days: 1));

        final List<Expense> todayExpenses =
        filteredExpenses.where((e) => _isSameDay(e.date, now)).toList();
        final List<Expense> yesterdayExpenses =
        filteredExpenses.where((e) => _isSameDay(e.date, yesterday)).toList();
        final List<Expense> olderExpenses = filteredExpenses
            .where((e) =>
        e.date.isBefore(yesterday) && !_isSameDay(e.date, yesterday))
            .toList();

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
                title: _isSearching
                    ? _buildSearchField()
                    : _buildTitle(context, provider.selectedMonth),
                centerTitle: true,
                actions: _isSearching
                    ? [
                  IconButton(
                    icon: const Icon(Icons.close, size: 28),
                    onPressed: () {
                      setState(() {
                        _isSearching = false;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    },
                  ),
                ]
                    : [
                  IconButton(
                    icon: const Icon(Icons.search, size: 28),
                    onPressed: () {
                      setState(() {
                        _isSearching = true;
                      });
                    },
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

              if (filteredExpenses.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Center(
                      child: Text(
                        _isSearching
                            ? "No results found for '$_searchQuery'"
                            : "No expenses for this month.\nTap '+' to add one!",
                        textAlign: TextAlign.center,
                        style:
                        const TextStyle(fontSize: 16, color: Colors.grey),
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
                  childCount: todayExpenses.length,
                ),
              ),

              // "YESTERDAY" Header (only if there are expenses)
              if (yesterdayExpenses.isNotEmpty) _DateHeader(title: 'YESTERDAY'),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return _ExpenseListItem(expense: yesterdayExpenses[index]);
                  },
                  childCount: yesterdayExpenses.length,
                ),
              ),

              // "OLDER" Header (only if there are expenses)
              if (olderExpenses.isNotEmpty) _DateHeader(title: 'OLDER'),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) {
                    return _ExpenseListItem(expense: olderExpenses[index]);
                  },
                  childCount: olderExpenses.length,
                ),
              ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              NavigationManager.push(
                context,
                const AddExpenseManuallyScreen(),
                type: TransitionType.platform,
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
  final Expense expense;

  const _ExpenseListItem({
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
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
          child: Center(
            child: Text(
              expense.emoji ?? "📦",
              style: const TextStyle(fontSize: 22),
            ),
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