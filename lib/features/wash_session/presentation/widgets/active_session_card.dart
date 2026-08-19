import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/motion/entrance.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/features/client_auth/presentation/cubit/client_session_cubit.dart';
import '../../domain/entities/wash_cycle.dart';
import '../cubit/wash_cycles_cubit.dart';
import 'confirm_start_sheet.dart';
import 'pick_dryer_sheet.dart';

/// Bandeau de cycle en cours, en tête de l'accueil.
///
/// Résumé de « Mes lavages » : il montre le cycle le plus urgent et renvoie
/// vers la liste complète. Une seule source — le serveur — pour les deux
/// surfaces, donc plus de divergence possible entre ce que dit le bandeau et
/// ce que dit l'écran.
///
/// Il lisait auparavant une session stockée sur le téléphone, à un seul
/// emplacement. C'est ce qui limitait le client à un cycle, faisait survivre
/// la commande d'un client à sa déconnexion, et laissait l'affichage dériver
/// de la réalité du serveur.
class ActiveSessionCard extends StatelessWidget {
  const ActiveSessionCard({super.key});

  @override
  Widget build(BuildContext context) {
    // Un cycle appartient forcément à un numéro lié : le numéro est exigé
    // avant tout paiement, et c'est lui qui identifie le client côté serveur.
    // Déconnecté, ce bandeau n'a plus de propriétaire.
    final isLinked = context.select<ClientSessionCubit, bool>(
      (c) => c.state.isLinked,
    );

    return BlocBuilder<MyCyclesCubit, WashCyclesState>(
      builder: (context, state) {
        final banner = isLinked ? _banner(context, state) : null;

        // Le bandeau se déplie et se replie au lieu de surgir. C'est le
        // premier élément de l'accueil : quand il apparaît, tout le catalogue
        // descend d'un bloc, et ce saut brutal donnait l'impression d'un
        // rechargement de page.
        return AnimatedReveal(
          visible: banner != null,
          child: banner ?? const SizedBox.shrink(),
        );
      },
    );
  }

  /// Ce que le bandeau doit montrer, ou `null` s'il n'a rien à dire.
  Widget? _banner(BuildContext context, WashCyclesState state) {
    // Une remise en attente prime : la finition est payée, et c'est ce
    // bandeau qui porte le code que l'agent va demander.
    //
    // Lu sur le CYCLE, et non sur la session stockée localement : celle-ci ne
    // couvre que l'achat fait sur ce téléphone, si bien qu'une vente encaissée
    // au comptoir n'affichait aucune consigne.
    final handoff = state.awaitingHandoff?.handoffCode;
    if (handoff != null) return _HandoffCard(code: handoff);

    final cycle = state.mostUrgent;
    if (cycle == null) return null;

    return _CycleBanner(
      cycle: cycle,
      starting: state.startingToken == cycle.token,
      // Un seul démarrage à la fois, comme sur l'écran complet.
      //
      // Le second temps ne se lance pas comme le premier : `start` relancerait
      // la LAVEUSE par son jeton, alors qu'il faut désigner une sécheuse.
      onStart: state.startingToken != null
          ? null
          : cycle.state == CycleState.dryingToStart
          ? () => showPickDryerSheet(
              context,
              cycle,
              cycles: context.read<MyCyclesCubit>(),
            )
          : () async {
              // Confirmation avant tout démarrage physique : un appui
              // involontaire consommerait le cycle payé sur un tambour vide.
              final cubit = context.read<MyCyclesCubit>();
              if (await confirmMachineStart(
                context,
                machineName: cycle.machineName,
              )) {
                await cubit.start(cycle);
              }
            },
      onOpen: () => context.push(AppRoutes.myCycles),
      others: state.onHome.length - 1,
    );
  }
}

class _CycleBanner extends StatelessWidget {
  const _CycleBanner({
    required this.cycle,
    required this.starting,
    required this.onStart,
    required this.onOpen,
    required this.others,
  });

  final WashCycle cycle;
  final bool starting;
  final VoidCallback? onStart;
  final VoidCallback onOpen;

  /// Nombre de cycles NON montrés. Le bandeau n'en affiche qu'un ; taire les
  /// autres reviendrait à cacher au client qu'il a payé plusieurs machines.
  final int others;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceTint,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.primaryLight.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _title(cycle.state),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              _subtitle(),
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),

            if (others > 0) ...[
              const SizedBox(height: 4),
              Text(
                others == 1 ? '+ 1 autre lavage' : '+ $others autres lavages',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],

            // Le geste le plus urgent reste accessible sans ouvrir la liste :
            // c'est tout l'intérêt d'un bandeau sur l'accueil.
            if (cycle.state.needsAction) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: starting ? null : onStart,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: starting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(
                    starting
                        ? 'Démarrage…'
                        : cycle.state == CycleState.dryingToStart
                        ? 'Lancer le séchage'
                        : 'Démarrer la machine',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _title(CycleState state) => switch (state) {
    CycleState.toStart => 'Votre machine est prête',
    CycleState.failed => 'Le démarrage a échoué',
    CycleState.running => 'Lavage en cours',
    CycleState.dryingToStart => 'Lavage terminé',
    CycleState.finished => 'Lavage terminé',
  };

  String _subtitle() {
    final machine = [
      cycle.machineName,
      cycle.sizeKg != null ? '${cycle.sizeKg} kg' : null,
    ].whereType<String>().join(' · ');

    return switch (cycle.state) {
      CycleState.toStart =>
        'Chargez votre linge, puis démarrez${machine.isEmpty ? '' : ' — $machine'}.',
      CycleState.failed => 'Vérifiez que la machine est libre, puis réessayez.',
      // Le temps restant vient de la machine ; `null` tant qu'elle n'a pas été
      // relevée — afficher « 0 min » laisserait croire que c'est fini.
      CycleState.running =>
        cycle.remainingSeconds == null
            ? 'En cours$_machineSuffix'
            : 'Encore ${(cycle.remainingSeconds! / 60).ceil()} min$_machineSuffix',
      // Temps mort entre les deux temps : aucune machine ne tourne, et c'est
      // au client de lancer la seconde. Le dire, sinon il attend devant une
      // machine arrêtée.
      CycleState.dryingToStart =>
        'Il reste le séchage — sortez votre linge et lancez la sécheuse.',
      CycleState.finished => 'Récupérez votre linge$_machineSuffix.',
    };
  }

  String get _machineSuffix =>
      cycle.machineName == null ? '' : ' — ${cycle.machineName}';
}

/// Remise en attente : le linge part au comptoir, ce code l'y identifie.
class _HandoffCard extends StatelessWidget {
  const _HandoffCard({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Apportez votre linge au comptoir',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Présentez ce code à l\'agent pour la finition payée.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          Text(
            code,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
