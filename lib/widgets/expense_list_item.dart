import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../common/colors.dart';
import '../features/expenses/expense_detail.dart';
import '../models/expense.dart';
import '../navigation/nav_manager.dart';
import '../utils/currency_utils.dart';

class ExpenseListItem extends StatelessWidget {
  final Expense expense;

  final bool hasContainer;

  const ExpenseListItem({
    super.key,
    required this.expense,
    this.hasContainer = true,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a consistent color based on category name
    final Color categoryColor = _getCategoryColor(expense.category);

    final Widget content = InkWell(
      borderRadius: hasContainer ? BorderRadius.circular(20) : null,
      onTap: () => NavigationManager.push(
        context,
        ExpenseDetailScreen(expense: expense),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // 1. Emoji with Background
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(expense.emoji, style: const TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 16),

            // 2. Info Column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Merchant Name
                  Text(
                    expense.merchant,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Subtitle Row: Date only
                  Text(
                    _formatDate(expense.createdAt.toDate()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // 3. Amount & Category Column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${CurrencyUtils.formatAmount(expense.amount, expense.currency)}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    expense.category,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: categoryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    final theme = Theme.of(context);

    if (!hasContainer) {
      return Material(color: Colors.transparent, child: content);
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          if (theme.brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              offset: const Offset(0, 4),
              blurRadius: 16,
            ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: content,
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final checkDate = DateTime(date.year, date.month, date.day);

    if (checkDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (checkDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  Color _getCategoryColor(String category) {
    // Simple hash-based color generation for consistency
    final colors = [
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.green,
      Colors.red,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];
    return colors[category.hashCode.abs() % colors.length];
  }
}
