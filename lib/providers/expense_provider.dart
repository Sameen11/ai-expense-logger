import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/expense.dart';
import '../services/expense_service.dart';

class ExpenseProvider with ChangeNotifier {
  final ExpenseService _expenseService = ExpenseService();

  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;
  String? _currentUid;

  StreamSubscription? _expenseSubscription;

  // --- Getters ---
  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // --- Public Methods ---

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