import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/payment/presentation/widgets/session_countdown_ring.dart';
import 'package:fotdelsi/features/payment/presentation/widgets/session_recap_card.dart';
import '../cubit/wash_session_cubit.dart';

/// Bottom sheet — session de lavage en cours.
///
/// Affiché quand [WashSessionState.isRunning] est vrai.
/// Peut être ouvert/fermé librement ; le FAB "Session en cours" permet d'y revenir.
class WashRunningSheet extends StatelessWidget {
  const WashRunningSheet._({required this.machine, required this.rootContext});

  final Machine machine;
  final BuildContext rootContext;

  static void show(BuildContext context, Machine machine) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<WashSessionCubit>(),
        child: WashRunningSheet._(machine: machine, rootContext: context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WashSessionCubit, WashSessionState>(
      listenWhen: (prev, curr) =>
          prev.isRunning != curr.isRunning,
      listener: (context, state) {
        // Session terminée pendant que le sheet est ouvert.
        if (!state.isRunning) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final remaining = state.remainingSeconds;

        // Durée initiale estimée : 35 min si non disponible.
        const int fallbackTotal = 2100;
        final total =
            state.pendingSession != null ? fallbackTotal : fallbackTotal;

        return _SheetContainer(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DragHandle(),
                const SizedBox(height: AppSpacing.md),
                const _RunningHeader(),
                const SizedBox(height: AppSpacing.lg),
                SessionCountdownRing(
                  remaining: remaining ?? 0,
                  total: total,
                  size: 160,
                ),
                const SizedBox(height: AppSpacing.lg),
                SessionRecapCard(
                  machine: machine,
                  durationLabel: _durationLabel(total),
                  endTimeLabel: _endTimeLabel(remaining ?? 0),
                ),
                const SizedBox(height: AppSpacing.md),
                const _UpdateHint(),
                SizedBox(
                  height: MediaQuery.of(context).padding.bottom + AppSpacing.md,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _durationLabel(int seconds) => '${seconds ~/ 60} min';

  String _endTimeLabel(int remainingSeconds) {
    final endsAt = DateTime.now().add(Duration(seconds: remainingSeconds));
    final h = endsAt.hour.toString().padLeft(2, '0');
    final m = endsAt.minute.toString().padLeft(2, '0');
    return '${h}h$m';
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _SheetContainer extends StatelessWidget {
  const _SheetContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: child,
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _RunningHeader extends StatelessWidget {
  const _RunningHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.local_laundry_service_rounded,
            color: AppColors.success,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Machine lancée !',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Votre cycle est en cours.',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _UpdateHint extends StatelessWidget {
  const _UpdateHint();

  @override
  Widget build(BuildContext context) {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.sync_rounded,
          size: 14,
          color: AppColors.textTertiary,
        ),
        SizedBox(width: 6),
        Text(
          'Mis à jour toutes les 10 secondes',
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}
