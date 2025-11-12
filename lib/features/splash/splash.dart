import 'dart:async';
import 'package:ai_expense_logger/features/language/language_view.dart';
import 'package:flutter/material.dart';
import '../../navigation/nav_manager.dart';
import '../../services/shared_pref_service.dart';
import '../authentication/auth_wrapper.dart';
import '../onboarding/onboarding_view.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final prefs = SharedPrefService();

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    Timer(const Duration(seconds: 4), () {
      final isLoggedIn = prefs.getBool('onboarding_complete');
      if (mounted && isLoggedIn == null || isLoggedIn == false) {
        NavigationManager.pushReplacement(
          context,
          LanguageView(), // The new page you want to show
          type: TransitionType.slideFromRight, // Specify the transition
        );
      }else{
        NavigationManager.pushReplacement(
          context,
          const AuthWrapper(), // The new page you want to show
          type: TransitionType.slideFromRight,
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade800],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 120, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'Expense Logger',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2.0),
                ),
                const SizedBox(height: 80),
                const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
              ],
            ),
          ),
        ),
      ),
    );
  }
}
