import 'package:ai_expense_logger/common/colors.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../widgets/auth_button.dart';
import '../../widgets/custom_text_field.dart';

// --- ADDED: Import for user-friendly snackbar ---
import '../../widgets/notification_bar.dart';
import '../home/dashboard.dart';
import 'forgot_password_screen.dart';
import 'provider/auth_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // --- ADDED: State for password visibility and terms ---
  bool _obscurePassword = true;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    // Set default demo credentials
    _emailController.text = 'demo@expenselogger.com';
    _passwordController.text = 'demo123';
    _termsAccepted = true; // Auto-accept terms for demo
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemoCredentials() {
    setState(() {
      _emailController.text = 'demo@expenselogger.com';
      _passwordController.text = 'demo123';
      _termsAccepted = true;
    });
  }

  Future<void> _submit() async {
    // --- ADDED: Check for terms and conditions first ---
    if (!_termsAccepted) {
      SnackBarUtils.showError(
          context, 'Please accept the terms and conditions to log in.');
      return;
    }

    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signIn(
          _emailController.text.trim(), _passwordController.text.trim());

      if (mounted && authProvider.errorMessage != null) {
        // --- UPDATED: Use the helper for a styled error snackbar ---
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
                  const Icon(Icons.shopping_bag_outlined,
                      size: 80, color: AppColors.primaryColor),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome Back!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Sign in to continue',
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
                  // --- UPDATED: Password Field ---
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    obscureText: _obscurePassword,
                    // Use state variable
                    validator: (value) =>
                    (value == null || value.length < 6)
                        ? 'Password must be at least 6 characters'
                        : null,
                    // --- ADDED: Suffix icon to toggle visibility ---
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
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (
                                      _) => const ForgotPasswordScreen())),
                      child: const Text('Forgot Password?',
                          style: TextStyle(color: AppColors.primaryColor)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // --- ADDED: Terms and Conditions Checkbox ---
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
                                // --- ADDED: Make "Terms" tappable ---
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
                      : AuthButton(onPressed: _submit, text: 'Login'),
                  const SizedBox(height: 12),
                  // Demo Login Button
                  OutlinedButton(
                    onPressed: _fillDemoCredentials,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: AppColors.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: const Text(
                      '🚀 Use Demo Credentials',
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
                      const Text("Don't have an account?"),
                      TextButton(
                        onPressed: () =>
                            Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const SignUpScreen())),
                        child: const Text('Sign Up',
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
}