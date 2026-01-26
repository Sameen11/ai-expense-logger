import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:ai_expense_logger/widgets/digital_receipt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/expense.dart';
import '../../providers/expense_provider.dart';
import '../../utils/currency_utils.dart';
import '../snap/add_expense.dart';

class ExpenseDetailScreen extends StatefulWidget {
  final Expense expense;
  const ExpenseDetailScreen({super.key, required this.expense});

  @override
  State<ExpenseDetailScreen> createState() => _ExpenseDetailScreenState();
}

class _ExpenseDetailScreenState extends State<ExpenseDetailScreen> {
  final GlobalKey _receiptKey = GlobalKey();

  // Helper function to get emoji for expense with fallback
  String _getEmojiForExpense(Expense expense) {
    if (expense.emoji != null && expense.emoji!.trim().isNotEmpty) {
      final emoji = expense.emoji!.trim();
      if (emoji.length > 0 &&
          emoji != '×' &&
          emoji != '✕' &&
          emoji != '✖' &&
          emoji != 'X' &&
          emoji != 'x') {
        return emoji;
      }
    }

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

    return '📦';
  }

  void _handleEdit(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddExpenseManuallyScreen(expenseToEdit: widget.expense),
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
        await context.read<ExpenseProvider>().deleteExpense(widget.expense.id!);
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
        merchant: "${widget.expense.merchant} (Copy)",
        amount: widget.expense.amount,
        date: DateTime.now(),
        category: widget.expense.category,
        emoji: widget.expense.emoji ?? '📦',
        notes: widget.expense.notes,
        currency: widget.expense.currency,
        items: widget.expense.items,
        subtotal: widget.expense.subtotal,
        tax: widget.expense.tax,
        tip: widget.expense.tip,
        discount: widget.expense.discount,
        invoiceNumber: widget.expense.invoiceNumber,
        receiptPath: widget.expense.receiptPath,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Expense duplicated successfully!")),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error duplicating: $e")));
      }
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    try {
      // 1. Capture the widget as an image using RepaintBoundary
      RenderRepaintBoundary? boundary =
          _receiptKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;

      if (boundary == null) {
        // Fallback to text share if boundary not found (e.g. not rendered yet)
        _shareTextFallback();
        return;
      }

      // Convert to image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0); // High res
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );

      if (byteData != null) {
        final Uint8List pngBytes = byteData.buffer.asUint8List();

        // 2. Save to temporary file
        final tempDir = await getTemporaryDirectory();
        final file = await File(
          '${tempDir.path}/receipt_${widget.expense.id ?? "temp"}.png',
        ).create();
        await file.writeAsBytes(pngBytes);

        // 3. Share the file
        if (mounted) {
          await Share.shareXFiles(
            [XFile(file.path)],
            text: 'Receipt from ${widget.expense.merchant}',
            subject: 'Expense Receipt',
          );
        }
      } else {
        _shareTextFallback();
      }
    } catch (e) {
      debugPrint("Error sharing image: $e");
      _shareTextFallback();
    }
  }

  void _shareTextFallback() {
    final dateStr = DateFormat('MMM dd, yyyy').format(widget.expense.date);
    final amountStr = CurrencyUtils.formatAmount(
      widget.expense.amount,
      widget.expense.currency,
    );

    final StringBuffer sb = StringBuffer();
    sb.writeln("🧾 Receipt from ${widget.expense.merchant}");
    sb.writeln("Amount: $amountStr");
    sb.writeln("Date: $dateStr");
    sb.writeln("Category: ${widget.expense.category}");
    Share.share(sb.toString());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
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
            // 1. Digital Receipt (Replaces Placeholder)
            // Wrapped in RepaintBoundary for screenshot
            RepaintBoundary(
              key: _receiptKey,
              child: DigitalReceiptWidget(expense: widget.expense),
            ),
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

  // Removed _buildReceiptPlaceholder since we are using DigitalReceiptWidget directly

  // ... keep _buildDetailsCard, _buildActionsCard etc. but update 'expense' references to 'widget.expense'

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
          _buildDetailRow(
            context,
            title: 'Merchant',
            value: widget.expense.merchant,
          ),
          _buildDetailRow(
            context,
            title: 'Amount',
            value: CurrencyUtils.formatAmount(
              widget.expense.amount,
              widget.expense.currency,
            ),
            isAmount: true,
          ),
          _buildDetailRow(
            context,
            title: 'Receipt Date',
            value:
                (widget.expense.date.hour != 0 ||
                    widget.expense.date.minute != 0)
                ? DateFormat(
                    'MMM dd, yyyy • h:mm a',
                  ).format(widget.expense.date)
                : DateFormat('MMM dd, yyyy').format(widget.expense.date),
          ),
          _buildDetailRow(
            context,
            title: 'Added On',
            value: DateFormat(
              'MMM dd, yyyy • h:mm a',
            ).format(widget.expense.createdAt.toDate()),
          ),
          _buildDetailRow(
            context,
            title: 'Category',
            value: widget.expense.category,
            emoji: _getEmojiForExpense(widget.expense),
          ),
          _buildDetailRow(
            context,
            title: 'Payment',
            value: 'Credit Card', // Mock data
          ),
          if (widget.expense.invoiceNumber != null &&
              widget.expense.invoiceNumber!.isNotEmpty)
            _buildDetailRow(
              context,
              title: 'Invoice #',
              value: widget.expense.invoiceNumber!,
            ),
          _buildDetailRow(
            context,
            title: 'Notes',
            value: widget.expense.notes ?? 'No notes', // Handle null notes
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
