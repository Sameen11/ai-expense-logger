import 'package:ai_expense_logger/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../navigation/nav_manager.dart';
import '../../services/shared_pref_service.dart';
import '../authentication/auth_wrapper.dart';
import 'model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      lottiePath: 'assets/lottie/ob_11.json',
      secondLottiePath: 'assets/lottie/ob_12.json',
      title: 'Snap, Track, Done',
      subtitle:
          'Instantly capture receipts. Our AI extracts every detail so you don\'t have to type a thing.',
    ),
    OnboardingPageModel(
      lottiePath: 'assets/lottie/ob_2.json',
      title: 'Auto-Categorization',
      subtitle:
          'Groceries, Travel, or Bills? We automatically sort your expenses into the right categories.',
    ),
    OnboardingPageModel(
      lottiePath: 'assets/lottie/ob_1.json', // Using unused asset for Insights
      title: 'Smart Insights',
      subtitle:
          'Visualize your spending habits with beautiful charts and get AI-powered financial tips.',
    ),
    OnboardingPageModel(
      lottiePath: 'assets/lottie/ob_3.json',
      title: 'Easy Export',
      subtitle:
          'Ready for tax season? Export your data to CSV, PDF, or Excel in just one tap.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutQuart,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    final prefs = SharedPrefService();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) {
      NavigationManager.pushReplacement(
        context,
        const AuthWrapper(),
        type: TransitionType.fade, // Smoother transition to app
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Force dark mode aesthetic or use Theme if already dark
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // We want a premium look, defaulting to dark background if possible or using scaffold
    final backgroundColor = AppColors.scaffoldBackground;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background Gradient (Subtle)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.cardColorDark.withOpacity(0.5),
                    backgroundColor,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip Button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16.0, top: 8.0),
                    child: TextButton(
                      onPressed: _finishOnboarding,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.darkTextSecondary,
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),

                // Page Content
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (int page) =>
                        setState(() => _currentPage = page),
                    itemBuilder: (context, index) =>
                        OnboardingPageContent(page: _pages[index]),
                  ),
                ),

                // Bottom Controls
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    children: [
                      // Page Indicator
                      PageIndicator(
                        currentPage: _currentPage,
                        pageCount: _pages.length,
                      ),
                      const SizedBox(height: 32),

                      // Animated Button
                      _AnimatedOnboardingButton(
                        isLastPage: _currentPage == _pages.length - 1,
                        onPressed: _goToNextPage,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPageContent extends StatefulWidget {
  final OnboardingPageModel page;
  const OnboardingPageContent({super.key, required this.page});

  @override
  State<OnboardingPageContent> createState() => _OnboardingPageContentState();
}

class _OnboardingPageContentState extends State<OnboardingPageContent>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  bool _showSecondLottie = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.page.secondLottiePath != null && !_showSecondLottie) {
          setState(() {
            _showSecondLottie = true;
          });
          _controller.reset();
          _controller.repeat();
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lottie Animation with Glow Effect
          Container(
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBrand.withOpacity(0.1),
                  blurRadius: 60,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Lottie.asset(
              _showSecondLottie
                  ? widget.page.secondLottiePath!
                  : widget.page.lottiePath,
              controller: _controller,
              onLoaded: (composition) {
                _controller.duration = composition.duration;
                if (!_showSecondLottie) {
                  _controller.forward();
                } else {
                  _controller.repeat();
                }
              },
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            widget.page.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            widget.page.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.darkTextSecondary,
              height: 1.5,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedOnboardingButton extends StatelessWidget {
  final bool isLastPage;
  final VoidCallback onPressed;

  const _AnimatedOnboardingButton({
    required this.isLastPage,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isLastPage ? double.infinity : 64,
      height: 64,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBrand,
          foregroundColor: Colors.white,
          padding: EdgeInsets.zero,
          shape: isLastPage
              ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
              : const CircleBorder(),
          elevation: 8,
          shadowColor: AppColors.primaryBrand.withOpacity(0.4),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: isLastPage
              ? const Text(
                  'Get Started',
                  key: ValueKey('text'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                )
              : const Icon(
                  Icons.arrow_forward_rounded,
                  key: ValueKey('icon'),
                  size: 28,
                ),
        ),
      ),
    );
  }
}

class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;

  const PageIndicator({
    super.key,
    required this.currentPage,
    required this.pageCount,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: isActive ? 24.0 : 8.0,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primaryBrand
                : AppColors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
