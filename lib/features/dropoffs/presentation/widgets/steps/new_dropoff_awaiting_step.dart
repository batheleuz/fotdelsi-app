import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import 'package:fotdelsi/features/payment/presentation/widgets/payment_qr_view.dart';
import '../../cubit/new_dropoff_cubit.dart';

/// Étape 4 — confirmation d'envoi de la demande de paiement. **Non bloquante** :
/// l'agent revient à la file et sert le client suivant ; le dépôt apparaîtra
/// dans « À lancer » dès que le paiement est confirmé (mis à jour en temps réel).
class NewDropOffAwaitingStep extends StatefulWidget {
  const NewDropOffAwaitingStep({super.key});

  @override
  State<NewDropOffAwaitingStep> createState() => _NewDropOffAwaitingStepState();
}

class _NewDropOffAwaitingStepState extends State<NewDropOffAwaitingStep> {
  /// Court délai anti-spam avant de pouvoir renvoyer la notification.
  static const _resendCooldown = 60;
  int _cooldown = _resendCooldown;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  void _startCooldown() {
    _timer?.cancel();
    _cooldown = _resendCooldown;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_cooldown <= 0) {
        _timer?.cancel();
      } else if (mounted) {
        setState(() => _cooldown--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _resend() async {
    final ok = await context.read<NewDropOffCubit>().resend();
    if (!mounted) return;
    if (ok) _startCooldown();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Notification renvoyée au client.'
                : 'Échec de l\'envoi, réessayez.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<NewDropOffCubit>().state;

    // Le client est devant l'agent : il n'y a rien à attendre ni à renvoyer,
    // seulement un code à lui montrer.
    if (state.showsQr) return _QrToShow(state: state);

    final phone = state.contactPhone;
    final canResend = _cooldown <= 0;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          const _Ring(),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Demande envoyée à',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            '+221 $phone',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'Le client confirme le paiement sur son app Wave / Orange Money.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE7F1FF),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF155A9E), size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Vous pouvez servir le client suivant — ce dépôt apparaîtra dans « À lancer » une fois payé.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF155A9E)),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          PrimaryButton(
            label: 'Revenir à la file',
            icon: Icons.arrow_back_rounded,
            backgroundColor: AppColors.primaryLight,
            onPressed: () => context.pop(),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: canResend ? _resend : null,
            child: Text(
              canResend
                  ? 'Renvoyer la notification'
                  : 'Renvoyer la notification · ${_cooldown}s',
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceTint,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.send_rounded,
        size: 38,
        color: AppColors.primaryLight,
      ),
    );
  }
}

/// Le code à scanner, quand le client est là.
///
/// Même parti pris que l'écran de vente au comptoir : c'est le seul contenu
/// destiné à être lu par quelqu'un d'AUTRE que le porteur du téléphone. Pas de
/// bouton à côté du code, rien qui puisse être touché par mégarde pendant que
/// le client scanne.
class _QrToShow extends StatelessWidget {
  const _QrToShow({required this.state});

  final NewDropOffState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surfaceTint,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Scannez pour payer',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Avec l\'appareil photo de votre téléphone',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),

          PaymentQrView(
            payload: state.session!.qrPayload!,
            provider: state.provider!,
            amount: state.total,
            size: 240,
          ),

          const SizedBox(height: 32),
          const Text(
            'Le dépôt rejoindra la file dès le paiement confirmé.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
          ),
          const SizedBox(height: AppSpacing.lg),
          PrimaryButton(
            label: 'Terminer',
            icon: Icons.check_rounded,
            backgroundColor: AppColors.primaryLight,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}
