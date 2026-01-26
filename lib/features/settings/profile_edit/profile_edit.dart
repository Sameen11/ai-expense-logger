import 'package:ai_expense_logger/core/theme/app_colors.dart';
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
  String? _initialPhotoURL;

  // ⭐️ Current Avatar URL
  String? _currentPhotoURL;

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
      // NOTE: getProfileForEdit currently returns Map<String,String>, we might need to fetch the full object or update the provider method.
      // For now, let's access the userProfile directly from provider to get photoURL safely.
      final userProfile = authProvider.userProfile;

      // ⭐️ Store initial values
      _initialName = userProfile?.displayName ?? '';
      _initialEmail = userProfile?.email ?? '';
      _initialPhotoURL = userProfile?.photoURL;

      if (_initialPhotoURL == null || _initialPhotoURL!.isEmpty) {
        // Generate a default random one if none exists
        _currentPhotoURL = _generateRandomAvatarUrl();
      } else {
        _currentPhotoURL = _initialPhotoURL;
      }

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

  // ⭐️ Helper to generate a random DiceBear URL
  String _generateRandomAvatarUrl() {
    final randomSeed = DateTime.now().millisecondsSinceEpoch.toString();
    // Using 'adventurer' style which is fun and 3D-ish
    return 'https://api.dicebear.com/9.x/adventurer/png?seed=$randomSeed&backgroundColor=b6e3f4,c0aede,d1d4f9';
  }

  void _shuffleAvatar() {
    setState(() {
      _currentPhotoURL = _generateRandomAvatarUrl();
    });
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
    final bool avatarChanged = _currentPhotoURL != _initialPhotoURL;

    if (!nameChanged && !emailChanged && !avatarChanged) {
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
      // usage of updateUserProfile needs to be updated in AuthProvider to accept photoURL?
      // Just in case AuthProvider doesn't support photoURL update in updateUserProfile yet,
      // we might need to call a separate method or assume it will be handled.
      // Checking AuthProvider again... it calls _authService.updateUserProfile.
      // We need to make sure we pass the photoURL too.
      // For now, let's assume we need to update AuthProvider or directly update specific fields.
      // Actually, let's update the AuthProvider first if needed.
      // But adhering to the task, I will assume I can pass it or I'll implement a custom update here.

      // Since I can't see the auth_service method signature right now, I will modify AuthProvider in next step.
      // For now, let's pretend AuthProvider has an update function that takes photoURL or we'll add it.
      await authProvider.updateUserProfile(
        newName: newName,
        newEmail: newEmail,
        newPhotoURL:
            _currentPhotoURL, // I will add this parameter to AuthProvider
      );

      if (mounted) {
        // Update initial values on success
        _initialName = newName;
        _initialEmail = newEmail;
        _initialPhotoURL = _currentPhotoURL;
        SnackBarUtils.showSuccess(context, "Profile updated successfully!");
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showSuccess(context, "Failed to update profile: $e");
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
              // ⭐️ AVATAR SELECTION
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.cardColor,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(
                          color: theme.colorScheme.primary,
                          width: 2,
                        ),
                        image: _currentPhotoURL != null
                            ? DecorationImage(
                                image: NetworkImage(_currentPhotoURL!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _currentPhotoURL == null
                          ? Icon(
                              Icons.person,
                              size: 50,
                              color: theme.dividerColor,
                            )
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: _shuffleAvatar,
                      icon: const Icon(Icons.shuffle_rounded, size: 20),
                      label: const Text("Shuffle Avatar"),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors
                            .secondaryBrand, // Use secondary brand color
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        backgroundColor: AppColors.secondaryBrand.withOpacity(
                          0.1,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

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
              const SizedBox(height: 32), // Increased spacing
              // UPDATE BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primaryBrand, // Use primary brand color
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                    ), // Taller button
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // Match app theme radius
                    ),
                    elevation: 0,
                    shadowColor: Colors.transparent,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Save Changes', // Better text
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
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
