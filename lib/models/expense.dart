import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String? id; // Firestore document ID
  final String merchant;
  final double amount;
  final DateTime date;
  final String category;
  final String? notes;
  final Timestamp createdAt;
  final String emoji;


  Expense({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.notes,
    required this.createdAt,
    required this.emoji,
  });

  // Factory constructor to create an Expense from a Firestore snapshot
  factory Expense.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, [SnapshotOptions? options]) {
    final data = snapshot.data()!;
    return Expense(
      id: snapshot.id,
      merchant: data['merchant'] as String,
      amount: data['amount'] as double,
      date: (data['date'] as Timestamp).toDate(),
      category: data['category'] as String,
      notes: data['notes'] as String?,
      createdAt: data['createdAt'] as Timestamp,
      emoji: data['emoji'] as String,
    );
  }

  // Method to convert an Expense instance to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'merchant': merchant,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'notes': notes,
      'createdAt': createdAt, // Will be set on add
      'emoji': emoji,
    };
  }
}