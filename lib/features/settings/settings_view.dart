import 'package:ai_expense_logger/common/colors.dart';
import 'package:ai_expense_logger/features/authentication/provider/auth_provider.dart';
import 'package:ai_expense_logger/features/upgrade/premium_view.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../navigation/nav_manager.dart';
import 'category/add_category.dart';
import 'profile_edit/profile_edit.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    // We use a Scaffold here to get the AppBar
    return Scaffold(
      backgroundColor: AppColors.bgColor, // Lighter grey background
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.bgColor, // Match scaffold background
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
            const _SettingsSectionHeader(title: 'ACCOUNT'),
            const _AccountPlanCard(),
            const _SettingsSectionHeader(title: 'PREFERENCES'),
            _SettingsGroup(
              children: [
                _SettingsTextValueOption(
                  title: 'Currency',
                  value: 'USD',
                  onTap: () {
                    // Handle currency tap
                  },
                ),
                _SettingsTextValueOption(
                  title: 'Default Payment Method',
                  value: 'Not Set',
                  onTap: () {
                    // Handle payment method tap
                  },
                ),
                _SettingsTextValueOption(
                  title: 'Manage Categories',
                  value: 'Set',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddCategoryScreen(),
                      ),
                    );
                  },
                ),
                const _SettingsToggleOption(title: 'Keep Data Local Only'),
              ],
            ),
            const _SettingsSectionHeader(title: 'EXPORT'),
            _SettingsGroup(
              children: [
                _SettingsOption(
                  title: 'Export All Data',
                  onTap: () {
                    // Handle export tap
                  },
                ),
              ],
            ),
            const _SettingsSectionHeader(title: 'PRIVACY'),
            _SettingsGroup(
              children: [
                _SettingsOption(
                  title: 'Privacy Policy',
                  onTap: () {
                    // Handle privacy policy tap
                  },
                ),
                _SettingsOption(
                  title: 'Terms of Service',
                  onTap: () {
                    // Handle terms tap
                  },
                ),
              ],
            ),
            const _SettingsSectionHeader(title: 'SUPPORT'),
            _SettingsGroup(
              children: [
                _SettingsOption(
                  title: 'Help & FAQ',
                  onTap: () {
                    // Handle help tap
                  },
                ),
                _SettingsOption(
                  title: 'Contact Us',
                  onTap: () {
                    // Handle contact tap
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SettingsGroup(
              children: [
                _SettingsOption(
                  title: 'Version 1.0.0',
                  showArrow: true, // Changed to true for consistency
                  onTap: () {
                    // Handle version tap
                  },
                ),
              ],
            ),
            // Sign Out Button Group
            const SizedBox(height: 20),
            _SettingsGroup(
              children: [
                _SignOutTile(),
              ],
            ),
            const SizedBox(height: 40), // Extra space at the bottom
          ],
        ),
      ),
    );
  }
}

// --- Reusable Private Widgets ---

// A new reusable widget for grouping settings
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        // ClipRRect to ensure children respect the rounded corners
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          // FIX: Add a Material widget. This provides the "canvas"
          // for the InkWell ripple effects from the ListTiles to draw on.
          // Without this, the ripple effect is often invisible.
          child: Material(
            color: Colors.white,
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(), // Disable scrolling
              shrinkWrap: true,
              itemCount: children.length,
              itemBuilder: (context, index) => children[index],
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey[200],
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
    return Padding(
      padding: const EdgeInsets.only(left: 18.0, right: 16.0, top: 24.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 13,
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
    // Use auth provider to get user info (if available)
    final authProvider = context.watch<AuthProvider>();
    // Use the provider's user object, which updates on notifyListeners()
    final user = authProvider.user;

    String email = user?.email ?? 'john@example.com';
    String name = user?.displayName ?? 'John Doe';
    String initials = (name.isNotEmpty && name != 'John Doe')
        ? name.trim().split(' ').map((l) => l[0]).take(2).join().toUpperCase()
        : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : '??');

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
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 17,
        ),
      ),
      subtitle: Text(
        email,
        style: TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        // --- THIS IS THE NAVIGATION LOGIC ---
        // We use the current name and email to pre-fill the form
        NavigationManager.push(
          context,
          ProfileEditView(
            currentName: name,
            currentEmail: email,
          ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 1,
        shadowColor: Colors.grey[200],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Free Plan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Use your NavigationManager for consistency
                    NavigationManager.push(
                      context,
                      PremiumScreen(),
                      type: TransitionType.slideFromBottom, // A modal slide is nice here
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Upgrade to Pro',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
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

  const _SettingsOption({
    required this.title,
    required this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: showArrow ? const Icon(Icons.chevron_right, color: Colors.grey) : null,
      onTap: onTap,
    );
  }
}

// A settings row with text and a text value
class _SettingsTextValueOption extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingsTextValueOption({
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}

// A settings row with text and a toggle switch
class _SettingsToggleOption extends StatefulWidget {
  final String title;
  const _SettingsToggleOption({required this.title});

  @override
  State<_SettingsToggleOption> createState() => _SettingsToggleOptionState();
}

class _SettingsToggleOptionState extends State<_SettingsToggleOption> {
  bool _isEnabled = false;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(widget.title),
      value: _isEnabled,
      onChanged: (bool value) {
        setState(() {
          _isEnabled = value;
          // You can also save this value to SharedPreferences or database
        });
      },
      activeColor: Colors.blue,
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
