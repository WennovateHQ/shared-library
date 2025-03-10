import 'package:flutter/material.dart';
import '../models/onboarding_model.dart';
import '../themes/fresh_theme.dart';
import '../widgets/fresh_button.dart';
import '../widgets/onboarding_view.dart';

/// Base onboarding screen based on Pro-Grocery UI kit
/// Used as a base class for the specific app onboarding screens
abstract class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);
}

/// Abstract base state class for onboarding screens
/// Concrete implementations must provide onboardingItems and onFinishOnboarding
abstract class OnboardingScreenState<T extends OnboardingScreen>
    extends State<T> {
  int _currentPage = 0;
  late PageController _pageController;

  /// Abstract method to be implemented by subclasses to provide onboarding data
  List<OnboardingModel> get onboardingItems;

  /// Abstract method to be implemented by subclasses for navigation
  void onFinishOnboarding();

  /// Optional method to get custom colors, can be overridden
  Color get progressIndicatorColor => FreshTheme.primary;
  Color get progressIndicatorBackgroundColor => FreshTheme.cardColor;
  Color get nextButtonColor => FreshTheme.primary;
  Color get skipButtonColor => FreshTheme.textSecondary;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _goToNextPage() {
    if (_currentPage < onboardingItems.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      onFinishOnboarding();
    }
  }

  void _skipToEnd() {
    _pageController.animateToPage(
      onboardingItems.length - 1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == onboardingItems.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (!isLastPage)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(FreshTheme.padding),
                  child: TextButton(
                    onPressed: _skipToEnd,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: skipButtonColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: onboardingItems.length,
                itemBuilder: (context, index) {
                  return OnboardingView(
                    data: onboardingItems[index],
                  );
                },
              ),
            ),

            // Page indicator dots
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  onboardingItems.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? progressIndicatorColor
                          : progressIndicatorColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),

            // Next/Get Started button
            Padding(
              padding: const EdgeInsets.only(
                left: FreshTheme.padding,
                right: FreshTheme.padding,
                bottom: FreshTheme.padding * 2,
              ),
              child: FreshButton(
                onPressed: _goToNextPage,
                text: isLastPage ? 'Get Started' : 'Next',
                leadingIcon: isLastPage ? Icons.check : Icons.arrow_forward,
                size: FreshButtonSize.large,
                type: FreshButtonType.primary,
                isFullWidth: true,
                customColor: nextButtonColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
