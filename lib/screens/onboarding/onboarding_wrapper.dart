import 'package:flutter/cupertino.dart';
import '../../theme/bunk_theme.dart';
import 'pages/intro_page.dart';
import 'pages/details_page.dart';
import 'pages/all_set_page.dart';

class OnboardingWrapper extends StatefulWidget {
  const OnboardingWrapper({super.key});

  @override
  State<OnboardingWrapper> createState() => _OnboardingWrapperState();
}

class _OnboardingWrapperState extends State<OnboardingWrapper> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: BunkTheme.of(context).background,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  IntroPage(onNext: _nextPage),
                  DetailsPage(onNext: _nextPage),
                  AllSetPage(
                    onNext: () {
                      // State handled inside AllSetPage, it will trigger a re-build in main.dart
                    },
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
