import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../../domain/entities/payment_delivery.dart';

/// Demande à l'agent comment la demande de paiement doit atteindre le payeur.
///
/// Renvoie `null` si la feuille est refermée sans choisir : aucune demande ne
/// part alors, ce qui est l'issue prudente — une demande envoyée par le mauvais
/// canal se rattrape mal, le client attendant une notification qu'il ne verra
/// pas, ou un QR que personne ne lui montre.
///
/// Les deux cas existent vraiment au comptoir : le client apporte son linge
/// lui-même et paie devant l'agent, ou il envoie quelqu'un et paiera depuis son
/// téléphone. Choisir à sa place, c'était se tromper une fois sur deux.
Future<PaymentDelivery?> askPaymentDelivery(BuildContext context) {
  return showModalBottomSheet<PaymentDelivery>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _DeliveryChoice(),
  );
}

class _DeliveryChoice extends StatelessWidget {
  const _DeliveryChoice();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          const Text(
            'Comment le client va-t-il payer ?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          _Option(
            icon: Icons.qr_code_2_rounded,
            accent: AppColors.secondary,
            title: 'Afficher le QR code',
            subtitle: 'Le client paie directement avec son application mobile money.',
            onTap: () => Navigator.of(context).pop(PaymentDelivery.onSite),
          ),
          const SizedBox(height: AppSpacing.sm),
          _Option(
            icon: Icons.send_rounded,
            accent: AppColors.primary,
            title: 'Envoyer la demande',
            subtitle:
                'Le client reçoit le lien de paiement sur son téléphone.',
            onTap: () => Navigator.of(context).pop(PaymentDelivery.notify),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, size: 21, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
