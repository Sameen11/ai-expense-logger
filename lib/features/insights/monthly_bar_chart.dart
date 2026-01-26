import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/currency_utils.dart';

class MonthlyBarChart extends StatelessWidget {
  final Map<DateTime, double> monthlyData;
  final String currency;

  const MonthlyBarChart({
    super.key,
    required this.monthlyData,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    if (monthlyData.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final sortedKeys = monthlyData.keys.toList()..sort();

    // Find max value for Y-axis scaling
    double maxY = 0;
    for (var val in monthlyData.values) {
      if (val > maxY) maxY = val;
    }
    // Add buffer
    maxY = maxY * 1.2;
    if (maxY == 0) maxY = 100;

    return Container(
      height: 250,
      padding: const EdgeInsets.only(top: 24, bottom: 8, left: 8, right: 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.all(8),
              tooltipMargin: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  CurrencyUtils.formatAmount(rod.toY, currency),
                  TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sortedKeys.length) {
                    return const SizedBox.shrink();
                  }
                  final date = sortedKeys[index];
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('MMM').format(date),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const SizedBox.shrink();
                  // Compact currency format
                  return Text(
                    CurrencyUtils.formatCompactAmount(value, currency),
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(
                        0.5,
                      ),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
                interval: maxY / 4, // Show ~4 labels
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: theme.dividerColor.withOpacity(0.05),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: sortedKeys.asMap().entries.map((entry) {
            final index = entry.key;
            final date = entry.value;
            final amount = monthlyData[date] ?? 0.0;

            // Highlight current month
            final isCurrentMonth =
                date.year == DateTime.now().year &&
                date.month == DateTime.now().month;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: amount,
                  color: isCurrentMonth
                      ? theme.colorScheme.primary
                      : theme.colorScheme.primary.withOpacity(0.5),
                  // Gradient for a "Neon" look
                  gradient: LinearGradient(
                    colors: isCurrentMonth
                        ? [theme.colorScheme.primary, const Color(0xFF5856D6)]
                        : [
                            theme.colorScheme.primary.withOpacity(0.6),
                            const Color(0xFF5856D6).withOpacity(0.6),
                          ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(6),
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: theme.dividerColor.withOpacity(0.05),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
