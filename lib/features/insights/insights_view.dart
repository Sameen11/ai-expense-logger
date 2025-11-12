import 'package:ai_expense_logger/common/colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class InsightsView extends StatelessWidget {
  const InsightsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor, // Light background
      appBar: AppBar(
        backgroundColor: Colors.grey[100],
        surfaceTintColor: Colors.transparent, // No shadow
        elevation: 0,
        // Title with month selector
        title: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              // Using hardcoded date as per image
              'September 2025',
              style: TextStyle(
                color: Colors.grey[900],
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.grey[800]),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.download_outlined, color: Colors.grey[800]),
            onPressed: () {
              // Handle download action
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Total Spending Card
            _buildTotalSpendingCard(),
            const SizedBox(height: 24),

            // 2. Spending by Category Card
            _buildSpendingByCategoryCard(),
            const SizedBox(height: 24),

            // 3. Summary Card
            _buildSummaryCard(),
          ],
        ),
      ),
    );
  }

  // Card for the "Total Spending" section
  Widget _buildTotalSpendingCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Spending',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            // Using hardcoded value from image
            NumberFormat.currency(symbol: '\$').format(2847.32),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.arrow_upward, color: Colors.white, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '12%',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'vs last month',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Card for the "Spending by Category" section
  Widget _buildSpendingByCategoryCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Spending by Category',
            style: TextStyle(
              color: Colors.grey[900],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          // Pie Chart Placeholder
          Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                Icons.pie_chart_outline,
                color: Colors.grey[500],
                size: 60,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Category List
          _buildCategoryProgressItem(
            icon: Icons.coffee,
            title: 'Meals & Dining',
            amount: 847,
            percentage: 0.30,
            color: Colors.blue[600]!,
          ),
          _buildCategoryProgressItem(
            icon: Icons.directions_car,
            title: 'Travel',
            amount: 623,
            percentage: 0.22,
            color: Colors.green[600]!,
          ),
          _buildCategoryProgressItem(
            icon: Icons.laptop_chromebook,
            title: 'Software',
            amount: 412,
            percentage: 0.14,
            color: Colors.purple[600]!,
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: () {
                // Handle "View All Categories"
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All Categories',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Colors.blue[700],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // Reusable widget for each category progress bar item
  Widget _buildCategoryProgressItem({
    required IconData icon,
    required String title,
    required double amount,
    required double percentage,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.grey[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    // Using hardcoded value from image
                    '\$${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(percentage * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Rounded LinearProgressIndicator
          ClipRRect(
            borderRadius: BorderRadius.circular(5.0),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  // Card for the "Summary" section
  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        children: [
          _buildSummaryRow(
            title: 'Average Daily',
            value: NumberFormat.currency(symbol: '\$').format(94.91),
          ),
          const SizedBox(height: 20),
          _buildSummaryRow(
            title: 'Top Merchant',
            value: 'Starbucks (8x)',
          ),
        ],
      ),
    );
  }

  // Reusable row for the summary card
  Widget _buildSummaryRow({required String title, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 16,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

