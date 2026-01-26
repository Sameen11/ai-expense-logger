import 'package:ai_expense_logger/models/expense.dart';
import 'package:ai_expense_logger/providers/category_provider.dart';
import 'package:ai_expense_logger/utils/currency_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class DigitalReceiptWidget extends StatelessWidget {
  final Expense expense;
  final bool
  isForSharing; // Use this to remove background transparency if needed

  const DigitalReceiptWidget({
    super.key,
    required this.expense,
    this.isForSharing = false,
  });

  @override
  Widget build(BuildContext context) {
    // Receipts are typically white paper with black ink
    const receiptColor = Colors.white;
    const inkColor = Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: receiptColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: isForSharing
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                const Icon(Icons.receipt_long, color: inkColor, size: 32),
                const SizedBox(height: 8),
                Text(
                  'ExpenseMind',
                  style: TextStyle(
                    color: inkColor.withOpacity(0.6),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  expense.merchant.toUpperCase(),
                  style: const TextStyle(
                    color: inkColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('MMM dd, yyyy • h:mm a').format(expense.date),
                  style: TextStyle(
                    color: inkColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Divider(color: Colors.black12, thickness: 1),
          const SizedBox(height: 16),

          // Items
          if (expense.items != null && expense.items!.isNotEmpty) ...[
            ...expense.items!.map((item) {
              final quantity = (item['quantity'] as num?)?.toDouble() ?? 1.0;
              final itemName = item['name'] ?? 'Item';
              final price = (item['total_price'] as num?)?.toDouble() ?? 0.0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        quantity > 1
                            ? '${quantity.toInt()}x $itemName'
                            : itemName,
                        style: const TextStyle(
                          color: inkColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      CurrencyUtils.formatAmount(price, expense.currency),
                      style: const TextStyle(
                        color: inkColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total Amount",
                  style: TextStyle(
                    color: inkColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  CurrencyUtils.formatAmount(expense.amount, expense.currency),
                  style: const TextStyle(
                    color: inkColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),
          const Divider(color: Colors.black12, thickness: 1),
          const SizedBox(height: 16),

          // Totals Breakdown
          if (expense.items != null && expense.items!.isNotEmpty) ...[
            if (expense.subtotal != null)
              _buildSummaryRow(
                "Subtotal",
                expense.subtotal!,
                inkColor,
                expense.currency,
              ),
            if (expense.tax != null)
              _buildSummaryRow("Tax", expense.tax!, inkColor, expense.currency),
            if (expense.tip != null)
              _buildSummaryRow("Tip", expense.tip!, inkColor, expense.currency),
            if (expense.discount != null)
              _buildSummaryRow(
                "Discount",
                -expense.discount!,
                Colors.green,
                expense.currency,
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "TOTAL",
                  style: TextStyle(
                    color: inkColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  CurrencyUtils.formatAmount(expense.amount, expense.currency),
                  style: const TextStyle(
                    color: inkColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),
          const Divider(color: Colors.black12, thickness: 1),
          const SizedBox(height: 16),

          // Additional Details
          // Category with emoji and color
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Category",
                  style: TextStyle(color: Colors.black54, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(context).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _getCategoryColor(context).withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getCategoryIcon(context),
                        color: _getCategoryColor(context),
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        expense.category,
                        style: TextStyle(
                          color: _getCategoryColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildSummaryRow(
            "Payment",
            0,
            inkColor,
            expense.currency,
            valueOverride: "Credit Card",
          ),
          if (expense.invoiceNumber != null &&
              expense.invoiceNumber!.isNotEmpty)
            _buildSummaryRow(
              "Invoice #",
              0,
              inkColor,
              expense.currency,
              valueOverride: expense.invoiceNumber!,
            ),
          if (expense.notes != null && expense.notes!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Notes:",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    expense.notes!,
                    style: const TextStyle(
                      color: inkColor,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),

          // Footer
          Center(
            child: Column(
              children: [
                Text(
                  "Thank you!",
                  style: TextStyle(
                    fontFamily: 'Cursive',
                    fontSize: 18,
                    color: inkColor.withOpacity(0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 24),

                // Financial Quote
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _getRandomQuote(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.amber.shade900,
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Transaction ID
                Text(
                  "ID: ${expense.id ?? "TEMP-${DateTime.now().millisecondsSinceEpoch}"}",
                  style: const TextStyle(
                    color: Colors.black38,
                    fontSize: 9,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double val,
    Color color,
    String currency, {
    String? valueOverride,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
          ),
          Text(
            valueOverride ?? CurrencyUtils.formatAmount(val, currency),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(BuildContext context) {
    try {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      final category = categoryProvider.getCategory(expense.category);
      return category.iconData;
    } catch (e) {
      // Fallback to default icon if provider not available
      return Icons.category;
    }
  }

  Color _getCategoryColor(BuildContext context) {
    try {
      final categoryProvider = Provider.of<CategoryProvider>(
        context,
        listen: false,
      );
      final category = categoryProvider.getCategory(expense.category);
      return category.colorValue;
    } catch (e) {
      // Fallback to gray if provider not available
      return const Color(0xFF6C757D);
    }
  }

  String _getRandomQuote() {
    final quotes = [
      '"A budget is telling your money where to go instead of wondering where it went." - Dave Ramsey',
      '"Do not save what is left after spending, but spend what is left after saving." - Warren Buffett',
      '"The habit of saving is itself an education; it fosters every virtue." - T.T. Munger',
      '"Wealth is not about having a lot of money; it\'s about having a lot of options." - Chris Rock',
      '"An investment in knowledge pays the best interest." - Benjamin Franklin',
      '"Financial peace isn\'t the acquisition of stuff. It\'s learning to live on less than you make." - Dave Ramsey',
      '"The best time to plant a tree was 20 years ago. The second best time is now." - Chinese Proverb',
      '"Price is what you pay. Value is what you get." - Warren Buffett',
      '"Too many people spend money they haven\'t earned, to buy things they don\'t want, to impress people they don\'t like." - Will Rogers',
      '"It\'s not how much money you make, but how much money you keep." - Robert Kiyosaki',
      '"Beware of little expenses; a small leak will sink a great ship." - Benjamin Franklin',
      '"The stock market is filled with individuals who know the price of everything, but the value of nothing." - Philip Fisher',
      '"Never spend your money before you have it." - Thomas Jefferson',
      '"A penny saved is a penny earned." - Benjamin Franklin',
      '"Money is only a tool. It will take you wherever you wish, but it will not replace you as the driver." - Ayn Rand',
      '"The individual investor should act consistently as an investor and not as a speculator." - Ben Graham',
      '"Compound interest is the eighth wonder of the world." - Albert Einstein',
      '"The goal isn\'t more money. The goal is living life on your terms." - Chris Brogan',
      '"Rich people have small TVs and big libraries, and poor people have small libraries and big TVs." - Zig Ziglar',
      '"The quickest way to double your money is to fold it in half and put it in your back pocket." - Will Rogers',
      '"Money grows on the tree of persistence." - Japanese Proverb',
      '"Formal education will make you a living; self-education will make you a fortune." - Jim Rohn',
      '"The art is not in making money, but in keeping it." - Proverb',
      '"Don\'t tell me what you value, show me your budget, and I\'ll tell you what you value." - Joe Biden',
      '"Every time you borrow money, you\'re robbing your future self." - Nathan W. Morris',
    ];

    // Use expense amount as seed for consistent quote per expense
    final seed = expense.amount.toInt() + expense.date.day;
    return quotes[seed % quotes.length];
  }
}
