import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/expense.dart';
import '../../providers/category_provider.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final Expense expense;
  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100], // Light background
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        // Custom back button to match the style
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.grey[800]),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Expense Details',
          style: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // Handle Edit action
            },
            style: TextButton.styleFrom(
                foregroundColor: Colors.blue[700],
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)
                )
            ),
            child: const Text(
              'Edit',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Receipt Image Placeholder
            _buildReceiptPlaceholder(context),
            const SizedBox(height: 24),

            // 2. Details Section
            _buildDetailsCard(context),
            const SizedBox(height: 24),

            // 3. Actions Section
            _buildActionsCard(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Widget for the receipt placeholder
  Widget _buildReceiptPlaceholder(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              color: Colors.grey[600],
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Tap to view full size',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget for the main details card
  Widget _buildDetailsCard(BuildContext context) {
    final category = context.watch<CategoryProvider>()
        .getCategory(expense.category.toLowerCase());
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            context,
            title: 'Merchant',
            value: expense.merchant,
          ),
          _buildDetailRow(
            context,
            title: 'Amount',
            value: NumberFormat.currency(symbol: '\$').format(expense.amount),
            isAmount: true,
          ),
          _buildDetailRow(
            context,
            title: 'Date',
            value: DateFormat('MMM dd, yyyy').format(expense.date),
          ),
          _buildDetailRow(
            context,
            title: 'Category',
            value: expense.category,
            icon: category.iconData,
          ),
          _buildDetailRow(
            context,
            title: 'Payment',
            value: 'Credit Card', // Mock data
          ),
          _buildDetailRow(
            context,
            title: 'Notes',
            value: expense.notes ?? 'No notes', // Handle null notes
            isLast: true,
          ),
        ],
      ),
    );
  }

  // Reusable row for the details card
  Widget _buildDetailRow(
      BuildContext context, {
        required String title,
        required String value,
        IconData? icon,
        bool isAmount = false,
        bool isLast = false,
      }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 16,
            ),
          ),
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: Colors.blue[800], size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                value,
                style: TextStyle(
                  color: Colors.grey[900],
                  fontSize: 16,
                  fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget for the action buttons
  Widget _buildActionsCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildActionRow(
            context,
            title: 'Share Receipt',
            icon: Icons.share_outlined,
            color: Colors.grey[800]!,
            onTap: () {
              // Handle Share
            },
          ),
          _buildActionRow(
            context,
            title: 'Duplicate Expense',
            icon: Icons.copy_outlined,
            color: Colors.grey[800]!,
            onTap: () {
              // Handle Duplicate
            },
          ),
          _buildActionRow(
            context,
            title: 'Delete Expense',
            icon: Icons.delete_outline,
            color: Colors.red[700]!,
            isLast: true,
            onTap: () {
              // Handle Delete
            },
          ),
        ],
      ),
    );
  }

  // Reusable row for the action buttons
  Widget _buildActionRow(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required VoidCallback onTap,
        bool isLast = false,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: isLast
            ? const BorderRadius.vertical(bottom: Radius.circular(16))
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : Border(bottom: BorderSide(color: Colors.grey[200]!)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

