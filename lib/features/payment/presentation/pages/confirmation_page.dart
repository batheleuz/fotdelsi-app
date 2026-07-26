import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import '../widgets/session_countdown_ring.dart';
import '../widgets/session_recap_card.dart';
import '../widgets/success_check_badge.dart';

/// Écran de confirmation : la machine est lancée, le cycle démarre.
///
/// Phase design : le décompte tourne via un [Timer] local. En production il
/// suivra `wash_session.remain_time` poussé par le WebSocket.
class ConfirmationPage extends StatefulWidget {
  const ConfirmationPage({
    super.key,
    required this.machine,
    this.durationSeconds = 2100,
  });

  final Machine machine;
  final int durationSeconds;

  @override
  State<ConfirmationPage> createState() => _ConfirmationPageState();
}

class _ConfirmationPageState extends State<ConfirmationPage> {
  late int _remaining = widget.durationSeconds;
  late final DateTime _endsAt =
      DateTime.now().add(Duration(seconds: widget.durationSeconds));
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_remaining <= 0) return;
      setState(() => _remaining--);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _durationLabel => '${widget.durationSeconds ~/ 60} min';

  String get _endTimeLabel {
    final h = _endsAt.hour.toString().padLeft(2, '0');
    final m = _endsAt.minute.toString().padLeft(2, '0');
    return '${h}h$m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.md,
                ),
                child: Column(
                  children: [
                    const SuccessCheckBadge(),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Machine lancée !',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Votre lavage a démarré. Détendez-vous, on s’occupe du reste.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SessionCountdownRing(
                      remaining: _remaining,
                      total: widget.durationSeconds,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    SessionRecapCard(
                      machine: widget.machine,
                      durationLabel: _durationLabel,
                      endTimeLabel: _endTimeLabel,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _NotifyHint(),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg,
              ),
              child: PrimaryButton(
                label: "Retour à l'accueil",
                onPressed: () => context.go(AppRoutes.home),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifyHint extends StatelessWidget {
  const _NotifyHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.notifications_active_outlined,
            size: 16, color: AppColors.textTertiary),
        SizedBox(width: 8),
        Text(
          'Vous serez notifié à la fin du cycle.',
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}
