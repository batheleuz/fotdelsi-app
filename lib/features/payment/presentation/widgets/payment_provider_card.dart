import 'package:flutter/material.dart';

import 'package:fotdelsi/core/constants/app_icons.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_curves.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import '../../domain/entities/payment_provider.dart';
import '../utils/payment_provider_presentation.dart';
import 'payment_provider_logo.dart';

/// Carte sélectionnable d'un moyen de paiement.
class PaymentProviderCard extends StatelessWidget {
  const PaymentProviderCard({
    super.key,
    required this.provider,
    required this.selected,
    required this.onTap,
  });

  final PaymentProvider provider;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        padding: EdgeInsets.all(selected ? 13 : 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 2 : 0.5,
          ),
        ),
        child: Row(
          children: [
            PaymentProviderLogo(provider: provider),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    provider.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    provider.tagline,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              duration: AppDurations.fast,
              opacity: selected ? 1 : 0,
              child: const Icon(AppIcons.check,
                  size: 20, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
