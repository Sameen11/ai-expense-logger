import 'package:ai_expense_logger/core/sizer.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../../features/onboarding/onboarding_view.dart';
import '../../navigation/nav_manager.dart';
import '../../widgets/glassmorphic_language_tile.dart';

class Language {
  final String code;
  final String name;
  final String flag;

  Language({required this.code, required this.name, required this.flag});
}

class LanguageView extends StatefulWidget {
  const LanguageView({super.key});

  @override
  State<LanguageView> createState() => _LanguageViewState();
}

class _LanguageViewState extends State<LanguageView> with TickerProviderStateMixin {
  final List<Language> _languages = [
    Language(code: 'en', name: 'English', flag: '🇺🇸'),
    Language(code: 'es', name: 'Español', flag: '🇪🇸'),
    Language(code: 'fr', name: 'Français', flag: '🇫🇷'),
    Language(code: 'de', name: 'Deutsch', flag: '🇩🇪'),
    Language(code: 'it', name: 'Italiano', flag: '🇮🇹'),
    Language(code: 'pt', name: 'Português', flag: '🇵🇹'),
    Language(code: 'ja', name: '日本語', flag: '🇯🇵'),
    Language(code: 'ko', name: '한국어', flag: '🇰🇷'),
    Language(code: 'zh', name: '中文', flag: '🇨🇳'),
    Language(code: 'ar', name: 'العربية', flag: '🇸🇦'),
    Language(code: 'hi', name: 'हिन्दी', flag: '🇮🇳'),
    Language(code: 'ru', name: 'Русский', flag: '🇷🇺'),
  ];

  String? _selectedLanguageCode;
  bool _isNavigating = false;

  // Animation controllers for the background gradient (for extra smoothness)
  late AnimationController _gradientController;
  late Animation<AlignmentGeometry> _topAlignmentAnimation;
  late Animation<AlignmentGeometry> _bottomAlignmentAnimation;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4), // Longer duration for subtle animation
    )..repeat(reverse: true);

    _topAlignmentAnimation = Tween<AlignmentGeometry>(
      begin: Alignment.topLeft,
      end: Alignment.topRight,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOutQuad,
    ));

    _bottomAlignmentAnimation = Tween<AlignmentGeometry>(
      begin: Alignment.bottomRight,
      end: Alignment.bottomLeft,
    ).animate(CurvedAnimation(
      parent: _gradientController,
      curve: Curves.easeInOutQuad,
    ));
  }

  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }

  void _onLanguageSelected(String code) {
    setState(() {
      _selectedLanguageCode = code;
    });
  }

  void _onContinue() {
    if (_selectedLanguageCode != null && !_isNavigating) {
      setState(() => _isNavigating = true);
      Timer(const Duration(milliseconds: 300), () {
        NavigationManager.pushReplacement(
          context,
          const OnboardingScreen(),
          type: TransitionType.platform,
        );
        if (mounted) {
          setState(() => _isNavigating = false);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isButtonEnabled = _selectedLanguageCode != null;

    return Scaffold(
      backgroundColor: Colors.transparent, // Transparent to show gradient
      body: AnimatedBuilder(
        animation: _gradientController,
        builder: (context, child) {
          return Container(
            // Dynamic gradient background
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.shade200.withOpacity(0.8),
                  Colors.purple.shade200.withOpacity(0.8),
                  Colors.pink.shade200.withOpacity(0.8),
                ],
                begin: _topAlignmentAnimation.value,
                end: _bottomAlignmentAnimation.value,
              ),
            ),
            child: child,
          );
        },
        child: SafeArea(
          child: Column(
            children: [
              // --- HERO: Modern Header with richer typography ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                child: Hero(
                  tag: 'language_header', // For potential smooth transitions
                  child: Material(
                    color: Colors.transparent, // Important for Hero
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Your Language',
                          style: TextStyle( // Using GoogleFonts for modern look
                            fontSize: 38.fSize,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Select the language you want to use in the app.',
                          style: TextStyle(
                            fontSize: 22.fSize,
                            color: Colors.white.withOpacity(0.8),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // --- Grid-based language list with Glassmorphism ---
              Expanded(
                child: GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 10.h),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Changed to 2 columns for larger tiles
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 1.1, // Adjusted ratio for a nicer card shape
                  ),
                  itemCount: _languages.length,
                  itemBuilder: (context, index) {
                    final language = _languages[index];
                    final isSelected = language.code == _selectedLanguageCode;

                    return GlassmorphicLanguageTile(
                      language: language,
                      isSelected: isSelected,
                      onTap: () => _onLanguageSelected(language.code),
                    );
                  },
                ),
              ),

              // Continue Button
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (isButtonEnabled && !_isNavigating) ? _onContinue : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: isButtonEnabled
                          ? Colors.white.withOpacity(0.9) // White button for contrast
                          : Colors.white.withOpacity(0.4),
                      foregroundColor: isButtonEnabled ? theme.primaryColor : Colors.white.withOpacity(0.7),
                      shape: const StadiumBorder(),
                      elevation: isButtonEnabled ? 10 : 0,
                      shadowColor: Colors.black.withOpacity(0.2), // Stronger shadow for pop
                    ),
                    child: _isNavigating
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.blue, // Primary color for loading
                        strokeWidth: 3,
                      ),
                    )
                        : Text(
                      'Continue',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

