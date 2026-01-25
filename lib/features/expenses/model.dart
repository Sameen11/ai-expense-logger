
import 'package:flutter/material.dart';

// A simple data model for an Expense.
class Expense {
  final String id;
  final String merchant;
  final double amount;
  final DateTime date;
  final String category;
  final IconData icon;
  final String paymentMethod;
  final String notes;
  final String? receiptImageUrl; // URL or path to the receipt image

  Expense({
    required this.id,
    required this.merchant,
    required this.amount,
    required this.date,
    required this.category,
    required this.icon,
    this.paymentMethod = 'Credit Card',
    this.notes = '',
    this.receiptImageUrl,
  });
}
