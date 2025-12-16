import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/expense.dart';
import '../../providers/category_provider.dart';
import '../../utils/currency_utils.dart';
import '../../common/colors.dart';

class ExpenseDetailScreen extends StatelessWidget {
  final Expense expense;
  const ExpenseDetailScreen({super.key, required this.expense});

  // Helper function to get emoji for expense with fallback
  String _getEmojiForExpense(Expense expense) {
    // Check if emoji is valid (not null, not empty, and not just whitespace)
    if (expense.emoji != null && expense.emoji!.trim().isNotEmpty) {
      // Check if it's a valid emoji (not a single character that might be a cross)
      final emoji = expense.emoji!.trim();
      // If it's a valid emoji string, return it
      if (emoji.length > 0 && emoji != '×' && emoji != '✕' && emoji != '✖' && emoji != 'X' && emoji != 'x') {
        return emoji;
      }
    }
    
    // Fallback to category-based emoji
    final categoryEmojiMap = {
      'Food & Drinks': '🍔',
      'Groceries': '🛒',
      'Transport': '🚌',
      'Shopping': '🛍',
      'Subscriptions': '📺',
      'Bills & Utilities': '💡',
      'Salary': '💼',
      'Business': '🏢',
      'Investments': '📈',
      'Health': '❤️',
      'Entertainment': '🎬',
      'Travel': '✈️',
      'Other': '📦',
    };
    
    final categoryEmoji = categoryEmojiMap[expense.category];
    if (categoryEmoji != null) {
      return categoryEmoji;
    }
    
    // Final fallback
    return '📦';
  }

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

            // 3. Receipt Breakdown Section (New)
            if (expense.items != null && expense.items!.isNotEmpty) ...[
              _buildBreakdownCard(context),
              const SizedBox(height: 24),
            ],

            // 4. Actions Section
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
      child: Stack(
        children: [
          Center(
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
                  expense.merchant,
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
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
          // App Watermark
          Positioned(
            bottom: 12,
            right: 12,
            child: Opacity(
              opacity: 0.4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AI Expense Logger',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget for the main details card
  Widget _buildDetailsCard(BuildContext context) {
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
            value: CurrencyUtils.formatAmount(expense.amount, expense.currency),
            isAmount: true,
          ),
          _buildDetailRow(
            context,
            title: 'Receipt Date',
            value: (expense.date.hour != 0 || expense.date.minute != 0)
                ? DateFormat('MMM dd, yyyy • h:mm a').format(expense.date)
                : DateFormat('MMM dd, yyyy').format(expense.date),
          ),
          _buildDetailRow(
            context,
            title: 'Added On',
            value: DateFormat('MMM dd, yyyy • h:mm a').format(expense.createdAt.toDate()),
          ),
          _buildDetailRow(
            context,
            title: 'Category',
            value: expense.category,
            emoji: _getEmojiForExpense(expense),
          ),
          _buildDetailRow(
            context,
            title: 'Payment',
            value: 'Credit Card', // Mock data
          ),
          if (expense.invoiceNumber != null && expense.invoiceNumber!.isNotEmpty)
            _buildDetailRow(
              context,
              title: 'Invoice #',
              value: expense.invoiceNumber!,
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

  // NEW: Breakdown Card
  Widget _buildBreakdownCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Receipt Breakdown", 
            style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: Color(0xff1C1C1E),
            )
          ),
          const SizedBox(height: 16),
          // Items
          if (expense.items != null)
            ...expense.items!.map((item) {
              final quantity = (item['quantity'] as num?)?.toDouble() ?? 1.0;
              final itemName = item['name'] ?? 'Item';
              final displayName = quantity > 1.0 
                  ? '${quantity.toStringAsFixed(0)}x $itemName'
                  : itemName;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(fontSize: 14, color: Color(0xff1C1C1E)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      CurrencyUtils.formatAmount(
                          (item['total_price'] as num?)?.toDouble() ?? 0.0, 
                          expense.currency
                      ),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xff1C1C1E)),
                    ),
                  ],
                ),
              );
            }),
          
          const Divider(height: 24, color: Color(0xFFEEEEEE)),
          
          if (expense.subtotal != null && expense.subtotal! > 0) 
            _breakdownRow("Subtotal", expense.subtotal!),
          if (expense.discount != null && expense.discount! > 0) 
            _breakdownRow("Discount", -expense.discount!, isDiscount: true),
          if (expense.tax != null && expense.tax! > 0) 
            _breakdownRow("Tax", expense.tax!),
          if (expense.tip != null && expense.tip! > 0) 
            _breakdownRow("Tip", expense.tip!),
          
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Total", 
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: Color(0xff1C1C1E),
                )
              ),
              Text(
                CurrencyUtils.formatAmount(expense.amount, expense.currency),
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: AppColors.primaryColor
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String title, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title, 
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              CurrencyUtils.formatAmount(amount, expense.currency),
              textAlign: TextAlign.end,
              style: TextStyle(
                color: isDiscount ? Colors.green : const Color(0xff1C1C1E),
                fontSize: 14,
                fontWeight: FontWeight.w600
              ),
              overflow: TextOverflow.ellipsis,
            ),
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
        String? emoji,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null) ...[
                  Text(
                    emoji ?? "📦",
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 16,
                      fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
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
