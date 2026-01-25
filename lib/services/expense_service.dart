import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // --- Private helper to get the subcollection ---
  // This is the key: 'users/{uid}/expenses'
  CollectionReference<Expense> _getExpensesCollection(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('expenses')
        .withConverter<Expense>(
      fromFirestore: (snapshots, _) => Expense.fromFirestore(snapshots),
      toFirestore: (expense, _) => expense.toFirestore(),
    );
  }

  /// Adds a new expense document to the user's 'expenses' subcollection
  Future<void> addExpense(String uid, Expense expense) async {
    await _getExpensesCollection(uid).add(expense);
  }

  /// Updates an existing expense document
  /// CHANGED: Now accepts specific ID and Map data to support partial updates
  Future<void> updateExpense(String uid, String expenseId, Map<String, dynamic> data) async {
    await _getExpensesCollection(uid).doc(expenseId).update(data);
  }

  /// Deletes an expense document
  Future<void> deleteExpense(String uid, String expenseId) async {
    await _getExpensesCollection(uid).doc(expenseId).delete();
  }

  /// Gets a stream of all expenses for a user, ordered by date
  Stream<List<Expense>> getExpensesStream(String uid) {
    return _getExpensesCollection(uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }
}