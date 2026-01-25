import 'dart:ui';

import 'package:ai_expense_logger/common/colors.dart';
import 'package:ai_expense_logger/common/remote_values.dart';
import 'package:ai_expense_logger/providers/expense_provider.dart';
import 'package:ai_expense_logger/services/shared_pref_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/sizer.dart';
import 'features/authentication/provider/auth_provider.dart';
import 'features/authentication/service/auth_service.dart';
import 'features/splash/splash.dart';
import 'providers/category_provider.dart';
import 'providers/theme_provider.dart';
import 'core/theme/app_theme.dart';

// Note: We DO NOT import 'firebase_options.dart' because we are using the manual setup method.

void main() async {
  // 1. Ensure that Flutter's internal bindings are initialized before any plugins.
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase. This will automatically use the
  //    google-services.json and GoogleService-Info.plist files you added.
  await Firebase.initializeApp();

  RemoteConfig().init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // // Pass all uncaught "fatal" errors from Flutter framework to Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Catch asynchronous errors (outside Flutter)
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Catch and handle Flutter errors (especially camera plugin observer errors)
  FlutterError.onError = (FlutterErrorDetails details) {
    // Check if it's a camera-related error that we can safely ignore
    final errorString = details.exception.toString();
    if (errorString.contains('ObserverProxyApi') ||
        errorString.contains('ObserverImpl') ||
        errorString.contains('CameraX')) {
      // Log but don't crash - these are known camera plugin issues
      print('Camera plugin observer error (ignored): ${details.exception}');
      return;
    }

    // For other errors, use the default handler
    FlutterError.presentError(details);
  };

  await SharedPrefService.init(); // initialize once

  // 4. Run the application.
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
        Provider<AuthService>(create: (_) => AuthService()),

        // ChangeNotifierProvider creates and listens to our AuthProvider.
        // It depends on AuthService, so we read the instance we provided above.
        // It will automatically rebuild dependent widgets when the auth state changes.
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(context.read<AuthService>()),
        ),

        // This is the magic:
        // It depends on AuthProvider and rebuilds when AuthProvider changes
        ChangeNotifierProxyProvider<AuthProvider, ExpenseProvider>(
          create: (_) => ExpenseProvider(),
          update: (_, auth, previousExpenses) {
            // When auth.uid changes (login/logout),
            // it updates the ExpenseProvider with the new uid
            previousExpenses!.updateUid(auth.user?.uid);
            return previousExpenses;
          },
        ),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        // Add ThemeProvider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Sizer(
        builder: (context, orientation, deviceType) {
          // Listen to ThemeProvider
          final themeProvider = Provider.of<ThemeProvider>(context);
          return MaterialApp(
            title: 'AI Expense Logger',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            debugShowCheckedModeBanner: false,
            // The app's journey starts with the SplashScreen.
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}
