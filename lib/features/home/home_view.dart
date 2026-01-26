import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/expense_provider.dart';
import '../../utils/currency_utils.dart';
import '../../widgets/expense_list_item.dart';
import '../../navigation/nav_manager.dart';
import '../expenses/expenses_view.dart';
import '../snap/snap_view.dart';
import '../insights/insights_view.dart';
import '../snap/add_expense.dart';
import '../../services/export_service.dart';
import '../../widgets/export_bottom_sheet.dart';
import '../../widgets/notification_bar.dart';
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.cardColor,
                  image: DecorationImage(
                    image:
                        (authProvider.userProfile?.photoURL != null &&
                            authProvider.userProfile!.photoURL!.isNotEmpty)
                        ? NetworkImage(authProvider.userProfile!.photoURL!)
                        : const AssetImage(
                                'assets/pngs/profile_placeholder.png',
                              )
                              as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                  border: Border.all(color: theme.dividerColor, width: 0.5),
                ),
                child:
                    (authProvider.userProfile?.photoURL == null ||
                        authProvider.userProfile!.photoURL!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.grey)
                    : null,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Builder(
                builder: (context) {
                  final hour = DateTime.now().hour;
                  String greeting;
                  if (hour < 12) {
                    greeting = 'GOOD MORNING 🌅';
                  } else if (hour < 17) {
                    greeting = 'GOOD AFTERNOON ☀️';
                  } else if (hour < 21) {
                    greeting = 'GOOD EVENING 🌆';
                  } else {
                    greeting = 'GOOD NIGHT 🌙';
                  }

                  return Text(
                    greeting,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
              Text(
                firstName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  // Syne font applied via theme
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onBackground,
                ),
              ),
            ],
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
                AppColors.premiumCardGradientStart,
                AppColors.premiumCardGradientEnd,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32), // More rounded
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBrand.withOpacity(0.4),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Month name
                  Text(
                    monthName.toUpperCase(),
                    style: GoogleFonts.lexend(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  // Expense count badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${provider.expenses.length} expenses',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Text(
                'Total Spent in $monthName',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                CurrencyUtils.formatAmount(amount, currency),
                style: GoogleFonts.syne(
                  // Explicitly use Syne for the big number
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BUDGET',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyUtils.formatAmount(budget, currency),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SAVED',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyUtils.formatAmount(saved, currency),
                        style: TextStyle(
                          color: saved >= 0
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  // Daily Average Indicator
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'DAILY AVG',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyUtils.formatAmount(dailyAverage, currency),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      // Trend Indicator
                      if (hasTrend) ...[
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                trendIcon,
                                color: isMore
                                    ? const Color(0xFFFF453A)
                                    : const Color(0xFF32D74B), // Red/Green
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                trendText,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildCircleAction(
            context,
            theme,
            icon: Icons.add_rounded,
            label: 'ADD',
            onTap: () => NavigationManager.push(
              context,
              const AddExpenseManuallyScreen(),
              type: TransitionType.platform,
            ),
          ),
          _buildCircleAction(
            context,
            theme,
            icon: Icons.upload_file_rounded, // Changed icon for Export
            label: 'EXPORT',
            onTap: () => _showExportOptions(context),
            color: const Color(0xFFD1E4FF), // Light Blue
            iconColor: AppColors.primaryBrand,
          ),
          _buildCircleAction(
            context,
            theme,
            icon: Icons.camera_alt_rounded,
            label: 'SNAP', // Renamed from BILL
            onTap: () => NavigationManager.push(context, const SnapView()),
            color: const Color(0xFFFFEFD1), // Light Orange
            iconColor: Colors.black,
          ),
        ],
      ),
    );
  }

  Widget _buildCircleAction(
    BuildContext context,
    ThemeData theme, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
    Color? iconColor,
  }) {
    final bgColor = color ?? theme.colorScheme.primary.withOpacity(0.1);
    final fgColor = iconColor ?? theme.colorScheme.primary;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
              boxShadow: color != null
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(icon, color: fgColor, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityHeader(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Last Transactions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              //Syne applied via header
            ),
          ),
          TextButton(
            onPressed: () =>
                NavigationManager.push(context, const ExpensesView()),
            child: Text(
              'View all',
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
        final expenses = provider.expenses; // Use all expenses for "recent"
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

        return ListView.builder(
          // Removed container for cleaner look
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: recentExpenses.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ExpenseListItem(
                expense: recentExpenses[index],
                hasContainer: true, // Use internal container
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showExportOptions(BuildContext context) async {
    final format = await showExportBottomSheet(context);
    if (format != null) {
      if (!mounted) return;
      final provider = Provider.of<ExpenseProvider>(context, listen: false);
      final expenses = provider.expensesForSelectedMonth;

      if (expenses.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No expenses to export for this month')),
        );
        return;
      }

      try {
        // Show loading indicator
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Generating export...')));

        final dateStr = DateFormat('MMM_yyyy').format(provider.selectedMonth);
        await ExportService().exportExpenses(
          expenses,
          'expenses_$dateStr',
          format,
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
