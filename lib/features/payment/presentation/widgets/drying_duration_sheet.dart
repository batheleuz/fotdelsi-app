import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import 'package:fotdelsi/features/catalog/domain/entities/drying_duration_tier.dart';

/// Modal bottom sheet pour choisir la durée de séchage.
///
/// Affiche les 4 options :
/// - 15 minutes (1 jeton / 100 pulses) : 1 500 CFA
/// - 30 minutes (2 jetons / 200 pulses) : 3 000 CFA
/// - 45 minutes (3 jetons / 300 pulses) : 4 500 CFA
/// - 1 heure (4 jetons / 400 pulses) : 5 000 CFA
Future<DryingDurationTier?> showDryingDurationSheet(
  BuildContext context, {
  required DryingDurationTier currentTier,
  bool isFormula = true,
}) {
  return showModalBottomSheet<DryingDurationTier>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (context) => _DryingDurationSheetContent(
      selectedTier: currentTier,
      isFormula: isFormula,
    ),
  );
}

class _DryingDurationSheetContent extends StatelessWidget {
  const _DryingDurationSheetContent({
    required this.selectedTier,
    required this.isFormula,
  });

  final DryingDurationTier selectedTier;
  final bool isFormula;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            ),
            const Text(
              'Durée du séchage',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choisissez le temps de séchage pour votre linge.',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ...DryingDurationTier.values.map(
              (tier) => _TierTile(
                tier: tier,
                isSelected: tier == selectedTier,
                isFormula: isFormula,
                onTap: () => Navigator.of(context).pop(tier),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }
}

class _TierTile extends StatelessWidget {
  const _TierTile({
    required this.tier,
    required this.isSelected,
    required this.isFormula,
    required this.onTap,
  });

  final DryingDurationTier tier;
  final bool isSelected;
  final bool isFormula;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = tier.pulses ~/ 100;

    final String priceLabel = isFormula
        ? '+${formatFcfa(tier.price)}'
        : formatFcfa(tier.price);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceTint : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isSelected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tier.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '$tokens pièce${tokens > 1 ? 's' : ''} (${tier.pulses} pulses)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                priceLabel,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
