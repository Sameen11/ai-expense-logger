import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// import '../../common/colors.dart';

import '../../providers/expense_provider.dart';
import '../../utils/currency_utils.dart';
import '../../widgets/expense_list_item.dart';
import '../../navigation/nav_manager.dart';
import '../expenses/expenses_view.dart';
import '../snap/snap_view.dart';
import '../insights/insights_view.dart';
import '../snap/add_expense.dart';
import '../authentication/provider/auth_provider.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Background color handled by theme
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 24),
              _buildSummaryCard(context, theme),
              const SizedBox(height: 24),
              _buildQuickActions(context, theme),
              const SizedBox(height: 24),
              _buildRecentActivityHeader(context, theme),
              const SizedBox(height: 12),
              _buildRecentActivityList(context, theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final authProvider = Provider.of<AuthProvider>(context);
    // Get the first name
    final displayName =
        authProvider.userProfile?.displayName ??
        authProvider.user?.displayName ??
        'User';
    final firstName = displayName.split(' ').first;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.waving_hand_rounded, // Changed icon to waving hand
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello,',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    firstName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onBackground,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.cardColor,
              image: const DecorationImage(
                image: AssetImage(
                  'assets/pngs/profile_placeholder.png',
                ), // Placeholder or fallback
                fit: BoxFit.cover,
              ),
              border: Border.all(color: theme.dividerColor, width: 0.5),
            ),
            child: const Icon(Icons.person, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, ThemeData theme) {
    return Consumer2<ExpenseProvider, AuthProvider>(
      builder: (context, provider, authProvider, _) {
        final totalSpentMap = provider.totalSpentByCurrency;
        // Default to USD or the first currency available
        String currency = 'USD';
        double amount = 0.0;
        if (totalSpentMap.isNotEmpty) {
          currency = totalSpentMap.keys.first;
          amount = totalSpentMap[currency]!;
        }

        final dailyAverage = provider.averageDailySpending;

        // Budget Data from AuthProvider
        final budget = authProvider.userProfile?.budget ?? 5000.0;
        final saved = budget - amount;

        // Comparison Data
        final percentageChange = provider.getPercentageChange(currency);
        final bool hasTrend = percentageChange != null;
        final bool isMore = hasTrend && percentageChange > 0;
        final IconData trendIcon = isMore
            ? Icons.trending_up_rounded
            : Icons.trending_down_rounded;
        final String trendText = hasTrend
            ? '${percentageChange.abs().toStringAsFixed(1)}% vs last month'
            : 'No prior data';

        final monthName = DateFormat('MMMM').format(provider.selectedMonth);

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.brightness == Brightness.dark
                    ? theme.colorScheme.primary.withOpacity(0.8)
                    : const Color(0xFF6B66FF),
                theme.brightness == Brightness.dark
                    ? theme.colorScheme.secondary.withOpacity(0.8)
                    : const Color(0xFF8F8CFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Spent in $monthName',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.more_horiz,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                CurrencyUtils.formatAmount(amount, currency),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (hasTrend)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        trendText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Avg',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyUtils.formatAmount(dailyAverage, currency),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Remaining',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          CurrencyUtils.formatAmount(saved, currency),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'QUICK ACTIONS',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  theme,
                  icon: Icons.camera_alt_rounded,
                  label: 'Snap Receipt',
                  color: Colors.blue,
                  onTap: () =>
                      NavigationManager.push(context, const SnapView()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  theme,
                  icon: Icons.add_rounded,
                  label: 'Add Expense',
                  color: const Color(0xFF6B66FF),
                  onTap: () => NavigationManager.push(
                    context,
                    const AddExpenseManuallyScreen(),
                    type: TransitionType.platform,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  theme,
                  icon: Icons.bar_chart_rounded,
                  label: 'View Insights',
                  color: Colors.purple,
                  onTap: () =>
                      NavigationManager.push(context, const InsightsView()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickActionCard(
                  context,
                  theme,
                  icon: Icons.download_rounded,
                  label: 'Export Data',
                  color: Colors.orange,
                  onTap: () {
                    // Placeholder for export functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Export feature coming soon!'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'RECENT ACTIVITY',
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.0,
            ),
          ),
          TextButton(
            onPressed: () =>
                NavigationManager.push(context, const ExpensesView()),
            child: Text(
              'See All',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(BuildContext context, ThemeData theme) {
    return Consumer<ExpenseProvider>(
      builder: (context, provider, _) {
        final expenses = provider.expensesForSelectedMonth;
        if (expenses.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No recent activity',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          );
        }

        // Show top 5 or fewer
        final recentExpenses = expenses.take(5).toList();

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                offset: const Offset(0, 4),
                blurRadius: 16,
              ),
            ],
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: recentExpenses.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: theme.dividerColor.withOpacity(0.1),
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              return ExpenseListItem(
                expense: recentExpenses[index],
                hasContainer: false,
              );
            },
          ),
        );
      },
    );
  }
}
