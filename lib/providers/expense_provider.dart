import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUid;
  DateTime _selectedMonth = DateTime.now();

  StreamSubscription? _expenseSubscription;

  // --- Getters ---
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedMonth => _selectedMonth;

  // --- Public Methods ---

  void updateSelectedMonth(DateTime newMonth) {
    _selectedMonth = newMonth;
    notifyListeners();
  }

  /// Called by a ProxyProvider to update the UID and fetch data
  void updateUid(String? newUid) {
    if (newUid != _currentUid) {
      _currentUid = newUid;
      _expenseSubscription?.cancel(); // Cancel old subscription

      if (newUid != null) {
        _fetchExpenses(newUid);
      } else {
        _expenses = [];
        notifyListeners();
      }
    }
  }

  void _fetchExpenses(String uid) {
    _setLoading(true);
    _expenseSubscription = _expenseService.getExpensesStream(uid).listen((expenses) {
      _expenses = expenses;
      _setError(null);
      _setLoading(false);
    }, onError: (e) {
      _setError(e.toString());
      _setLoading(false);
    });
  }

  /// Adds a new expense
  Future<void> addExpense({
    required String merchant,
    required double amount,
    required DateTime date,
    required String category,
    String? notes,
  }) async {
    if (_currentUid == null) {
      _setError("User not logged in");
      return;
    }

    _setLoading(true);
    try {
      final newExpense = Expense(
        merchant: merchant,
        amount: amount,
        date: date,
        category: category,
        notes: notes,
        createdAt: Timestamp.now(), // Set creation time
      );
      await _expenseService.addExpense(_currentUid!, newExpense);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // You can add updateExpense and deleteExpense methods here following the same pattern

  Future<void> deleteExpense(String expenseId) async {
    if (_currentUid == null) {
      _setError("User not logged in");
      return;
    }
    _setLoading(true);
    try {
      await _expenseService.deleteExpense(_currentUid!, expenseId);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
  /// Filters the main list to only expenses in the selected month
  List<Expense> get expensesForSelectedMonth {
    return _expenses
        .where((e) =>
    e.date.year == _selectedMonth.year &&
        e.date.month == _selectedMonth.month)
        .toList();
  }

  /// Calculates the total spending for the selected month
  double get totalSpentForSelectedMonth {
    return expensesForSelectedMonth.fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Groups all expenses by category and sums their amounts
  Map<String, double> get spendingByCategory {
    var categoryTotals = <String, double>{};
    for (var expense in expensesForSelectedMonth) {
      categoryTotals.update(
        expense.category,
            (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return categoryTotals;
  }

  /// Calculates the average daily spending for the selected month
  double get averageDailySpending {
    if (expensesForSelectedMonth.isEmpty) return 0.0;

    // Use the number of days in the *entire* month for a stable average
    final daysInMonth = DateUtils.getDaysInMonth(_selectedMonth.year, _selectedMonth.month);

    // Handle division by zero, just in case
    if (daysInMonth == 0) return 0.0;

    return totalSpentForSelectedMonth / daysInMonth;
  }

  /// Finds the merchant with the most transactions
  String get topMerchant {
    if (expensesForSelectedMonth.isEmpty) return "N/A";

    var merchantCounts = <String, int>{};
    for (var expense in expensesForSelectedMonth) {
      merchantCounts.update(
        expense.merchant,
            (value) => value + 1,
        ifAbsent: () => 1,
      );
    }

    // Find the merchant with the highest count
    final top = merchantCounts.entries.reduce((a, b) => a.value > b.value ? a : b);
    return "${top.key} (${top.value}x)";
  }

  // List of colors for the pie chart slices
  final List<Color> _pieChartColors = [
    Colors.blue[600]!,
    Colors.green[600]!,
    Colors.purple[600]!,
    Colors.orange[600]!,
    Colors.red[600]!,
    Colors.teal[600]!,
    Colors.pink[600]!,
    Colors.indigo[600]!,
    Colors.brown[600]!,
    Colors.cyan[600]!,
  ];

  /// Prepares data for the pie chart, including percentages and colors
  List<PieChartSectionData> get pieChartData {
    if (totalSpentForSelectedMonth == 0) return [];

    final categorySpending = spendingByCategory;
    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort by amount descending

    List<PieChartSectionData> sections = [];
    double startDegree = 0; // For ensuring sections don't overlap visually if data is very small

    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final categoryName = entry.key;
      final amount = entry.value;
      final percentage = (amount / totalSpentForSelectedMonth) * 100;

      // Skip very small slices if they would be invisible or ugly
      if (percentage < 3 && sortedCategories.length > 5) { // Threshold for "other" or grouping
        // You might group these into an "Other" category,
        // but for now, we'll just show them if they pass a minimum size, or individually if few categories.
      }

      sections.add(
        PieChartSectionData(
          color: _pieChartColors[i % _pieChartColors.length],
          value: amount, // Use raw amount for value, fl_chart will calculate sizes
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 50, // Size of the slice
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 2) // For readability
            ],
          ),
          showTitle: percentage > 8, // Only show title for larger slices
        ),
      );
    }
    return sections;
  }

  // --- Private Setters for State ---
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _expenseSubscription?.cancel();
    super.dispose();
  }
}