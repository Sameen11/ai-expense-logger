import 'package:ai_expense_logger/providers/expense_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'category_detail_card.dart';

class AllCategoriesScreen extends StatelessWidget {
  final String currency;

  const AllCategoriesScreen({super.key, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('All Categories'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<ExpenseProvider>(
        builder: (context, provider, child) {
          final stats = provider.getCategoryDetails(currency);

          if (stats.isEmpty) {
            return Center(
              child: Text(
                'No categories found',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              final stat = stats[index];
              return CategoryDetailCard(stat: stat, currency: currency);
            },
          );
        },
      ),
    );
  }
}
