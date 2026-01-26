import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/expense.dart';
import '../models/category_stats.dart';
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

  /// Returns the total spent in the month *prior* to the selected month
  Map<String, double> get totalSpentPreviousMonthByCurrency {
    final prevMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);

    final prevMonthExpenses = _expenses.where((e) {
      final addedDate = e.createdAt.toDate();
      return addedDate.year == prevMonth.year &&
          addedDate.month == prevMonth.month;
    });

    var totals = <String, double>{};
    for (var expense in prevMonthExpenses) {
      totals.update(
        expense.currency,
        (val) => val + expense.amount,
        ifAbsent: () => expense.amount,
      );
    }
    return totals;
  }

  /// Returns the percentage change for a specific currency compared to last month
  /// Returns null if last month was 0 (cannot divide by zero/new user)
  double? getPercentageChange(String currency) {
    final currentTotal = totalSpentByCurrency[currency] ?? 0.0;
    final prevTotal = totalSpentPreviousMonthByCurrency[currency] ?? 0.0;

    if (prevTotal == 0) return null; // No previous data or 0 spend

    return ((currentTotal - prevTotal) / prevTotal) * 100;
  }

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
    _expenseSubscription = _expenseService
        .getExpensesStream(uid)
        .listen(
          (expenses) {
            _expenses = expenses;
            _setError(null);
            _setLoading(false);
          },
          onError: (e) {
            _setError(e.toString());
            _setLoading(false);
          },
        );
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
    String? receiptPath,
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
        receiptPath: receiptPath,
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

  Future<void> updateExpense(String? expenseId, Expense updatedExpense) async {
    if (_currentUid == null) {
      _setError("User not logged in");
      return;
    }

    _setLoading(true);
    try {
      // Create a map of the data to update
      // Note: We don't update createdAt to preserve the original sort order
      final data = {
        'merchant': updatedExpense.merchant,
        'amount': updatedExpense.amount,
        'date': Timestamp.fromDate(updatedExpense.date),
        'category': updatedExpense.category,
        'emoji': updatedExpense.emoji,
        'notes': updatedExpense.notes,
        'currency': updatedExpense.currency,
        'items': updatedExpense.items,
        'subtotal': updatedExpense.subtotal,
        'tax': updatedExpense.tax,
        'tip': updatedExpense.tip,
        'discount': updatedExpense.discount,
        'invoiceNumber': updatedExpense.invoiceNumber,
      };

      await _expenseService.updateExpense(_currentUid!, expenseId!, data);

      // Update local list directly for immediate UI feedback (optional, as stream handles it)
      final index = _expenses.indexWhere((e) => e.id == expenseId);
      if (index != -1) {
        _expenses[index] = updatedExpense;
        notifyListeners();
      }
    } catch (e) {
      _setError(e.toString());
      rethrow;
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

  Future<void> updateCategoryForExpenses(
    String oldCategory,
    String newCategory,
  ) async {
    if (_currentUid == null) {
      _setError("User not logged in");
      return;
    }
    _setLoading(true);
    try {
      await _expenseService.updateCategoryForExpenses(
        _currentUid!,
        oldCategory,
        newCategory,
      );
    } catch (e) {
      _setError(e.toString());
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// Filters the main list to only expenses in the selected month (by Added On date)
  List<Expense> get expensesForSelectedMonth {
    return _expenses.where((e) {
      final addedDate = e.createdAt.toDate();
      return addedDate.year == _selectedMonth.year &&
          addedDate.month == _selectedMonth.month;
    }).toList();
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
    for (var expense in expensesForSelectedMonth.where(
      (e) => e.currency == currency,
    )) {
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
    final daysInMonth = DateUtils.getDaysInMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

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
    final top = merchantCounts.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    return "${top.key} (${top.value}x)";
  }

  /// Gets top merchants by receipt count for a specific currency
  List<MapEntry<String, int>> getTopMerchantsByCount(
    String currency, {
    int limit = 5,
  }) {
    var merchantCounts = <String, int>{};
    for (var expense in expensesForSelectedMonth.where(
      (e) => e.currency == currency,
    )) {
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
  List<MapEntry<String, double>> getTopMerchantsByAmount(
    String currency, {
    int limit = 5,
  }) {
    var merchantAmounts = <String, double>{};
    for (var expense in expensesForSelectedMonth.where(
      (e) => e.currency == currency,
    )) {
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

  // --- TREDS: Daily & Cumulative ---

  /// Returns data for the LineChart (Daily Trend) for a specific currency
  /// Fills in 0.0 for days with no expenses to ensure the chart is continuous
  List<FlSpot> getDailyTrendPoints(String currency) {
    if (expensesForSelectedMonth.isEmpty) {
      // Return empty list so UI can show "No Data"
      return [];
    }

    final daysInMonth = DateUtils.getDaysInMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    // 1. Group by day
    final Map<int, double> dailyTotals = {};
    for (int i = 1; i <= daysInMonth; i++) {
      dailyTotals[i] = 0.0;
    }

    for (var expense in expensesForSelectedMonth.where(
      (e) => e.currency == currency,
    )) {
      final day = expense.createdAt.toDate().day;
      dailyTotals[day] = (dailyTotals[day] ?? 0.0) + expense.amount;
    }

    // 2. Convert to FlSpot list
    return dailyTotals.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  /// Returns cumulative spending points for the selected month
  List<FlSpot> getCumulativeTrendPoints(String currency) {
    if (expensesForSelectedMonth.isEmpty) return [];

    final dailySpots = getDailyTrendPoints(currency);
    List<FlSpot> cumulativeSpots = [];
    double runningTotal = 0.0;

    for (var spot in dailySpots) {
      runningTotal += spot.y;
      cumulativeSpots.add(FlSpot(spot.x, runningTotal));
    }

    return cumulativeSpots;
  }

  /// Returns daily trend points for the PREVIOUS month (for comparison)
  /// X-axis matches current month days (1-31)
  List<FlSpot> getLastMonthTrendPoints(String currency) {
    final prevMonthDate = DateTime(
      _selectedMonth.year,
      _selectedMonth.month - 1,
    );

    // Filter expenses for previous month
    final prevMonthExpenses = _expenses.where((e) {
      final addedDate = e.createdAt.toDate();
      return addedDate.year == prevMonthDate.year &&
          addedDate.month == prevMonthDate.month &&
          e.currency == currency;
    }).toList();

    if (prevMonthExpenses.isEmpty) return [];

    final daysInPrevMonth = DateUtils.getDaysInMonth(
      prevMonthDate.year,
      prevMonthDate.month,
    );

    final Map<int, double> dailyTotals = {};
    // Initialize all days to 0
    final maxDays = DateUtils.getDaysInMonth(
      _selectedMonth.year,
      _selectedMonth.month,
    );

    for (int i = 1; i <= maxDays; i++) {
      // If prev month had fewer days (e.g. Feb vs Mar), just skip or flatline?
      // We'll just map 1:1 up to what's possible
      if (i <= daysInPrevMonth) {
        dailyTotals[i] = 0.0;
      }
    }

    for (var expense in prevMonthExpenses) {
      final day = expense.createdAt.toDate().day;
      dailyTotals[day] = (dailyTotals[day] ?? 0.0) + expense.amount;
    }

    return dailyTotals.entries
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));
  }

  // --- MONTHLY BAR CHART DATA ---

  /// Returns total spending for the last 6 months (including current)
  /// Map key is "MMM" (e.g., "Jan", "Feb") or DateTime
  Map<DateTime, double> getSixMonthTrend(String currency) {
    // Start from 5 months ago
    final Map<DateTime, double> monthlyData = {};
    final now =
        _selectedMonth; // Use selected month as anchor? Or Today? usually Today is better for "History"

    // Let's anchor on "Today" so it shows valid history regardless of selected month
    final anchor = DateTime.now();

    for (int i = 5; i >= 0; i--) {
      final month = DateTime(anchor.year, anchor.month - i);
      // Filter expenses for this month
      final monthExpenses = _expenses.where((e) {
        final d = e.createdAt.toDate();
        return d.year == month.year &&
            d.month == month.month &&
            e.currency == currency;
      });

      final total = monthExpenses.fold(0.0, (sum, e) => sum + e.amount);
      monthlyData[month] = total;
    }
    return monthlyData;
  }

  // --- PIE CHART & CATEGORY DETAILS ---

  /// Returns detailed stats for each category
  List<CategoryStats> getCategoryDetails(String currency) {
    final expenses = expensesForSelectedMonth
        .where((e) => e.currency == currency)
        .toList();
    if (expenses.isEmpty) return [];

    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);

    // Group by category
    final Map<String, List<Expense>> grouped = {};
    for (var e in expenses) {
      if (!grouped.containsKey(e.category)) grouped[e.category] = [];
      grouped[e.category]!.add(e);
    }

    List<CategoryStats> stats = [];
    grouped.forEach((category, list) {
      final catTotal = list.fold(0.0, (sum, e) => sum + e.amount);
      final avg = catTotal / list.length;

      // Find top merchant
      final Map<String, double> merchantSpend = {};
      for (var e in list) {
        merchantSpend.update(
          e.merchant,
          (val) => val + e.amount,
          ifAbsent: () => e.amount,
        );
      }
      // Sort to find max
      var topMerchant = "N/A";
      if (merchantSpend.isNotEmpty) {
        final topEntry = merchantSpend.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
        topMerchant = topEntry.key;
      }
      // Get emoji from first expense
      final emoji = list.first.emoji ?? "🏷️";

      stats.add(
        CategoryStats(
          categoryName: category,
          emoji: emoji,
          totalAmount: catTotal,
          percentage: totalSpent > 0 ? (catTotal / totalSpent) : 0,
          transactionCount: list.length,
          averageSpend: avg,
          topMerchant: topMerchant,
        ),
      );
    });

    // Sort by Total Amount Descending
    stats.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return stats;
  }

  /// Prepares data for the pie chart, grouping small % into "Other"
  List<PieChartSectionData> getPieChartData(String currency) {
    final stats = getCategoryDetails(currency);
    if (stats.isEmpty) return [];

    final total = stats.fold(0.0, (sum, s) => sum + s.totalAmount);
    if (total == 0) return [];

    List<PieChartSectionData> sections = [];
    double otherTotal = 0;
    final double threshold = 0.05; // 5%

    int colorIndex = 0;

    for (var stat in stats) {
      if (stat.percentage < threshold && stats.length > 5) {
        // Add to Other
        otherTotal += stat.totalAmount;
      } else {
        sections.add(
          PieChartSectionData(
            color: _pieChartColors[colorIndex % _pieChartColors.length],
            value: stat.totalAmount,
            title: '${(stat.percentage * 100).toStringAsFixed(0)}%',
            radius: 50,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black, blurRadius: 2)],
            ),
            showTitle: true,
          ),
        );
        colorIndex++;
      }
    }

    if (otherTotal > 0) {
      sections.add(
        PieChartSectionData(
          color: Colors.grey,
          value: otherTotal,
          title: '${((otherTotal / total) * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
          showTitle: true,
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
