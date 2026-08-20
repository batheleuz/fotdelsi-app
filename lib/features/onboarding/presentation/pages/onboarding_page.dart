import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/onboarding/onboarding_store.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_curves.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../../data/onboarding_content.dart';
import '../../domain/entities/onboarding_slide.dart';
import '../widgets/onboarding_footer.dart';
import '../widgets/onboarding_header.dart';
import '../widgets/onboarding_slide_view.dart';

/// Écran d'onboarding.
///
/// Phase design : l'état est géré localement (PageController + index). Le
/// gestionnaire d'état applicatif (Riverpod / Bloc…) sera branché plus tard,
/// après validation, sans modifier ces sous-composants.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  final List<OnboardingSlide> _slides = const OnboardingContent().getSlides();

  int _index = 0;

  bool get _isLast => _index == _slides.length - 1;

  void _onNext() {
    if (_isLast) {
      _onFinish();
      return;
    }
    _controller.nextPage(
      duration: AppDurations.normal,
      curve: AppCurves.standard,
    );
  }

  void _onSkip() => _controller.animateToPage(
    _slides.length - 1,
    duration: AppDurations.slow,
    curve: AppCurves.standard,
  );

  Future<void> _onFinish() async {
    // Onboarding vu → ne plus l'afficher aux prochaines ouvertures.
    await serviceLocator<OnboardingStore>().markSeen();
    if (mounted) context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: AppSpacing.xs),
            OnboardingHeader(visible: !_isLast, onSkip: _onSkip),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) =>
                    OnboardingSlideView(slide: _slides[i]),
              ),
            ),
            OnboardingFooter(
              pageCount: _slides.length,
              currentIndex: _index,
              isLast: _isLast,
              onNext: _onNext,
            ),
          ],
        ),
      ),
    );
  }
}
