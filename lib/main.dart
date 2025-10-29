import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'core/sizer.dart';
import 'features/authentication/provider/auth_provider.dart';
import 'features/authentication/service/auth_service.dart';
import 'features/splash/splash.dart';

// Note: We DO NOT import 'firebase_options.dart' because we are using the manual setup method.

void main() async {
  // 1. Ensure that Flutter's internal bindings are initialized before any plugins.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase. This will automatically use the
  //    google-services.json and GoogleService-Info.plist files you added.
  await Firebase.initializeApp();

  // 3. Run the application.
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider is used to provide multiple objects down the widget tree.
    // This makes our state and services available to any widget that needs them.
    return MultiProvider(
      providers: [
        // Provides the AuthService instance. This is a simple service class.
        Provider<AuthService>(
          create: (_) => AuthService(),
        ),

        // ChangeNotifierProvider creates and listens to our AuthProvider.
        // It depends on AuthService, so we read the instance we provided above.
        // It will automatically rebuild dependent widgets when the auth state changes.
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthService>()),
        ),
      ],
      child: Sizer(
          builder: (context, orientation, deviceType) {
          return MaterialApp(
            title: 'AI Expense Logger',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              primaryColor: Colors.blue,
              visualDensity: VisualDensity.adaptivePlatformDensity,
              fontFamily: 'Poppins',
              scaffoldBackgroundColor: Colors.white,
              // This creates a consistent, modern style for all text fields in the app.
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 20.0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                labelStyle: TextStyle(color: Colors.grey[600]),
              ),
            ),
            debugShowCheckedModeBanner: false,
            // The app's journey starts with the SplashScreen.
            home: const SplashScreen(),
          );
        }
      ),
    );
  }
}

