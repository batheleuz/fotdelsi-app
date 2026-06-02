import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fotdelsi/core/constants/app_images.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_curves.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import '../../domain/entities/onboarding_slide.dart';
import 'onboarding_bubbles.dart';

/// Illustration d'un écran d'onboarding.
///
/// Mappe le type métier [OnboardingIllustration] vers une illustration SVG, et
/// compose le fond teinté + les bulles flottantes. L'illustration apparaît avec
/// une légère animation d'entrée (scale + fade) à chaque changement de slide.
class OnboardingIllustrationView extends StatelessWidget {
  const OnboardingIllustrationView({super.key, required this.illustration});

  final OnboardingIllustration illustration;

  String get _asset => switch (illustration) {
        OnboardingIllustration.wash => AppImages.onboardingWash,
        OnboardingIllustration.pay => AppImages.onboardingPay,
        OnboardingIllustration.track => AppImages.onboardingTrack,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.xl - 4),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const OnboardingBubbles(),
          TweenAnimationBuilder<double>(
            key: ValueKey(illustration),
            tween: Tween(begin: 0.85, end: 1),
            duration: AppDurations.normal,
            curve: AppCurves.emphasized,
            builder: (context, scale, child) => Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: ((scale - 0.85) / 0.15).clamp(0.0, 1.0),
                child: child,
              ),
            ),
            child: SvgPicture.asset(_asset, width: 180, height: 180),
          ),
        ],
      ),
    );
  }
}
