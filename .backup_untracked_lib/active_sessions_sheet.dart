import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../../domain/entities/wash_cycle.dart';
import '../cubit/wash_cycles_cubit.dart';
import 'confirm_pickup_sheet.dart';
import 'confirm_start_sheet.dart';
import 'pick_dryer_sheet.dart';
import 'start_command_sent_sheet.dart';

/// Toutes les sessions en cours, quand il y en a plus d'une.
///
/// ─── Pourquoi elle existe ───
///
/// Rien n'empêche un client de payer deux fois — deux machines chargées en
/// même temps, ou simplement un second paiement lancé parce que le premier
/// semblait ne pas passer. Il obtient alors deux cycles bien réels, et
/// l'accueil n'en montrait qu'un : le second existait, était payé, et
/// n'apparaissait nulle part tant qu'on n'ouvrait pas l'écran complet.
///
/// ─── Pourquoi une feuille, et non l'écran complet ───
///
/// L'écran des cycles mêle l'historique aux cycles vivants. Depuis l'accueil,
/// la question est plus courte : « lesquels tournent maintenant, et lequel
/// attend un geste ». La feuille ne montre que cela, et le bouton du bas mène
/// à l'écran complet pour le reste.
Future<void> showActiveSessionsSheet(
  BuildContext context, {
  required List<WashCycle> cycles,
  required WashCyclesCubit cubit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (sheetContext) => BlocProvider.value(
      value: cubit,
      child: _ActiveSessionsSheet(cycles: cycles),
    ),
  );
}

class _ActiveSessionsSheet extends StatelessWidget {
  const _ActiveSessionsSheet({required this.cycles});

  final List<WashCycle> cycles;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              cycles.length == 1
                  ? 'Votre lavage'
                  : 'Vos ${cycles.length} lavages',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Chacun est payé et suivi séparément.',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),

            // `shrinkWrap` : la feuille s'ajuste au nombre de cycles. Au-delà
            // de quelques-uns, elle défile plutôt que de couvrir l'écran.
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: cycles.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _CycleRow(cycle: cycles[index]),
              ),
            ),

            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.push(AppRoutes.myCycles);
                },
                child: const Text('Voir tous mes lavages'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CycleRow extends StatelessWidget {
  const _CycleRow({required this.cycle});

  final WashCycle cycle;

  /// Ce que la machine fait, en un mot.
  ///
  /// `dryingToStart` mérite sa propre phrase : la session est encore
  /// « en cours » côté serveur, mais plus rien ne tourne et c'est au client
  /// d'agir. La confondre avec `running` laisserait quelqu'un attendre devant
  /// une machine arrêtée.
  String get _statusLabel => switch (cycle.state) {
    CycleState.toStart => 'À démarrer',
    CycleState.dryingToStart => 'Lavage terminé — séchage à lancer',
    // Ce que l'application sait : la commande est partie. Personne ne peut
    // plus vérifier qu'une machine tourne — EQLink ne le rend pas — et le
    // client n'a peut-être pas encore appuyé sur l'écran de la machine.
    CycleState.running => 'Commande envoyée',
    CycleState.awaitingPickup => 'Linge à récupérer',
    CycleState.failed => 'N\'a pas démarré',
    CycleState.finished => 'Terminé',
  };

  Color get _statusColor => switch (cycle.state) {
    CycleState.failed => AppColors.danger,
    CycleState.running => AppColors.textSecondary,
    CycleState.finished => AppColors.success,
    _ => AppColors.secondary,
  };

  String get _machineLabel {
    final name = cycle.isDrying
        ? (cycle.dryerMachineName ?? cycle.machineName)
        : cycle.machineName;
    return name ?? 'Machine';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _machineLabel,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusLabel,
                  style: TextStyle(fontSize: 12.5, color: _statusColor),
                ),
                if (cycle.formulaLabel != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    cycle.formulaLabel!,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (cycle.state.needsAction) ...[
            const SizedBox(width: 10),
            _StartButton(cycle: cycle),
          ],
        ],
      ),
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({required this.cycle});

  final WashCycle cycle;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<WashCyclesCubit>().state;

    // Un seul démarrage à la fois, comme partout ailleurs : deux appuis
    // simultanés lanceraient deux machines pour un client qui n'a chargé
    // qu'un tambour.
    final busy = state.startingToken != null;
    final thisOne = state.startingToken == cycle.token;

    return FilledButton(
      onPressed: busy ? null : () => _start(context),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: thisOne
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Text(switch (cycle.state) {
              CycleState.dryingToStart => 'Sécher',
              CycleState.awaitingPickup => 'Terminer',
              _ => 'Démarrer',
            }),
    );
  }

  Future<void> _start(BuildContext context) async {
    final cubit = context.read<WashCyclesCubit>();

    // Le second temps ne se lance pas comme le premier : `start` relancerait
    // la LAVEUSE par son jeton, alors qu'il faut désigner une sécheuse.
    if (cycle.state == CycleState.dryingToStart) {
      await showPickDryerSheet(context, cycle, cycles: cubit);
      return;
    }

    // Rien à lancer : le linge est présumé prêt, et c'est cette confirmation
    // qui clôt le cycle — plus aucune machine ne sait le faire.
    if (cycle.state == CycleState.awaitingPickup) {
      if (await confirmLaundryPickup(context)) {
        await cubit.confirmPickup(cycle);
      }
      return;
    }

    // Confirmation avant tout démarrage physique : un appui involontaire
    // consommerait le cycle payé sur un tambour vide.
    if (await confirmMachineStart(context, machineName: cycle.machineName)) {
      if (await cubit.start(cycle) && context.mounted) {
        // La commande est partie ; le tambour attend que le client appuie sur
        // l'écran de la machine. C'est là qu'il faut le lui dire.
        await showStartCommandSent(context, machineName: cycle.machineName);
      }
    }
  }
}
