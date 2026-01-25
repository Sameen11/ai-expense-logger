// import 'package:ai_expense_logger/common/colors.dart';
import 'package:ai_expense_logger/features/authentication/provider/auth_provider.dart';
import 'package:ai_expense_logger/features/upgrade/premium_view.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../navigation/nav_manager.dart';
import '../../providers/expense_provider.dart';
import '../../services/export_service.dart';
import '../../widgets/export_bottom_sheet.dart';
import '../../widgets/notification_bar.dart';
import 'profile_edit/profile_edit.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  Future<void> _showExportOptions() async {
    // Get the provider once
    final expenseProvider = context.read<ExpenseProvider>();

    // Show the bottom sheet and wait for a result
    final ExportFormat? format = await showExportBottomSheet(context);

    // Do nothing if the user dismissed the sheet
    if (format == null || !mounted) return;

    try {
      final expenses = expenseProvider.expensesForSelectedMonth;
      if (expenses.isEmpty) {
        SnackBarUtils.showSuccess(context, 'No data to export for this month.');
        return;
      }

      final monthName = DateFormat(
        'yyyy-MM',
      ).format(expenseProvider.selectedMonth);

      // Show progress message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Exporting ${expenses.length} expenses to ${format.name.toUpperCase()}...',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }

      // Call the single export service
      await ExportService().exportExpenses(expenses, monthName, format);

      // Show success (optional)
      if (mounted) {
        SnackBarUtils.showSuccess(
          context,
          'Successfully exported to ${format.name.toUpperCase()}!',
        );
      }
    } catch (e) {
      // Show error
      if (mounted) {
        SnackBarUtils.showError(
          context,
          'Error exporting file: ${e.toString()}',
        );
      }
    }
  }

  Future<void> _openEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'expensemind@gmail.com',
      query: 'subject=Contact Us&body=Hello,',
    );

    if (!await launchUrl(emailUri)) {
      throw 'Could not open email app';
    }
  }

  Future<void> _openUrl() async {
    final Uri url = Uri.parse(
      'https://expense-mind-website.vercel.app/privacy',
    );

    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication, // opens in browser
    )) {
      throw 'Could not open the URL';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // We use a Scaffold here to get the AppBar
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Lighter grey background
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor:
            theme.scaffoldBackgroundColor, // Match scaffold background
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false, // Removes back button
      ),
      // SingleChildScrollView allows the content to scroll
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: _UserProfileSection(),
            ),
            // const _SettingsSectionHeader(title: 'ACCOUNT'),
            // const _AccountPlanCard(),
            const _SettingsSectionHeader(title: 'PREFERENCES'),
            _SettingsGroup(
              children: [
                _SettingsOption(
                  icon: const _SettingsIcon(
                    icon: Icons.account_balance_wallet_rounded,
                    color: Colors.green,
                  ),
                  title: 'Monthly Budget',
                  onTap: () => _showUpdateBudgetDialog(context),
                ),
                // _SettingsTextValueOption(
                //   // --- NEW ICON ---
                //   icon: const _SettingsIcon(
                //     icon: Icons.attach_money_rounded,
                //     color: Colors.green,
                //   ),
                //   title: 'Currency',
                //   value: 'USD',
                //   onTap: () {
                //     // Handle currency tap
                //   },
                // ),
                // const _SettingsToggleOption(
                //   icon: _SettingsIcon(
                //     icon: Icons.data_usage_rounded,
                //     color: Colors.blue,
                //   ),
                //   title: 'Keep Data Local Only',
                // ),
              ],
            ),
            const _SettingsSectionHeader(title: 'EXPORT'),
            _SettingsGroup(
              children: [
                _SettingsOption(
                  // --- NEW ICON ---
                  icon: const _SettingsIcon(
                    icon: Icons.upload_file_rounded,
                    color: Color(0xFF007AFF), // iOS Blue
                  ),
                  title: 'Export All Data',
                  onTap: _showExportOptions,
                ),
              ],
            ),
            const _SettingsSectionHeader(title: 'PRIVACY'),
            _SettingsGroup(
              children: [
                _SettingsOption(
                  // --- NEW ICON ---
                  icon: const _SettingsIcon(
                    icon: Icons.shield_rounded,
                    color: Colors.blueGrey,
                  ),
                  title: 'Privacy Policy',
                  onTap: () {
                    _openUrl();
                  },
                ),
                // _SettingsOption(
                //   // --- NEW ICON ---
                //   icon: const _SettingsIcon(
                //     icon: Icons.article_rounded,
                //     color: Colors.grey,
                //   ),
                //   title: 'Terms of Service',
                //   onTap: () {
                //     // Handle terms tap
                //   },
                // ),
              ],
            ),
            const _SettingsSectionHeader(title: 'SUPPORT'),
            _SettingsGroup(
              children: [
                // _SettingsOption(
                //   // --- NEW ICON ---
                //   icon: const _SettingsIcon(
                //     icon: Icons.help_outline_rounded,
                //     color: Colors.purple,
                //   ),
                //   title: 'Help & FAQ',
                //   onTap: () {
                //     // Handle help tap
                //   },
                // ),
                _SettingsOption(
                  // --- NEW ICON ---
                  icon: const _SettingsIcon(
                    icon: Icons.email_rounded,
                    color: Colors.redAccent,
                  ),
                  title: 'Contact Us',
                  onTap: () {
                    // Handle contact tap
                    _openEmail();
                  },
                ),
              ],
            ),
            // Sign Out Button Group
            const SizedBox(height: 20),
            _SettingsGroup(children: const [_SignOutTile()]),
            const SizedBox(height: 40), // Extra space at the bottom
          ],
        ),
      ),
    );
  }

  void _showUpdateBudgetDialog(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.read<AuthProvider>();
    final currentBudget = authProvider.userProfile?.budget ?? 5000.0;
    final controller = TextEditingController(
      text: currentBudget.toStringAsFixed(0),
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Update Budget',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set your monthly spending goal to track your savings.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: theme.scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: '0',
                          prefixText: '\$ ',
                          prefixStyle: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.5),
                          ),
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final newBudget = double.tryParse(
                                controller.text,
                              );
                              if (newBudget != null && newBudget > 0) {
                                try {
                                  await authProvider.updateUserBudget(
                                    newBudget,
                                  );
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    SnackBarUtils.showSuccess(
                                      context,
                                      'Budget updated successfully!',
                                    );
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    SnackBarUtils.showError(
                                      context,
                                      e.toString(),
                                    );
                                  }
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              shadowColor: theme.colorScheme.primary
                                  .withOpacity(0.4),
                            ),
                            child: const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// --- Reusable Private Widgets ---

