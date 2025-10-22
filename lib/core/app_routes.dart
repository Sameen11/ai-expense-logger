
import 'package:ai_expense_logger/features/language/language_view.dart';
import 'package:ai_expense_logger/features/onboarding/onboarding_view.dart';
import 'package:go_router/go_router.dart';

import '../features/splash/splash.dart';

class AppRouter {

  static const splash = '/splash';
  static const language = '/language';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const dashboard = '/dashboard';
  static const settings = '/settings';
  static const premium = '/premium';
  static const compression = '/compression';
  static const lock = '/lock';
  static const private = '/private';
  static const privatePreview = '/private-preview';
  static const smartCleaner = '/smart-cleaner';
  static const test = '/test';
  static const test1 = '/test1';
  static const duplicateImage = '/duplicate-image';
  static const duplicateVideo = '/duplicate-video';
  static const duplicateContacts = '/duplicate-contacts';
  static const duplicateAudio = '/duplicate-audio';
  static const videoResult = '/video-result';
  static const success = '/success';

  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: splash, builder: (context, state) => const SplashScreen()),
      GoRoute(
        path: language,
        builder: (context, state) => const LanguageView(),
      ),
      GoRoute(
        path: onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
}