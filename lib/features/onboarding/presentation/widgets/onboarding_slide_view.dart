import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_curves.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../../domain/entities/onboarding_slide.dart';
import 'onboarding_illustration_view.dart';

/// Une page de l'onboarding : illustration + titre + description.
///
/// Le texte glisse vers le haut en fondu à l'affichage (animation d'entrée).
class OnboardingSlideView extends StatelessWidget {
  const OnboardingSlideView({super.key, required this.slide});

  final OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OnboardingIllustrationView(illustration: slide.illustration),
          const SizedBox(height: AppSpacing.xl),
          _FadeSlideIn(
            child: Column(
              children: [
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpacing.sm + 4),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  child: Text(
                    slide.description,
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium,
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

/// Petite animation d'entrée réutilisable au sein de l'onboarding :
/// fondu + léger glissement vers le haut.
class _FadeSlideIn extends StatefulWidget {
  const _FadeSlideIn({required this.child});

  final Widget child;

  @override
  State<_FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<_FadeSlideIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.normal,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppCurves.standard,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.12),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}
