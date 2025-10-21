import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../authentication/auth_wrapper.dart'; // Import the AuthWrapper

// Data Model (no changes)
class OnboardingPageModel {
  final String imagePath;
  final String title;
  final String subtitle;
  OnboardingPageModel({required this.imagePath, required this.title, required this.subtitle});
}

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
      imagePath: 'assets/images/undraw_product_tour.svg',
      title: 'Discover Amazing Products',
      subtitle: 'Browse through thousands of products from the best brands.',
    ),
    OnboardingPageModel(
      imagePath: 'assets/images/undraw_shopping_app.svg',
      title: 'Add to Cart with Ease',
      subtitle: 'Select your favorite items and add them to your cart effortlessly.',
    ),
    OnboardingPageModel(
      imagePath: 'assets/images/undraw_order_confirmed.svg',
      title: 'Fast & Secure Checkout',
      subtitle: 'Complete your purchase with our streamlined and secure payment process.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finishOnboarding();
    }
  }

  // ** UPDATED **
  // When onboarding is finished or skipped, navigate to the AuthWrapper.
  // The AuthWrapper will then decide whether to show the Login screen or Home screen.
  void _finishOnboarding() {
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const AuthWrapper()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: const Text('Skip', style: TextStyle(color: Colors.grey, fontSize: 16)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (int page) => setState(() => _currentPage = page),
                itemBuilder: (context, index) => OnboardingPageContent(page: _pages[index]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  PageIndicator(currentPage: _currentPage, pageCount: _pages.length),
                  NextButton(onPressed: _goToNextPage, isLastPage: _currentPage == _pages.length - 1),
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

// --- INDIVIDUAL ONBOARDING PAGE UI ---
class OnboardingPageContent extends StatelessWidget {
  final OnboardingPageModel page;
  const OnboardingPageContent({super.key, required this.page});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SvgPicture.asset(page.imagePath, height: 250),
          const SizedBox(height: 50),
          Text(page.title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(page.subtitle, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5)),
        ],
      ),
    );
  }
}

// --- NEXT BUTTON WIDGET ---
class NextButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLastPage;
  const NextButton({super.key, required this.onPressed, required this.isLastPage});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: const CircleBorder(),
        padding: const EdgeInsets.all(20),
        backgroundColor: Colors.blue,
        elevation: 5,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: isLastPage
            ? const Icon(Icons.check, color: Colors.white, key: ValueKey('check_icon'))
            : const Icon(Icons.arrow_forward, color: Colors.white, key: ValueKey('arrow_icon')),
      ),
    );
  }
}

// --- PAGE INDICATOR WIDGET ---
class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int pageCount;
  const PageIndicator({super.key, required this.currentPage, required this.pageCount});
  Widget _buildDot(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 8.0,
      width: isActive ? 24.0 : 8.0,
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.grey.shade300,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(pageCount, (index) => _buildDot(index == currentPage)),
    );
  }
}
