import 'package:flutter/material.dart';
import 'expense_detail.dart';
import 'model.dart';
import 'package:intl/intl.dart';

class ExpensesView extends StatelessWidget {
  const ExpensesView({super.key});

  // Mock data for demonstration
  static final List<Expense> _expenses = [
    // Today's expenses
    Expense(
      id: 'e1',
      merchant: 'Starbucks',
      amount: 15.47,
      date: DateTime.now(),
      category: 'Meals & Dining',
      icon: Icons.coffee,
      notes: 'Client meeting coffee',
    ),
    Expense(
      id: 'e2',
      merchant: 'Uber',
      amount: 23.10,
      date: DateTime.now(),
      category: 'Travel',
      icon: Icons.directions_car,
    ),
    // Yesterday's expenses
    Expense(
      id: 'e3',
      merchant: 'Adobe',
      amount: 9.99,
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: 'Software',
      icon: Icons.laptop_chromebook,
    ),
    Expense(
      id: 'e4',
      merchant: 'Pizza Hut',
      amount: 34.50,
      date: DateTime.now().subtract(const Duration(days: 1)),
      category: 'Meals & Dining',
      icon: Icons.local_pizza,
    ),
    // Older expenses for scroll demo
    Expense(
      id: 'e5',
      merchant: 'Netflix',
      amount: 19.99,
      date: DateTime.now().subtract(const Duration(days: 3)),
      category: 'Entertainment',
      icon: Icons.movie,
    ),
    Expense(
      id: 'e6',
      merchant: 'Amazon',
      amount: 120.50,
      date: DateTime.now().subtract(const Duration(days: 4)),
      category: 'Shopping',
      icon: Icons.shopping_bag,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Group expenses for the list (e.g., Today, Yesterday)
    // In a real app, this logic would be in a ViewModel or Bloc
    final List<Expense> todayExpenses = _expenses.where((e) => e.date.day == DateTime.now().day).toList();
    final List<Expense> yesterdayExpenses = _expenses.where((e) => e.date.day == DateTime.now().day - 1).toList();
    final List<Expense> olderExpenses = _expenses.where((e) => e.date.day < DateTime.now().day - 1).toList();

    const double totalSpent = 2847.32; // Hardcoded total from image
    const Color backgroundColor = Colors.white; // Flat white background

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // This SliverAppBar has a flat, minimal look
          SliverAppBar(
            backgroundColor: backgroundColor,
            expandedHeight: 220.0,
            floating: false,
            surfaceTintColor: Colors.transparent,
            pinned: true,
            elevation: 0, // No shadow
            iconTheme: IconThemeData(color: Colors.grey[800]), // Darker icons
            actionsIconTheme: IconThemeData(color: Colors.grey[800]),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('MMMM yyyy').format(DateTime.now()), // "September 2025"
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
                onPressed: () {
                  // Handle search action
                },
              ),
            ],
            // The flexible space holds the "Total Spent" section
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: backgroundColor,
                child: Padding(
                  // Added padding to ensure it's below the status bar
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
                      // Clean text look for the total
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
            // Clean divider at the bottom
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: Colors.grey[200],
                height: 1.0,
              ),
            ),
          ),

          // "TODAY" Header
          _DateHeader(title: 'TODAY'),

          // List of Today's expenses
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return _ExpenseListItem(expense: todayExpenses[index]);
              },
              childCount: todayExpenses.length,
            ),
          ),

          // "YESTERDAY" Header
          _DateHeader(title: 'YESTERDAY'),

          // List of Yesterday's expenses
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return _ExpenseListItem(expense: yesterdayExpenses[index]);
              },
              childCount: yesterdayExpenses.length,
            ),
          ),

          // "OLDER" Header
          _DateHeader(title: 'OLDER'),

          // List of Older expenses
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                return _ExpenseListItem(expense: olderExpenses[index]);
              },
              childCount: olderExpenses.length,
            ),
          ),


          // Add some padding at the bottom
          const SliverToBoxAdapter(
            child: SizedBox(height: 100), // More space for FAB
          ),
        ],
      ),
      // Standard Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle add new expense
        },
        backgroundColor: Colors.blue[700],
        elevation: 6,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
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
        padding: const EdgeInsets.only(top: 24.0, bottom: 8.0, left: 18.0, right: 18.0),
        color: Colors.white, // Match scaffold background
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

// Private widget for a single expense item in the list (Flat ListTile)
class _ExpenseListItem extends StatelessWidget {
  final Expense expense;

  const _ExpenseListItem({
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0), // Less horizontal padding
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        // Modern rounded-square icon
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.0), // Rounded square
          ),
          child: Icon(expense.icon, color: Colors.blue[800], size: 24),
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
          // Navigate to the Expense Detail Screen
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExpenseDetailScreen(expense: expense),
            ),
          );
        },
      ),
    );
  }
}

