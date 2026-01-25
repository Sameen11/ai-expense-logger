// import 'package:ai_expense_logger/common/colors.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // 1. Added Lottie Import

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

  // 2. Updated paths to .json files
  final List<OnboardingPageModel> _pages = [
    OnboardingPageModel(
      lottiePath: 'assets/lottie/ob_11.json',
      secondLottiePath:
          'assets/lottie/ob_12.json', // Your second file for page 1
      title: 'Snap → Categorize → Done',
      subtitle: 'Track expenses in seconds with AI-powered receipt scanning.',
    ),
    OnboardingPageModel(
      lottiePath: 'assets/lottie/ob_2.json',
      title: 'AI Auto-Categorizes Everything',
      subtitle:
          'No manual sorting. Our AI recognizes merchants and categories automatically.',
    ),
    OnboardingPageModel(
      lottiePath: 'assets/lottie/ob_3.json',
      title: 'Export for Taxes, No Hassle',
      subtitle:
          'One-tap CSV exports ready for your accountant or tax software.',
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
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    final prefs = SharedPrefService();
    await prefs.setBool('onboarding_complete', true);
    NavigationManager.pushReplacement(
      context,
      const AuthWrapper(),
      type: TransitionType.slideFromRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: Text(
                  'Skip',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
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
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 20.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PageIndicator(
                    currentPage: _currentPage,
                    pageCount: _pages.length,
                  ),
                  NextButton(
                    onPressed: _goToNextPage,
                    isLastPage: _currentPage == _pages.length - 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Below widgets are unchanged but included for completeness.

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

    // Listen for when the animation finishes
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (widget.page.secondLottiePath != null && !_showSecondLottie) {
          setState(() {
            _showSecondLottie = true;
          });
          // Reset and play the second one (looping)
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 250,
            child: Lottie.asset(
              // Toggle path based on state
              _showSecondLottie
                  ? widget.page.secondLottiePath!
                  : widget.page.lottiePath,
              controller: _controller,
              onLoaded: (composition) {
                _controller.duration = composition.duration;
                // Start playing
                if (!_showSecondLottie) {
                  _controller.forward(); // Play once for the first lottie
                } else {
                  _controller.repeat(); // Loop the second lottie
                }
              },
            ),
          ),
          const SizedBox(height: 50),
          Text(
            widget.page.title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.page.subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 16,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// --- NEXT BUTTON WIDGET ---
class NextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLastPage;
  const NextButton({
    super.key,
    required this.onPressed,
    required this.isLastPage,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(20),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 5,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) =>
            ScaleTransition(scale: animation, child: child),
        child: isLastPage
            ? Icon(
                Icons.check,
                size: 30,
                color: theme.colorScheme.onPrimary,
                key: const ValueKey('check_icon'),
              )
            : Icon(
                Icons.arrow_forward,
                size: 30,
                color: theme.colorScheme.onPrimary,
                key: const ValueKey('arrow_icon'),
              ),
      ),
    );
  }
}

// --- PAGE INDICATOR WIDGET ---
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
      children: List.generate(pageCount, (index) {
        final isActive = index == currentPage;
        final theme = Theme.of(context);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 8.0,
          width: isActive ? 24.0 : 8.0,
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primary
                : theme.disabledColor.withOpacity(0.3),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
          ),
        );
      }),
    );
  }
}
