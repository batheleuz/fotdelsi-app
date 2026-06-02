import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_curves.dart';

/// Indicateurs de page animés (le point actif s'allonge en orange).
///
/// Composant interne à l'onboarding.
class OnboardingIndicator extends StatelessWidget {
  const OnboardingIndicator({
    super.key,
    required this.count,
    required this.currentIndex,
  });

  final int count;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: AppDurations.normal,
            curve: AppCurves.standard,
            margin: const EdgeInsets.symmetric(horizontal: 3.5),
            height: 7,
            width: i == currentIndex ? 22 : 7,
            decoration: BoxDecoration(
              color: i == currentIndex
                  ? AppColors.secondary
                  : AppColors.indicatorInactive,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}
