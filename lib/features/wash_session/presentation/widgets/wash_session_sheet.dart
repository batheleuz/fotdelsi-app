import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import '../../domain/entities/machine_start_status.dart';
import '../cubit/wash_session_cubit.dart';
import 'wash_running_sheet.dart';

/// Bottom sheet — session confirmée, en attente de démarrage de la machine.
///
/// Affiché quand [WashSessionState.hasConfirmedPendingSession] est vrai.
/// Ferme automatiquement et ouvre [WashRunningSheet] quand la machine démarre.
class WashSessionSheet extends StatelessWidget {
  const WashSessionSheet._({required this.machine, required this.rootContext});

  final Machine machine;

  /// Contexte de la page parente — nécessaire pour ouvrir [WashRunningSheet]
  /// après fermeture de ce sheet.
  final BuildContext rootContext;

  static void show(BuildContext context, Machine machine) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<WashSessionCubit>(),
        child: WashSessionSheet._(machine: machine, rootContext: context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WashSessionCubit, WashSessionState>(
      listenWhen: (prev, curr) => prev.startStatus != curr.startStatus,
      listener: (context, state) {
        if (state.startStatus == WashStartStatus.success) {
          context.read<WashSessionCubit>().resetStartStatus();
          Navigator.of(context).pop(); // ferme ce sheet
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (rootContext.mounted && state.startedMachine != null) {
              WashRunningSheet.show(rootContext, state.startedMachine!);
            }
          });
        } else if (state.startStatus == WashStartStatus.failure) {
          ScaffoldMessenger.of(rootContext).showSnackBar(
            SnackBar(
              content: Text(
                state.startError ?? 'Impossible de démarrer la machine.',
              ),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        if (!state.hasConfirmedPendingSession) {
          return const SizedBox.shrink();
        }

        final cubit = context.read<WashSessionCubit>();
        final isRetry =
            state.pendingSession!.machineStartStatus ==
            MachineStartStatus.startFailed;

        return _SheetContainer(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _DragHandle(),
              const SizedBox(height: AppSpacing.md),
              _Header(isRetry: isRetry),
              const SizedBox(height: AppSpacing.sm),
              _MachineLine(machine: machine),
              const SizedBox(height: AppSpacing.lg),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: state.isStarting
                      ? null
                      : () => cubit.startMachine(machine),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: state.isStarting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isRetry ? 'Réessayer' : 'Démarrer',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              const _ReservationNote(),
              SizedBox(
                height: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
              ),
            ],
          ),
        );
      },
    );
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
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
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

class _Header extends StatelessWidget {
  const _Header({required this.isRetry});

  final bool isRetry;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isRetry
                ? AppColors.danger.withValues(alpha: 0.1)
                : AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isRetry ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
            color: isRetry ? AppColors.danger : AppColors.success,
            size: 22,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Expanded : le sous-titre tient sur plusieurs lignes sans déborder.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isRetry
                    ? 'Le démarrage n\'a pas fonctionné'
                    : 'Paiement confirmé',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isRetry
                    ? 'La machine n\'a pas répondu. Vous pouvez réessayer.'
                    : 'Chargez votre linge et fermez le hublot, puis appuyez sur Démarrer.',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MachineLine extends StatelessWidget {
  const _MachineLine({required this.machine});

  final Machine machine;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_laundry_service_rounded,
            size: 20,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            machine.name,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

/// La machine n'est PAS lancée tant que le client n'appuie pas sur Démarrer :
/// on le rassure sur le fait qu'elle lui reste réservée en attendant. Pas de
/// durée codée en dur ici — elle vit côté backend et pourrait diverger.
class _ReservationNote extends StatelessWidget {
  const _ReservationNote();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'La machine vous est réservée le temps de charger votre linge.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
      ),
    );
  }
}
