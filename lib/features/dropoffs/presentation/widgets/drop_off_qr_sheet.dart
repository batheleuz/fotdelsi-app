import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/phone_number.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import 'package:fotdelsi/features/payment/domain/repositories/payment_repository.dart';
import 'package:fotdelsi/features/payment/presentation/widgets/payment_qr_view.dart';
import '../../domain/entities/pending_drop_off_payment.dart';

/// Réaffiche le QR de paiement d'un dépôt que le client n'a pas encore réglé.
///
/// Comble un cul-de-sac : l'agent qui fermait l'assistant avant le paiement —
/// parce qu'un autre client attendait, ou par mégarde — ne pouvait plus jamais
/// remontrer le code. La commande restait dans « Paiements en attente », visible
/// mais inerte, et il fallait refaire toute la saisie.
///
/// Feuille distincte de celle du Cycle Direct, et non un paramètre de plus sur
/// elle : un dépôt n'a ni machine ni jeton de session. Il ne se surveille donc
/// pas de la même façon — on interroge le PAIEMENT — et il n'y a aucun cycle à
/// lancer au bout. Ce que le client paie ici, c'est un linge que l'agent lavera.
class DropOffQrSheet extends StatefulWidget {
  const DropOffQrSheet({super.key, required this.payment});

  final PendingDropOffPayment payment;

  static Future<void> show(
    BuildContext context, {
    required PendingDropOffPayment payment,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      // Sans quoi la feuille est rognée sur les grands écrans.
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DropOffQrSheet(payment: payment),
    );
  }

  @override
  State<DropOffQrSheet> createState() => _DropOffQrSheetState();
}

class _DropOffQrSheetState extends State<DropOffQrSheet> {
  final _payments = serviceLocator<PaymentRepository>();

  static const _pollInterval = Duration(seconds: 3);

  Timer? _pollTimer;
  bool _isPaid = false;

  @override
  void initState() {
    super.initState();
    final paymentId = widget.payment.paymentId;
    if (paymentId != null) {
      _pollTimer = Timer.periodic(
        _pollInterval,
        (_) => _checkPayment(paymentId),
      );
      _checkPayment(paymentId);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPayment(String paymentId) async {
    final result = await _payments.isPaymentConfirmed(paymentId);
    if (!mounted) return;

    result.fold(
      // Un échec réseau ne dit rien du paiement : on retentera au prochain
      // battement plutôt que d'annoncer un échec qui n'a pas eu lieu.
      (_) => null,
      (confirmed) {
        if (!confirmed || _isPaid) return;
        _pollTimer?.cancel();
        setState(() => _isPaid = true);
      },
    );
  }

  PaymentProvider get _provider =>
      widget.payment.provider?.toUpperCase() == 'ORANGE_MONEY'
      ? PaymentProvider.orangeMoney
      : PaymentProvider.wave;

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final payload = payment.qrPayload;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),

            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Dépôt',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  color: AppColors.textSecondary,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 4),

            _ClientCard(payment: payment),
            const SizedBox(height: AppSpacing.md),

            if (_isPaid)
              const _Confirmed()
            else if (payload != null)
              PaymentQrView(
                payload: payload,
                provider: _provider,
                amount: payment.amount,
              )
            else
              const _NoPayload(),

            if (!_isPaid && payload != null) ...[
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Le client scanne ce code avec l\'appareil photo de son '
                'téléphone. Le dépôt rejoint la file dès que le paiement est '
                'confirmé.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Qui paie, et combien.
class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.payment});

  final PendingDropOffPayment payment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  payment.customerName.isEmpty
                      ? 'Client sans nom'
                      : payment.customerName,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                formatFcfa(payment.amount),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (payment.contactPhone.isNotEmpty)
                Text(
                  displayPhone(payment.contactPhone),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              if (payment.formulaLabel != null) ...[
                if (payment.contactPhone.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  const Text(
                    '·',
                    style: TextStyle(color: AppColors.textTertiary),
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    payment.formulaLabel!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Le paiement est arrivé pendant que la feuille était ouverte.
class _Confirmed extends StatelessWidget {
  const _Confirmed();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle_rounded,
            size: 44,
            color: AppColors.success,
          ),
          SizedBox(height: 10),
          Text(
            'Paiement confirmé',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Le dépôt est entré dans la file d\'attente.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Rien à montrer : l'encaissement n'a jamais été lancé sur ce dépôt.
class _NoPayload extends StatelessWidget {
  const _NoPayload();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.qr_code_2_rounded, size: 34, color: AppColors.textTertiary),
          SizedBox(height: 8),
          Text(
            'Aucun code à afficher',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'La demande de paiement n\'a pas été lancée pour ce dépôt. '
            'Reprenez la vente pour en envoyer une.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
