import 'dart:async';

import 'package:flutter/material.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/pending_drop_off_payment.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import 'package:fotdelsi/features/payment/presentation/widgets/payment_qr_view.dart';
import 'package:fotdelsi/features/wash_session/domain/entities/session_payment_status.dart';
import 'package:fotdelsi/features/wash_session/domain/repositories/wash_session_repository.dart';
import 'package:fotdelsi/features/wash_session/presentation/widgets/confirm_start_sheet.dart';

/// Feuille modale pour réafficher le QR code de paiement d'un Cycle Direct en attente.
///
/// Permet à l'agent de remontrer le code au client si ce dernier ne l'avait pas scanné
/// immédiatement. Scrute l'état du paiement en arrière-plan et propose le bouton de démarrage
/// physique dès que le paiement est confirmé.
class DirectCycleQrSheet extends StatefulWidget {
  const DirectCycleQrSheet({
    super.key,
    required this.payment,
  });

  final PendingDropOffPayment payment;

  static Future<bool?> show(
    BuildContext context, {
    required PendingDropOffPayment payment,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DirectCycleQrSheet(payment: payment),
    );
  }

  @override
  State<DirectCycleQrSheet> createState() => _DirectCycleQrSheetState();
}

class _DirectCycleQrSheetState extends State<DirectCycleQrSheet> {
  final _sessionRepo = serviceLocator<WashSessionRepository>();
  Timer? _pollTimer;

  bool _isPaid = false;
  bool _isStarting = false;
  bool _isStarted = false;
  String? _errorMessage;

  static const _pollInterval = Duration(seconds: 3);

  @override
  void initState() {
    super.initState();
    final token = widget.payment.washSessionToken;
    if (token != null && token.isNotEmpty) {
      _startPolling(token);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPolling(String token) {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _checkStatus(token));
    _checkStatus(token);
  }

  Future<void> _checkStatus(String token) async {
    final result = await _sessionRepo.getSessionStatus(token);
    if (!mounted) return;

    result.fold(
      (_) => null,
      (status) {
        if (status.paymentStatus == SessionPaymentStatus.confirmed) {
          _pollTimer?.cancel();
          if (!_isPaid) {
            setState(() {
              _isPaid = true;
              _errorMessage = null;
            });
          }
        } else if (status.paymentStatus.isTerminalFailure) {
          _pollTimer?.cancel();
          setState(() {
            _errorMessage = 'Le paiement n\'a pas abouti.';
          });
        }
      },
    );
  }

  Future<void> _startMachine() async {
    final token = widget.payment.washSessionToken;
    if (token == null || _isStarting || _isStarted) return;

    final confirmed = await confirmMachineStart(
      context,
      machineName: widget.payment.machineName,
    );
    if (!confirmed || !mounted) return;

    setState(() {
      _isStarting = true;
      _errorMessage = null;
    });

    final result = await _sessionRepo.startMachine(token);
    if (!mounted) return;

    result.fold(
      (failure) {
        setState(() {
          _isStarting = false;
          _errorMessage = failure.message;
        });
      },
      (_) {
        setState(() {
          _isStarting = false;
          _isStarted = true;
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      },
    );
  }

  PaymentProvider get _provider {
    final raw = widget.payment.provider?.toUpperCase();
    if (raw == 'ORANGE_MONEY') return PaymentProvider.orangeMoney;
    return PaymentProvider.wave;
  }

  @override
  Widget build(BuildContext context) {
    final payment = widget.payment;
    final payload = payment.qrPayload;

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
        children: [
          // Poignée
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

          // En-tête
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Cycle',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.secondary,
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

          // Informations client & machine
          Container(
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
                    Text(
                      payment.customerName.isEmpty
                          ? 'Client au comptoir'
                          : payment.customerName,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
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
                    if (payment.contactPhone.isNotEmpty) ...[
                      Text(
                        '+221 ${payment.contactPhone}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('·', style: TextStyle(color: AppColors.textTertiary)),
                      const SizedBox(width: 8),
                    ],
                    if (payment.machineName != null)
                      Text(
                        payment.machineName!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    if (payment.formulaLabel != null) ...[
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
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Corps : QR Code ou Statut Confirmé
          if (_isStarted) ...[
            Container(
              padding: const EdgeInsets.all(24),
              child: const Column(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 64,
                    color: AppColors.success,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Machine démarrée !',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_isPaid) ...[
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    size: 52,
                    color: AppColors.success,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Paiement validé avec succès !',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Chargez le linge dans ${payment.machineName ?? 'la machine'} puis lancez le cycle.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            PrimaryButton(
              label: 'Démarrer la machine',
              icon: Icons.play_arrow_rounded,
              loading: _isStarting,
              backgroundColor: AppColors.secondary,
              onPressed: _startMachine,
            ),
          ] else ...[
            if (payload != null)
              PaymentQrView(
                payload: payload,
                provider: _provider,
                amount: payment.amount,
                size: 210,
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Text(
                  'Lien de paiement indisponible.',
                  style: TextStyle(fontSize: 13, color: AppColors.danger),
                ),
              ),

            const SizedBox(height: AppSpacing.md),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  'En attente du paiement du client…',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
