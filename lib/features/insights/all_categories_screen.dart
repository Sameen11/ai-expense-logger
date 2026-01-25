import 'package:ai_expense_logger/providers/category_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/category.dart';
import 'category_progress_item.dart';

class AllCategoriesScreen extends StatelessWidget {
  final List<MapEntry<String, double>> sortedCategories;
  final double totalSpent;

  const AllCategoriesScreen({
    super.key,
    required this.sortedCategories,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    // Expanded list of colors
    final colors = [
      Colors.blue[600]!,
      Colors.green[600]!,
      Colors.purple[600]!,
      Colors.orange[600]!,
      Colors.red[600]!,
      Colors.teal[600]!,
      Colors.pink[600]!,
      Colors.indigo[600]!,
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('All Categories'),
        backgroundColor: Colors.grey[100],
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: sortedCategories.length,
        itemBuilder: (context, index) {
          final entry = sortedCategories[index];
          final categoryName = entry.key;
          final amount = entry.value;
          final percentage = (totalSpent > 0) ? amount / totalSpent : 0.0;

          return CategoryProgressItem(
            icon: Icons.receipt_long,
            title: categoryName,
            amount: amount,
            percentage: percentage,
            color: colors[index % colors.length], // Cycle through all colors
          );
        },
      ),
    );
  }
}