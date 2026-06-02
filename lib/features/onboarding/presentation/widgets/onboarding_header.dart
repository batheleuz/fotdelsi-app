import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';

/// En-tête de l'onboarding : bouton « Passer » aligné à droite.
///
/// Disparaît en fondu sur le dernier écran.
class OnboardingHeader extends StatelessWidget {
  const OnboardingHeader({
    super.key,
    required this.visible,
    required this.onSkip,
  });

  final bool visible;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: AnimatedOpacity(
        opacity: visible ? 1 : 0,
        duration: const Duration(milliseconds: 250),
        child: IgnorePointer(
          ignoring: !visible,
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: TextButton(
              onPressed: onSkip,
              child: const Text(
                'Passer',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
