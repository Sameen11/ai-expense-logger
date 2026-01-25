import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/expense.dart';
import '../../providers/category_provider.dart';
import '../../providers/expense_provider.dart';
import '../../utils/currency_utils.dart';
// import '../../common/colors.dart';
import '../snap/add_expense.dart';

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
      if (emoji.length > 0 &&
          emoji != '×' &&
          emoji != '✕' &&
          emoji != '✖' &&
          emoji != 'X' &&
          emoji != 'x') {
        return emoji;
      }
    }

    // Fallback to category-based emoji
    final categoryEmojiMap = {
      'Food & Drinks': '🍜',
      'Groceries': '🥬',
      'Transport': '🚖',
      'Shopping': '🛍️',
      'Subscriptions': '💳',
      'Bills & Utilities': '⚡',
      'Salary': '💰',
      'Business': '🤝',
      'Investments': '📈',
      'Health': '🩺',
      'Entertainment': '🍿',
      'Travel': '🌏',
      'Other': '🧩',
    };

    final categoryEmoji = categoryEmojiMap[expense.category];
    if (categoryEmoji != null) {
      return categoryEmoji;
    }

    // Final fallback
    return '📦';
  }

  void _handleEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddExpenseManuallyScreen(expenseToEdit: expense),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context.read<ExpenseProvider>().deleteExpense(expense.id!);
        if (context.mounted) {
          Navigator.pop(context); // Pop detail screen
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Expense deleted")));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
      }
    }
  }

  Future<void> _handleDuplicate(BuildContext context) async {
    try {
      await context.read<ExpenseProvider>().addExpense(
        merchant: "${expense.merchant} (Copy)",
        amount: expense.amount,
        date: DateTime.now(), // Set to current time or keep original?
        category: expense.category,
        emoji: expense.emoji ?? '📦',
        notes: expense.notes,
        currency: expense.currency,
        items: expense.items,
        subtotal: expense.subtotal,
        tax: expense.tax,
        tip: expense.tip,
        discount: expense.discount,
        invoiceNumber: expense.invoiceNumber,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expense duplicated successfully!")),
        );
        Navigator.pop(context); // Go back to list to see the duplicate
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error duplicating: $e")));
      }
    }
  }

  void _handleShare(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(expense.date);
    final amountStr = CurrencyUtils.formatAmount(
      expense.amount,
      expense.currency,
    );

    final StringBuffer sb = StringBuffer();
    sb.writeln("🧾 Receipt from ${expense.merchant}");
    sb.writeln("Amount: $amountStr");
    sb.writeln("Date: $dateStr");
    sb.writeln("Category: ${expense.category}");

    if (expense.items != null && expense.items!.isNotEmpty) {
      sb.writeln("\nItems:");
      for (var item in expense.items!) {
        final name = item['name'];
        final price = item['total_price'];
        sb.writeln(
          "- $name: ${CurrencyUtils.formatAmount(price, expense.currency)}",
        );
      }
    }

    Share.share(sb.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Light background
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        // Custom back button to match the style
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Expense Details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _handleEdit(context),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Edit',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
    final theme = Theme.of(context);
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? theme.cardColor
            : Colors.grey[200],
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
                  color: theme.colorScheme.onSurfaceVariant,
                  size: 60,
                ),
                const SizedBox(height: 16),
                Text(
                  expense.merchant,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap to view full size',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'AI Expense Logger',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildDetailRow(context, title: 'Merchant', value: expense.merchant),
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
            value: DateFormat(
              'MMM dd, yyyy • h:mm a',
            ).format(expense.createdAt.toDate()),
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
          if (expense.invoiceNumber != null &&
              expense.invoiceNumber!.isNotEmpty)
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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Receipt Breakdown",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      CurrencyUtils.formatAmount(
                        (item['total_price'] as num?)?.toDouble() ?? 0.0,
                        expense.currency,
                      ),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }),

          Divider(height: 24, color: theme.dividerColor.withOpacity(0.1)),

          if (expense.subtotal != null && expense.subtotal! > 0)
            _breakdownRow(context, "Subtotal", expense.subtotal!),
          if (expense.discount != null && expense.discount! > 0)
            _breakdownRow(
              context,
              "Discount",
              -expense.discount!,
              isDiscount: true,
            ),
          if (expense.tax != null && expense.tax! > 0)
            _breakdownRow(context, "Tax", expense.tax!),
          if (expense.tip != null && expense.tip! > 0)
            _breakdownRow(context, "Tip", expense.tip!),

          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                CurrencyUtils.formatAmount(expense.amount, expense.currency),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(
    BuildContext context,
    String title,
    double amount, {
    bool isDiscount = false,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              CurrencyUtils.formatAmount(amount, expense.currency),
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDiscount ? Colors.green : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              title,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (emoji != null) ...[
                  Text(emoji ?? "📦", style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: isAmount
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildActionRow(
            context,
            title: 'Share Receipt',
            icon: Icons.share_outlined,
            color: theme.colorScheme.onSurface,
            onTap: () => _handleShare(context), // CONNECTED SHARE
          ),
          _buildActionRow(
            context,
            title: 'Duplicate Expense',
            icon: Icons.copy_outlined,
            color: theme.colorScheme.onSurface,
            onTap: () => _handleDuplicate(context), // CONNECTED DUPLICATE
          ),
          _buildActionRow(
            context,
            title: 'Delete Expense',
            icon: Icons.delete_outline,
            color: Colors.red[700]!,
            isLast: true,
            onTap: () => _handleDelete(context), // CONNECTED DELETE
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
    final theme = Theme.of(context);
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
                : Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withOpacity(0.1),
                    ),
                  ),
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