// ------------------------------------
// --- ⭐️ NEW WIDGET ⭐️ ---
// This creates the colored, rounded-square icon background
// ------------------------------------
class _SettingsIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SettingsIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30, // iOS icon container size
      height: 30,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6), // iOS radius
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }
}

// A new reusable widget for grouping settings
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16), // Increased radius
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // ClipRRect to ensure children respect the rounded corners
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: theme.cardColor,
            child: ListView.separated(
              physics:
                  const NeverScrollableScrollPhysics(), // Disable scrolling
              shrinkWrap: true,
              itemCount: children.length,
              itemBuilder: (context, index) => children[index],
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: theme.dividerColor.withOpacity(0.1),
                indent: 16, // Indent the divider
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Header for sections (e.g., "ACCOUNT", "PREFERENCES")
class _SettingsSectionHeader extends StatelessWidget {
  final String title;
  const _SettingsSectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(
        left: 18.0,
        right: 16.0,
        top: 24.0,
        bottom: 8.0,
      ),
      child: Text(
        title,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// User profile tile at the top
class _UserProfileSection extends StatelessWidget {
  const _UserProfileSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Use auth provider to get user info (if available)
    final authProvider = context.watch<AuthProvider>();
    // Use the provider's user object, which updates on notifyListeners()
    final user = authProvider.user;
    debugPrint("User: ${user}");

    String email = user?.email ?? 'john@example.com';
    String name = user?.displayName ?? 'John Doe';
    String initials = (name.isNotEmpty && name != 'John Doe')
        ? name.trim().split(' ').map((l) => l[0]).take(2).join().toUpperCase()
        : (user?.email?.isNotEmpty == true
              ? user!.email![0].toUpperCase()
              : '??');

    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: Colors.blue,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      subtitle: Text(
        email,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontSize: 14,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: theme.colorScheme.onSurfaceVariant,
      ),
      onTap: () {
        debugPrint("Profile tapped: ${user?.phoneNumber}");
        NavigationManager.push(
          context,
          ProfileEditView(),
          type: TransitionType.slideFromRight, // Use your modern transition
        );
      },
    );
  }
}

// The "Free Plan" card
class _AccountPlanCard extends StatelessWidget {
  const _AccountPlanCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: theme.cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Free Plan',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      '12/20',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '12 receipts used this month',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    NavigationManager.push(
                      context,
                      PremiumScreen(),
                      type: TransitionType.slideFromBottom,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Upgrade to Pro',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// A standard settings row with text and an arrow
class _SettingsOption extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final bool showArrow;
  final Widget? icon; // --- ADDED ICON ---

  const _SettingsOption({
    required this.title,
    required this.onTap,
    this.showArrow = true,
    this.icon, // --- ADDED ICON ---
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: icon, // --- USED ICON ---
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: showArrow
          ? Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant)
          : null,
      onTap: onTap,
    );
  }
}

// A settings row with text and a text value
class _SettingsTextValueOption extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;
  final Widget? icon; // --- ADDED ICON ---

  const _SettingsTextValueOption({
    required this.title,
    required this.value,
    required this.onTap,
    this.icon, // --- ADDED ICON ---
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: icon, // --- USED ICON ---
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
      onTap: onTap,
    );
  }
}

// A settings row with text and a toggle switch
class _SettingsToggleOption extends StatefulWidget {
  final String title;
  final Widget? icon; // --- ADDED ICON ---
  const _SettingsToggleOption({
    required this.title,
    this.icon, // --- ADDED ICON ---
    super.key,
  });

  @override
  State<_SettingsToggleOption> createState() => _SettingsToggleOptionState();
}

class _SettingsToggleOptionState extends State<_SettingsToggleOption> {
  bool _isEnabled = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      // SwitchListTile uses 'secondary' for the leading icon
      secondary: widget.icon, // --- USED ICON ---
      title: Text(
        widget.title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: theme.colorScheme.onSurface,
        ),
      ),
      value: _isEnabled,
      onChanged: (bool value) {
        setState(() {
          _isEnabled = value;
          // You can also save this value to SharedPreferences or database
        });
      },
      activeColor: theme.colorScheme.primary,
    );
  }
}

// Special list tile for the sign out button
class _SignOutTile extends StatelessWidget {
  const _SignOutTile();

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Center(
        child: Text(
          'Sign Out',
          style: TextStyle(
            color: Colors.red,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      onTap: () {
        // Use Provider to call the signOut method
        context.read<AuthProvider>().signOut();
      },
    );
  }
}
