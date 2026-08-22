import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fotdelsi/core/motion/app_motion.dart';
import 'package:fotdelsi/core/motion/status_transition.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_curves.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import 'package:fotdelsi/features/counter_sale/presentation/widgets/direct_cycle_qr_sheet.dart';
import '../cubit/pending_payments_cubit.dart';
import '../../domain/entities/pending_drop_off_payment.dart';

/// Un dépôt ou cycle direct en attente d'encaissement.
///
/// La carte répond d'abord à « que dois-je faire ? » : attendre, relancer, ou
/// terminer la vente. Les trois états ne sont donc pas fondus dans un même
/// « en attente » — c'est la distinction qui rend l'écran utile plutôt
/// qu'informatif.
class PendingPaymentCard extends StatelessWidget {
  const PendingPaymentCard({super.key, required this.payment});

  final PendingDropOffPayment payment;

  @override
  Widget build(BuildContext context) {
    final tone = _ToneFor(payment.state);
    final isDirect = payment.isDirectCycle;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDirect
                      ? AppColors.secondary.withValues(alpha: 0.12)
                      : AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isDirect ? 'Cycle Direct' : 'Dépôt',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDirect ? AppColors.secondary : AppColors.primary,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                formatFcfa(payment.amount),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            payment.customerName.isEmpty
                ? (isDirect ? 'Client au comptoir' : 'Client sans nom')
                : payment.customerName,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              if (payment.contactPhone.isNotEmpty)
                Text(
                  '+221 ${payment.contactPhone}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (isDirect && payment.machineName != null) ...[
                if (payment.contactPhone.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  const Text('·', style: TextStyle(color: AppColors.textTertiary)),
                  const SizedBox(width: 8),
                ],
                Text(
                  payment.machineName!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
              if (isDirect && payment.formulaLabel != null) ...[
                const SizedBox(width: 6),
                Text(
                  '(${payment.formulaLabel})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),
          Row(
            children: [
              // Le lien meurt pendant que l'agent regarde la liste : la
              // bascule « en attente » → « expiré » doit se voir se produire.
              AnimatedContainer(
                duration: AppMotion.duration(context, AppDurations.fast),
                curve: AppCurves.standard,
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: tone.background,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: StatusTransition(
                  statusKey: payment.state,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(tone.icon, size: 13, color: tone.foreground),
                      const SizedBox(width: 5),
                      Text(
                        tone.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: tone.foreground,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Depuis combien de temps le client attend, et — tant que le lien
              // vit — combien de temps il lui reste. C'est ce qui dit s'il faut
              // aller lui parler plutôt que patienter.
              Text(
                _timing(payment),
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),

          if (tone.hint != null) ...[
            const SizedBox(height: 8),
            Text(
              tone.hint!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          if (isDirect &&
              payment.state == PendingPaymentState.awaitingPayment &&
              payment.qrPayload != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await DirectCycleQrSheet.show(
                    context,
                    payment: payment,
                  );
                  if (context.mounted) {
                    context.read<PendingPaymentsCubit>().refresh();
                  }
                },
                icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                label: const Text(
                  'Afficher le QR Code',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Le temps qui compte selon l'état : ce qu'il reste au client tant que le
  /// lien vit, ce qu'il a laissé passer une fois qu'il est mort.
  static String _timing(PendingDropOffPayment payment) {
    final left = payment.validFor;
    if (payment.state == PendingPaymentState.awaitingPayment && left != null) {
      return 'expire dans ${_elapsed(left)}';
    }
    return 'depuis ${_elapsed(payment.waiting)}';
  }

  /// Arrondi à la minute puis à l'heure : à la seconde près, l'affichage
  /// changerait sans arrêt pour une information qui se lit en un coup d'œil.
  static String _elapsed(Duration d) {
    if (d.inMinutes < 1) return "moins d'une minute";
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    return minutes == 0 ? '$hours h' : '$hours h $minutes min';
  }
}

/// Couleur, libellé et conseil associés à un état.
class _ToneFor {
  factory _ToneFor(PendingPaymentState state) => switch (state) {
    PendingPaymentState.awaitingPayment => const _ToneFor._(
      label: 'En attente du client',
      icon: Icons.hourglass_bottom_rounded,
      foreground: Color(0xFF8A6100),
      background: Color(0xFFFFF5E0),
    ),
    PendingPaymentState.paymentExpired => const _ToneFor._(
      label: 'Lien expiré',
      icon: Icons.timer_off_outlined,
      foreground: Color(0xFF9A4B00),
      background: Color(0xFFFDEDE0),
      hint:
          'Le client n\'a pas payé à temps : le lien ne fonctionne plus. '
          'Refaites la vente pour lui en envoyer un nouveau.',
    ),
    PendingPaymentState.paymentFailed => const _ToneFor._(
      label: 'Paiement refusé',
      icon: Icons.error_outline_rounded,
      foreground: AppColors.danger,
      background: Color(0xFFFDECEC),
      hint:
          'Le paiement n\'est pas allé au bout. Refaites la demande depuis '
          'un nouveau dépôt.',
    ),
    PendingPaymentState.notInitiated => const _ToneFor._(
      label: 'Paiement non lancé',
      icon: Icons.pending_actions_rounded,
      foreground: Color(0xFF7A4EBD),
      background: Color(0xFFF1EAFB),
      hint:
          'Ce dépôt a été saisi sans demande de paiement. Le linge est peut-'
          'être déjà au comptoir.',
    ),
  };

  const _ToneFor._({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
    this.hint,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;
  final String? hint;
}
