// import 'package:ai_expense_logger/common/colors.dart';
import 'package:ai_expense_logger/features/authentication/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../navigation/nav_manager.dart';
import '../../../widgets/custom_text_field.dart';
import '../../../widgets/notification_bar.dart';
import '../../authentication/forgot_password_screen.dart';

class ProfileEditView extends StatefulWidget {
  const ProfileEditView({super.key});

  @override
  State<ProfileEditView> createState() => _ProfileEditViewState();
}

class _ProfileEditViewState extends State<ProfileEditView> {
  // Controllers
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  // ⭐️ State to hold initial values for comparison
  String _initialName = '';
  String _initialEmail = '';

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isDataLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final authProvider = context.read<AuthProvider>();

    try {
      // This now returns the country code as well
      final data = await authProvider.getProfileForEdit();

      // ⭐️ Store initial values
      _initialName = data['name'] ?? '';
      _initialEmail = data['email'] ?? '';

      // ⭐️ Set controllers and state
      _nameController = TextEditingController(text: _initialName);
      _emailController = TextEditingController(text: _initialEmail);

      if (mounted) {
        setState(() => _isDataLoading = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: ${e.toString()}')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  void dispose() {
    if (!_isDataLoading) {
      _nameController.dispose();
      _emailController.dispose();
    }
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final newName = _nameController.text.trim();
    final newEmail = _emailController.text.trim();

    // Check for changes
    final bool nameChanged = newName != _initialName;
    final bool emailChanged = newEmail != _initialEmail;

    if (!nameChanged && !emailChanged) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No changes to save.'),
          backgroundColor: Colors.blue,
        ),
      );
      Navigator.of(context).pop();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();

      // ⭐️ Pass the ISO code to the provider
      await authProvider.updateUserProfile(
        newName: newName,
        newEmail: newEmail,
      );

      if (mounted) {
        // Update initial values on success
        _initialName = newName;
        _initialEmail = newEmail;
        SnackBarUtils.showSuccess(context, "Profile updated successfully!");
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSuccess(context, "Failed to update profile");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ⭐️ Show a loader while data is being fetched
    final theme = Theme.of(context);
    if (_isDataLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: theme.scaffoldBackgroundColor),
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        shadowColor: Colors.transparent,
        title: Text(
          'Edit Profile',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
          ),
        ),
        elevation: 0,
        iconTheme: theme.iconTheme,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // NAME
              CustomTextField(
                controller: _nameController,
                labelText: 'Full Name',
                keyboardType: TextInputType.name,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // EMAIL
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                keyboardType: TextInputType.emailAddress,
                validator: (value) => (value == null || !value.contains('@'))
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 20),

              // UPDATE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 5,
                    shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Update Profile',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // ⭐️ RESET PASSWORD BUTTON
              TextButton(
                onPressed: () {
                  NavigationManager.push(
                    context,
                    const ForgotPasswordScreen(),
                    type: TransitionType.slideFromRight,
                  );
                },
                child: Text(
                  "Reset Password",
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
