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
    required String emoji,
    String? notes,
    String currency = 'USD', // Default to USD
    List<Map<String, dynamic>>? items,
    double? subtotal,
    double? tax,
    double? tip,
    double? discount,
    String? invoiceNumber,
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
        emoji: emoji,
        currency: currency, // Pass currency
        items: items,
        subtotal: subtotal,
        tax: tax,
        tip: tip,
        discount: discount,
        invoiceNumber: invoiceNumber,
      );
      await _expenseService.addExpense(_currentUid!, newExpense);
      
      // Switch view to the current month (when expense was added) so the user sees it immediately
      final now = DateTime.now();
      updateSelectedMonth(DateTime(now.year, now.month));
      
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
  /// Filters the main list to only expenses in the selected month (by Added On date)
  List<Expense> get expensesForSelectedMonth {
    return _expenses
        .where((e) {
          final addedDate = e.createdAt.toDate();
          return addedDate.year == _selectedMonth.year &&
                 addedDate.month == _selectedMonth.month;
        })
        .toList();
  }

  /// Calculates the total spending for the selected month per currency
  Map<String, double> get totalSpentByCurrency {
    var totals = <String, double>{};
    for (var expense in expensesForSelectedMonth) {
      totals.update(
        expense.currency,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    // Sort by amount descending (optional)
    return totals;
  }

  /// Groups all expenses by category and sums their amounts for a specific currency
  Map<String, double> getCategorySpending(String currency) {
    var categoryTotals = <String, double>{};
    for (var expense in expensesForSelectedMonth.where((e) => e.currency == currency)) {
      categoryTotals.update(
        expense.category,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return categoryTotals;
  }

  /// Legacy getter - returns USD total or first currency total (for backward compatibility if needed)
  double get totalSpentForSelectedMonth {
    if (expensesForSelectedMonth.isEmpty) return 0.0;
    // This is technically misleading if mixed currencies exist, but keeps existing calls safe
    // Ideally, UI should switch to totalSpentByCurrency
    return expensesForSelectedMonth.fold(0.0, (sum, e) => sum + e.amount); 
  }

  /// Groups all expenses by category and sums their amounts (Legacy - sums distinct currencies!)
  Map<String, double> get spendingByCategory {
    // WARNING: This sums amounts of potentially different currencies.
    // Use getCategorySpending(currency) instead.
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

  /// Finds the merchant with the most transactions (Legacy - all currencies)
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

  /// Gets top merchants by receipt count for a specific currency
  List<MapEntry<String, int>> getTopMerchantsByCount(String currency, {int limit = 5}) {
    var merchantCounts = <String, int>{};
    for (var expense in expensesForSelectedMonth.where((e) => e.currency == currency)) {
      merchantCounts.update(
        expense.merchant,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    
    final sorted = merchantCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).toList();
  }

  /// Gets top merchants by total amount for a specific currency
  List<MapEntry<String, double>> getTopMerchantsByAmount(String currency, {int limit = 5}) {
    var merchantAmounts = <String, double>{};
    for (var expense in expensesForSelectedMonth.where((e) => e.currency == currency)) {
      merchantAmounts.update(
        expense.merchant,
        (value) => value + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    
    final sorted = merchantAmounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sorted.take(limit).toList();
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

  /// Prepares data for the pie chart, including percentages and colors for a specific currency
  List<PieChartSectionData> getPieChartData(String currency) {
    final categorySpending = getCategorySpending(currency);
    final total = categorySpending.values.fold(0.0, (sum, val) => sum + val);
    
    if (total == 0) return [];

    final sortedCategories = categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Sort by amount descending

    List<PieChartSectionData> sections = [];

    for (int i = 0; i < sortedCategories.length; i++) {
      final entry = sortedCategories[i];
      final amount = entry.value;
      final percentage = (amount / total) * 100;

      sections.add(
        PieChartSectionData(
          color: _pieChartColors[i % _pieChartColors.length],
          value: amount, 
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 50, 
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [
              Shadow(color: Colors.black, blurRadius: 2) 
            ],
          ),
          showTitle: percentage > 8, 
        ),
      );
    }
    return sections;
  }

  // Legacy getter
  List<PieChartSectionData> get pieChartData {
    if (expensesForSelectedMonth.isEmpty) return [];
    final currency = expensesForSelectedMonth.first.currency;
    return getPieChartData(currency);
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
