import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import 'onboarding_indicator.dart';

/// Pied de page de l'onboarding : indicateurs + bouton d'action.
///
/// Le libellé du bouton bascule sur « Commencer » au dernier écran.
class OnboardingFooter extends StatelessWidget {
  const OnboardingFooter({
    super.key,
    required this.pageCount,
    required this.currentIndex,
    required this.isLast,
    required this.onNext,
  });

  final int pageCount;
  final int currentIndex;
  final bool isLast;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      child: Column(
        children: [
          OnboardingIndicator(count: pageCount, currentIndex: currentIndex),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: isLast ? 'Commencer' : 'Suivant',
            icon: Icons.arrow_forward_rounded,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
