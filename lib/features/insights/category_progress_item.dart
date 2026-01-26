import 'package:flutter/material.dart';
import '../../utils/currency_utils.dart';

class CategoryProgressItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final double amount;
  final double percentage;
  final Color color;
  final String currency; // Add currency

  const CategoryProgressItem({
    super.key,
    required this.icon,
    required this.title,
    required this.amount,
    required this.percentage,
    required this.color,
    this.currency = 'USD', // Default
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          // 1. Circular Progress with Percentage
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: percentage,
                    strokeWidth: 4,
                    backgroundColor: Theme.of(
                      context,
                    ).dividerColor.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    strokeCap: StrokeCap.round, // Modern rounded tips
                  ),
                ),
                Text(
                  '${(percentage * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // 2. Category Name
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),

          // 3. Amount
          Text(
            CurrencyUtils.formatAmount(amount, currency),
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
