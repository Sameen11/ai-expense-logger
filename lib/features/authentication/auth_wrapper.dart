import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/home_view.dart';
import 'login_screen.dart';
import 'provider/auth_provider.dart';

// The AuthWrapper is a crucial widget that decides which screen to show
// based on the user's authentication status.
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Consumer widget listens to AuthProvider for changes.
    // When the auth state changes, this builder function will re-run.
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // If user is authenticated, show the HomeScreen.
        if (authProvider.isAuthenticated) {
          return const HomeScreen();
        }
        // Otherwise, show the LoginScreen.
        else {
          return const LoginScreen();
        }
      },
    );
  }
}
