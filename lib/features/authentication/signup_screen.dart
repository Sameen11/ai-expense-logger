import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// import '../../common/colors.dart';
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
  final _nameController = TextEditingController();
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
      _updatePasswordValidation,
    ); // Clean up listener
    _nameController.dispose();
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
      if (_passwordStrength <= 0.2) {
        // 0 or 1 req
        _passwordStrengthText = 'Weak';
        _passwordStrengthColor = Colors.red;
      } else if (_passwordStrength <= 0.6) {
        // 2 or 3 reqs
        _passwordStrengthText = 'Medium';
        _passwordStrengthColor = Colors.orange;
      } else {
        // 4 or 5 reqs
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
    await authProvider.signUp(
      'Demo User',
      'demo@expenselogger.com',
      'Demo123!',
    );

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
    // if (!_termsAccepted) {
    //   SnackBarUtils.showError(
    //       context, 'Please accept the terms and conditions to sign up.');
    //   return;
    // }

    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signUp(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      // Background color is handled by Theme
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
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset("assets/logo.png", height: 28),
                        const SizedBox(width: 6),
                        Text(
                          'ExpenseMind',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onBackground,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Create Account',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Start your journey with us',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),
                  CustomTextField(
                    controller: _nameController,
                    labelText: 'Full Name',
                    keyboardType: TextInputType.name,
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Please enter your name'
                        : null,
                  ),
                  const SizedBox(height: 16),
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
                  CustomTextField(
                    controller: _passwordController,
                    labelText: 'Password',
                    obscureText: _obscurePassword,
                    validator: (value) {
                      if (value == null || value.length < 8) {
                        return 'Password must be at least 8 characters';
                      }
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
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  _buildStrengthIndicator(theme),
                  _buildPasswordHintList(theme),
                  const SizedBox(height: 16),
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
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  authProvider.isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : AuthButton(onPressed: _submit, text: 'Sign Up'),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: TextStyle(color: theme.colorScheme.onBackground),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(color: theme.colorScheme.primary),
                        ),
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

  Widget _buildStrengthIndicator(ThemeData theme) {
    bool isTyping = _passwordController.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isTyping)
            LinearProgressIndicator(
              value: _passwordStrength,
              backgroundColor: theme.colorScheme.surfaceVariant,
              valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          if (isTyping) const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
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
                const Expanded(child: SizedBox()),
              TextButton.icon(
                icon: Icon(
                  _showPasswordHints
                      ? Icons.remove_circle_outline
                      : Icons.info_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                label: Text(
                  _showPasswordHints
                      ? 'Hide Requirements'
                      : 'Show Requirements',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
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

  Widget _buildPasswordHintList(ThemeData theme) {
    if (!_showPasswordHints) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, left: 4.0, bottom: 4.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHintRow('At least 8 characters', _hasLength, theme),
            const SizedBox(height: 4),
            _buildHintRow(
              'Contains an uppercase letter (A-Z)',
              _hasUppercase,
              theme,
            ),
            const SizedBox(height: 4),
            _buildHintRow(
              'Contains a lowercase letter (a-z)',
              _hasLowercase,
              theme,
            ),
            const SizedBox(height: 4),
            _buildHintRow('Contains a number (0-9)', _hasNumber, theme),
            const SizedBox(height: 4),
            _buildHintRow(
              'Contains a special character (!@#...)',
              _hasSpecial,
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHintRow(String text, bool isValid, ThemeData theme) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.error_outline,
          color: isValid ? Colors.green : theme.colorScheme.onSurfaceVariant,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : theme.colorScheme.onSurfaceVariant,
            fontSize: 13,
            decoration: isValid
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
      ],
    );
  }
}
