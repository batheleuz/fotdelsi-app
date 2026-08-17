import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/payment/presentation/widgets/session_countdown_ring.dart';
import '../../domain/entities/wash_cycle.dart';
import '../cubit/wash_cycles_cubit.dart';
import 'pick_dryer_sheet.dart';

/// Feuille de suivi d'un cycle, ouverte depuis l'accueil.
///
/// Elle lit le cubit des cycles — la même source que le bandeau et « Mes
/// lavages ». Elle s'adossait auparavant à `WashSessionCubit`, qui relit une
/// session stockée sur le téléphone : cette source ne bougeait qu'à la
/// réception d'un événement temps réel, sans battement propre. Le compteur
/// restait donc figé, et il pouvait décrire un cycle que le serveur ne
/// connaissait plus.
///
/// Le cycle est retrouvé par son JETON à chaque construction, jamais recopié :
/// c'est ce qui fait que le contenu suit les relevés au lieu de montrer l'état
/// qu'avait le cycle à l'ouverture.
///
/// ─── Elle suit le cycle entier, pas seulement le lavage ───
///
/// Elle se refermait dès que le lavage s'arrêtait. Sur une formule à deux
/// temps, c'est précisément l'instant où le client a besoin d'elle : le linge
/// est lavé, la sécheuse reste à lancer, et la feuille disparaissait sans rien
/// annoncer. Elle traverse maintenant les trois moments — lavage, temps mort,
/// séchage — et ne se retire que lorsque le cycle n'existe plus.
class WashRunningSheet extends StatelessWidget {
  const WashRunningSheet._({required this.token});

  final String token;

  /// [cycles] est passé, et non lu depuis [context].
  ///
  /// Les écrans exposent des sous-classes différentes (`MyCyclesCubit` côté
  /// client, `CounterSaleCyclesCubit` côté agent) et un `read` par type de base
  /// ne les trouve pas : l'exception part alors dans le gestionnaire de geste,
  /// où elle est avalée — la feuille ne s'ouvrirait pas, en silence.
  static void show(
    BuildContext context,
    WashCycle cycle, {
    required WashCyclesCubit cycles,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // `.value` : la feuille s'ouvre sur une autre branche de l'arbre.
      builder: (_) => BlocProvider<WashCyclesCubit>.value(
        value: cycles,
        child: WashRunningSheet._(token: cycle.token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WashCyclesCubit, WashCyclesState>(
      builder: (context, state) {
        final cycle = _find(state);

        // Le cycle a disparu de la liste — il n'y a plus rien à suivre, et un
        // contenu figé vaudrait moins que pas de feuille du tout.
        if (cycle == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).maybePop();
          });
          return const SizedBox.shrink();
        }

        return _Sheet(cycle: cycle);
      },
    );
  }

  WashCycle? _find(WashCyclesState state) {
    for (final cycle in state.cycles ?? const <WashCycle>[]) {
      if (cycle.token == token) return cycle;
    }
    return null;
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.cycle});

  final WashCycle cycle;

  @override
  Widget build(BuildContext context) {
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
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(99),
            ),
          ),

          Text(
            cycle.formulaLabel ?? 'Votre cycle',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          if (cycle.runningMachineName != null) ...[
            const SizedBox(height: 2),
            Text(
              cycle.runningMachineName!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          if (cycle.state == CycleState.running)
            _Countdown(cycle: cycle)
          else
            _Steps(cycle: cycle),
        ],
      ),
    );
  }
}

/// Compte à rebours du temps en cours — lavage ou séchage, indifféremment.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.cycle});

  final WashCycle cycle;

  @override
  Widget build(BuildContext context) {
    final remaining = cycle.remainingSeconds;
    final elapsed = cycle.elapsed;

    // Durée totale DÉDUITE d'écoulé + restant, jamais supposée : la machine
    // n'annonce que ce qu'il reste. La feuille affichait auparavant « 35 min »
    // en dur, quel que soit le cycle réellement payé.
    final total = (remaining != null && elapsed != null)
        ? elapsed.inSeconds + remaining
        : null;

    return Column(
      children: [
        // Sur une formule à deux temps, « en cours » ne suffit pas : le client
        // doit savoir lequel des deux tourne.
        if (cycle.withDrying)
          _Badge(
            label: cycle.isDrying ? 'Séchage en cours' : 'Lavage en cours',
            icon: cycle.isDrying
                ? Icons.dry_cleaning_rounded
                : Icons.local_laundry_service_rounded,
          ),
        if (cycle.withDrying) const SizedBox(height: AppSpacing.md),

        SessionCountdownRing(
          remaining: remaining,
          total: total ?? 0,
          size: 160,
        ),

        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Écoulé',
                // Seul compteur qui avance à la seconde, et le seul qui le
                // puisse : il se déduit de l'instant de démarrage, il est
                // exact par construction.
                value: elapsed == null ? '—' : _clock(elapsed),
              ),
            ),
            Expanded(
              child: _Stat(
                label: 'Durée totale',
                value: total == null ? '—' : '${(total / 60).ceil()} min',
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),
        const Text(
          'Le temps restant est celui annoncé par la machine : il avance par '
          'paliers, au rythme des relevés.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }
}

/// Le cycle ne tourne pas : on montre où il en est, temps par temps.
///
/// Deux cartes plutôt qu'une ligne de texte : ce qui est fait et ce qui reste
/// n'ont pas le même statut, et le geste attendu doit se voir du premier coup
/// d'œil.
class _Steps extends StatelessWidget {
  const _Steps({required this.cycle});

  final WashCycle cycle;

  @override
  Widget build(BuildContext context) {
    final aSecher = cycle.state == CycleState.dryingToStart;

    return Column(
      children: [
        _StepCard(
          done: true,
          icon: Icons.local_laundry_service_rounded,
          title: 'Lavage terminé',
          body: cycle.machineName == null
              ? 'Vous pouvez sortir votre linge.'
              : 'Votre linge est prêt dans ${cycle.machineName}.',
        ),

        if (aSecher) ...[
          const SizedBox(height: AppSpacing.sm),
          _StepCard(
            done: false,
            icon: Icons.dry_cleaning_rounded,
            title: 'Il reste le séchage',
            // Le rappeler ici évite la question qui vient toujours à cet
            // instant : « est-ce que je dois repayer ? »
            body: 'Déjà payé avec votre formule. Chargez votre linge dans une '
                'sécheuse, puis lancez-la.',
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => showPickDryerSheet(
                context,
                cycle,
                cycles: context.read<WashCyclesCubit>(),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Démarrer le séchage'),
            ),
          ),
        ] else ...[
          if (cycle.withDrying) ...[
            const SizedBox(height: AppSpacing.sm),
            const _StepCard(
              done: true,
              icon: Icons.dry_cleaning_rounded,
              title: 'Séchage terminé',
              body: 'Votre linge est sec.',
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: const Text('Fermer'),
            ),
          ),
        ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.done,
    required this.icon,
    required this.title,
    required this.body,
  });

  /// Étape franchie. Distingue ce qui est acquis de ce qui attend un geste.
  final bool done;
  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final accent = done ? AppColors.primary : AppColors.secondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: done ? AppColors.surfaceTint : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(done ? Icons.check_circle_rounded : icon, size: 20, color: accent),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.surfaceTint,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      ],
    ),
  );
}

String _clock(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        value,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        style: const TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
      ),
    ],
  );
}
