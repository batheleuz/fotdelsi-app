import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import '../../cubit/new_dropoff_cubit.dart';

/// Étape 4 — attente du paiement client. **Non bloquante** : l'agent peut
/// revenir à la file et servir le client suivant ; le dépôt apparaîtra dans
/// « À lancer » une fois le paiement confirmé.
class NewDropOffAwaitingStep extends StatefulWidget {
  const NewDropOffAwaitingStep({super.key});

  @override
  State<NewDropOffAwaitingStep> createState() => _NewDropOffAwaitingStepState();
}

class _NewDropOffAwaitingStepState extends State<NewDropOffAwaitingStep> {
  static const _totalSeconds = 15 * 60;
  int _remaining = _totalSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) {
        _timer?.cancel();
      } else if (mounted) {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formatted {
    final m = (_remaining ~/ 60).toString().padLeft(2, '0');
    final s = (_remaining % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _resend() async {
    final ok = await context.read<NewDropOffCubit>().resend();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(ok
            ? 'Notification renvoyée au client.'
            : 'Échec de l\'envoi, réessayez.'),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final phone = context.select((NewDropOffCubit c) => c.state.contactPhone);
    final expired = _remaining <= 0;
    final canResend = _remaining <= _totalSeconds - 60;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          _Ring(expired: expired),
          const SizedBox(height: AppSpacing.lg),
          Text(expired ? 'Lien expiré' : 'Demande envoyée à',
              style: const TextStyle(
                  fontSize: 14, color: AppColors.textSecondary)),
          if (!expired) ...[
            const SizedBox(height: 2),
            Text('+221 $phone',
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.md),
            Text(_formatted,
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Le client confirme le paiement sur son app Wave / Orange Money.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text('Le client n\'a pas payé à temps.',
                  style: TextStyle(color: AppColors.textSecondary)),
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
            onPressed: canResend && !expired ? _resend : null,
            child: Text(canResend || expired
                ? 'Renvoyer la notification'
                : 'Renvoyer la notification · dans 1 min'),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.expired});
  final bool expired;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surfaceTint,
      ),
      alignment: Alignment.center,
      child: Icon(
        expired ? Icons.timer_off_outlined : Icons.schedule,
        size: 40,
        color: expired ? AppColors.textTertiary : AppColors.primaryLight,
      ),
    );
  }
}
