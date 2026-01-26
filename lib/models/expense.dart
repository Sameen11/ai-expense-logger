import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String? id; // Firestore document ID
  final String merchant;
  final double amount; // This is the Grand Total
  final DateTime date;
  final String category;
  final String? notes;
  final Timestamp createdAt;
  final String emoji;
  final String currency; // Currency code (USD, PKR, EUR, etc.)

  // --- Detailed Fields (Optional) ---
  final List<Map<String, dynamic>>?
  items; // [{'name': 'Pizza', 'price': 10.0, 'qty': 1}]
  final double? subtotal;
  final double? tax;
  final double? tip;
  final double? discount;
  final String? invoiceNumber;
  final String? receiptPath;

  Expense({
    this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    this.notes,
    required this.createdAt,
    required this.emoji,
    this.currency = 'USD',
    this.items,
    this.subtotal,
    this.tax,
    this.tip,
    this.discount,
    this.invoiceNumber,
    this.receiptPath,
  });

  // Factory constructor to create an Expense from a Firestore snapshot
  factory Expense.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot, [
    SnapshotOptions? options,
  ]) {
    final data = snapshot.data();
    if (data == null) {
      // Should theoretically not happen for existing docs
      throw Exception("Document ${snapshot.id} is empty");
    }

    return Expense(
      id: snapshot.id,
      merchant: data['merchant'] as String? ?? 'Unknown',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: data['category'] as String? ?? 'Other',
      notes: data['notes'] as String?,
      createdAt: data['createdAt'] as Timestamp? ?? Timestamp.now(),
      emoji: data['emoji'] as String? ?? '📦',
      currency: data['currency'] as String? ?? 'USD',

      // Load detailed fields safely
      items: data['items'] is List
          ? (data['items'] as List).cast<Map<String, dynamic>>()
          : null,
      subtotal: (data['subtotal'] as num?)?.toDouble(),
      tax: (data['tax'] as num?)?.toDouble(),
      tip: (data['tip'] as num?)?.toDouble(),
      discount: (data['discount'] as num?)?.toDouble(),
      invoiceNumber: data['invoice_number'] as String?,
      receiptPath: data['receipt_path'] as String?,
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
      'createdAt': createdAt,
      'emoji': emoji,
      'currency': currency,

      // Save detailed fields
      if (items != null) 'items': items,
      if (subtotal != null) 'subtotal': subtotal,
      if (tax != null) 'tax': tax,
      if (tip != null) 'tip': tip,
      if (discount != null) 'discount': discount,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (receiptPath != null) 'receipt_path': receiptPath,
    };
  }
}
