import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';

/// Progression de la vente au comptoir.
///
/// Propre au module : le dépôt a son propre parcours, avec d'autres étapes et
/// d'autres contraintes. Les mutualiser aurait couplé deux flux qui n'ont en
/// commun que d'être séquentiels.
///
/// Volontairement absent de l'étape de paiement : cet écran est montré au
/// client de l'autre côté du comptoir, il ne doit rien porter d'autre que le
/// code à scanner.
class CounterSaleStepper extends StatelessWidget {
  const CounterSaleStepper({super.key, required this.step, this.total = 4});

  /// Index de l'étape courante, à partir de 0.
  final int step;
  final int total;

  static const _labels = ['Prestation', 'Client', 'Paiement', 'Démarrage'];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(total, (i) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i == total - 1 ? 0 : 5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  height: 3,
                  decoration: BoxDecoration(
                    color: i <= step
                        ? AppColors.primaryLight
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Étape ${step + 1} sur $total',
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 2),
        Text(
          _labels[step.clamp(0, _labels.length - 1)],
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
