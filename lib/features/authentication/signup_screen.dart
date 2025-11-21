import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../common/colors.dart';
import '../../widgets/auth_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/notification_bar.dart';
import '../home/dashboard.dart';
import 'login_screen.dart';
import 'provider/auth_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // --- State for new features ---
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _termsAccepted = false;

  // --- ADDED: State to toggle the hint list ---
  bool _showPasswordHints = false;

  // --- State for password validation ---
  // Booleans are for the validator
  bool _hasLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecial = false;

  // Strength values are for the UI progress bar
  double _passwordStrength = 0.0;
  String _passwordStrengthText = '';
  Color _passwordStrengthColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    // --- Listener to check password strength in real-time ---
    _passwordController.addListener(_updatePasswordValidation);
  }

  @override
  void dispose() {
    _passwordController.removeListener(
        _updatePasswordValidation); // Clean up listener
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- UPDATED: Function to update hints AND strength bar ---
  void _updatePasswordValidation() {
    final password = _passwordController.text;

    // --- Handle empty state ---
    if (password.isEmpty) {
      setState(() {
        _hasLength = false;
        _hasUppercase = false;
        _hasLowercase = false;
        _hasNumber = false;
        _hasSpecial = false;
        _passwordStrength = 0.0;
        _passwordStrengthText = '';
        _passwordStrengthColor = Colors.transparent;
      });
      return;
    }

    int requirementsMet = 0;
    setState(() {
      // --- Set booleans for the validator ---
      _hasLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

      // --- Calculate strength for the progress bar ---
      if (_hasLength) requirementsMet++;
      if (_hasUppercase) requirementsMet++;
      if (_hasLowercase) requirementsMet++;
      if (_hasNumber) requirementsMet++;
      if (_hasSpecial) requirementsMet++;

      // Map 0-5 requirements to 0.0-1.0 strength
      _passwordStrength = requirementsMet / 5.0;

      // Set text and color based on strength
      if (_passwordStrength <= 0.2) { // 0 or 1 req
        _passwordStrengthText = 'Weak';
        _passwordStrengthColor = Colors.red;
      } else if (_passwordStrength <= 0.6) { // 2 or 3 reqs
        _passwordStrengthText = 'Medium';
        _passwordStrengthColor = Colors.orange;
      } else { // 4 or 5 reqs
        _passwordStrengthText = 'Strong';
        _passwordStrengthColor = Colors.green;
      }
    });
  }

  void _createDemoUser() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    // Show loading
    setState(() {});
    
    // Create demo user
    await authProvider.signUp('demo@expenselogger.com', 'Demo123!');
    
    if (mounted && authProvider.errorMessage != null) {
      SnackBarUtils.showError(context, authProvider.errorMessage!);
      authProvider.clearError();
    } else if (mounted) {
      SnackBarUtils.showSuccess(context, 'Demo user created successfully!');
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _submit() async {
    // --- Check for terms and conditions first ---
    if (!_termsAccepted) {
      SnackBarUtils.showError(
          context, 'Please accept the terms and conditions to sign up.');
      return;
    }

    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signUp(
          _emailController.text.trim(), _passwordController.text.trim());

      if (mounted && authProvider.errorMessage != null) {
        // --- Use the helper for a styled error snackbar ---
        SnackBarUtils.showError(context, authProvider.errorMessage!);
        authProvider.clearError();
      } else if (mounted) {
        // --- ADDED: Navigate to Home Screen on success ---
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
              (route) => false, // Removes all routes behind it
        );

      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.person_add_alt_1_outlined,
                      size: 80, color: AppColors.primaryColor),
                  const SizedBox(height: 20),
                  const Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Start your journey with us',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 40),
                  CustomTextField(
                    controller: _emailController,
                    labelText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) =>
                    (value == null || !value.contains('@'))
                        ? 'Enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  // --- Password Field ---
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    obscureText: _obscurePassword,
                    // --- VALIDATOR STILL CHECKS ALL REQUIREMENTS ---
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
                      // Use the state booleans for validation
                      if (!_hasUppercase ||
                          !_hasLowercase ||
                          !_hasNumber ||
                          !_hasSpecial) {
                        return 'Password does not meet all requirements';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  // --- UPDATED: Shows strength bar AND hint toggle button ---
                  _buildStrengthIndicator(),

                  // --- ADDED: Conditionally shows the hint checklist ---
                  _buildPasswordHintList(),
                  const SizedBox(height: 16),
                  // --- Confirm Password Field ---
                  CustomTextField(
                    controller: _confirmPasswordController,
                    labelText: 'Confirm Password',
                    obscureText: _obscureConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // --- Terms and Conditions Checkbox ---
                  Row(
                    children: [
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: Checkbox(
                          value: _termsAccepted,
                          onChanged: (bool? value) {
                            setState(() {
                              _termsAccepted = value ?? false;
                            });
                          },
                          activeColor: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                                fontSize: 14, color: Colors.grey),
                            children: [
                              const TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: const TextStyle(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    // TODO: Add navigation to your Terms & Conditions page
                                    SnackBarUtils.showSuccess(context,
                                        'Navigate to Terms & Conditions');
                                  },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  authProvider.isLoading
                      ? const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primaryColor))
                      : AuthButton(onPressed: _submit, text: 'Sign Up'),
                  const SizedBox(height: 12),
                  // Create Demo User Button
                  OutlinedButton(
                    onPressed: authProvider.isLoading ? null : _createDemoUser,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text(
                      '🎯 Create Demo User',
                      style: TextStyle(
                        color: AppColors.primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account?"),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context)
                                .pushReplacement(MaterialPageRoute(
                                builder: (_) => const LoginScreen())),
                        child: const Text('Login',
                            style: TextStyle(color: AppColors.primaryColor)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- UPDATED: Helper widget for strength bar AND hint toggle ---
  Widget _buildStrengthIndicator() {
    bool isTyping = _passwordController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Only show strength bar if user is typing
          if (isTyping)
            LinearProgressIndicator(
              value: _passwordStrength,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          if (isTyping) const SizedBox(height: 8),

          // Row for "Weak/Strong" text and the hint button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Show strength text if typing
              if (isTyping)
                Text(
                  _passwordStrengthText,
                  style: TextStyle(
                    color: _passwordStrengthColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                )
              else
              // Placeholder to keep the button to the right
                const Expanded(child: SizedBox()),

              // The Hint Button
              TextButton.icon(
                icon: Icon(
                  _showPasswordHints ? Icons.remove_circle_outline : Icons
                      .info_outline,
                  size: 16,
                  color: Colors.grey[700],
                ),
                label: Text(
                  _showPasswordHints
                      ? 'Hide Requirements'
                      : 'Show Requirements',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: () {
                  setState(() {
                    _showPasswordHints = !_showPasswordHints;
                  });
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- ADDED: Helper widget for the requirements checklist ---
  Widget _buildPasswordHintList() {
    // Only show the list if the toggle is true
    if (!_showPasswordHints) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 4.0, bottom: 4.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHintRow('At least 8 characters', _hasLength),
            const SizedBox(height: 4),
            _buildHintRow('Contains an uppercase letter (A-Z)', _hasUppercase),
            const SizedBox(height: 4),
            _buildHintRow('Contains a lowercase letter (a-z)', _hasLowercase),
            const SizedBox(height: 4),
            _buildHintRow('Contains a number (0-9)', _hasNumber),
            const SizedBox(height: 4),
            _buildHintRow('Contains a special character (!@#...)', _hasSpecial),
          ],
        ),
      ),
    );
  }

  // --- ADDED: Helper widget for a single hint row (re-using from before) ---
  Widget _buildHintRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.error_outline,
          color: isValid ? Colors.green : Colors.grey,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : Colors.grey[700],
            fontSize: 13,
            decoration: isValid ? TextDecoration.lineThrough : TextDecoration
                .none,
          ),
        ),
      ],
    );
  }
}