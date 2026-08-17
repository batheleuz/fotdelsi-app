import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/motion/entrance.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import '../../domain/entities/wash_cycle.dart';
import '../cubit/wash_cycles_cubit.dart';
import '../widgets/pick_dryer_sheet.dart';

// ─────────────────────────── Durées ────────────────────────────────────────
// Fonctions de fichier plutôt que méthodes statiques d'une carte : les trois
// cartes en ont besoin, et l'une d'elles allait chercher les helpers privés
// d'une autre — ça compilait, mais ça n'avait aucun sens.

/// « 07:12 », « 1:03:40 ». Chiffres à chasse fixe côté style pour que
/// l'affichage ne tressaute pas à chaque seconde.
String _clock(Duration d) {
  final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
}

/// « 42 min », « 1 h 12 min » — pour une durée déjà close, où la seconde
/// n'apporte rien.
String _roughDuration(Duration d) => d.inHours > 0
    ? '${d.inHours} h ${d.inMinutes.remainder(60)} min'
    : '${d.inMinutes} min';

/// « il y a 12 min », « il y a 3 j ». L'ancienneté dit à quel point une
/// commande a été oubliée — elle compte plus que l'heure exacte.
String _since(DateTime moment) {
  final d = DateTime.now().difference(moment);
  if (d.inMinutes < 60) return 'il y a ${d.inMinutes} min';
  if (d.inHours < 24) return 'il y a ${d.inHours} h';
  return 'il y a ${d.inDays} j';
}

/// Les trois regroupements d'un écran de cycles.
///
/// Publique parce que [CyclesLayout] en expose l'ordre.
enum CycleSection { toStart, running, finished }

/// Ce que l'écran est pour celui qui le regarde.
///
/// Les deux surfaces montrent les mêmes cycles avec les mêmes cartes, mais
/// pas dans le même ordre — parce qu'on n'y vient pas pour la même raison.
enum CyclesLayout {
  /// Espace agent : une file de travail.
  ///
  /// Ce qui réclame un geste passe en tête. Un cycle payé dont la machine
  /// n'est pas lancée, c'est de l'argent encaissé sans contrepartie : il doit
  /// sauter aux yeux avant tout le reste.
  worklist(
    order: [CycleSection.toStart, CycleSection.running, CycleSection.finished],
    finishedLabel: 'Terminés (24 h)',
  ),

  /// Espace client : son historique de lavages.
  ///
  /// Ce qui tourne en ce moment passe en tête — c'est la question qu'on se
  /// pose en ouvrant l'écran. Le reste, terminé ou encore à lancer, vient
  /// ensuite. Rien n'y est borné dans le temps : un lavage payé la semaine
  /// dernière lui appartient toujours.
  history(
    order: [CycleSection.running, CycleSection.toStart, CycleSection.finished],
    finishedLabel: 'Terminés',
  );

  const CyclesLayout({required this.order, required this.finishedLabel});

  final List<CycleSection> order;
  final String finishedLabel;
}

/// Une section : son titre, puis ses cartes en cascade. Vide si aucun cycle —
/// un intitulé sans contenu n'apprend rien.
List<Widget> _cycleSection(
  BuildContext context, {
  required String label,
  required List<WashCycle> cycles,
  required Widget Function(WashCycle) build,
  double gap = 10,
}) {
  if (cycles.isEmpty) return const [];

  return [
    _SectionLabel(label),
    const SizedBox(height: AppSpacing.sm),
    for (final (i, cycle) in cycles.indexed)
      EntranceFade(
        key: ValueKey(cycle.token),
        index: i,
        child: Padding(
          padding: EdgeInsets.only(bottom: gap),
          child: build(cycle),
        ),
      ),
    const SizedBox(height: AppSpacing.md),
  ];
}

/// Suivi des cycles : à démarrer, en cours, terminés.
///
/// Une seule page pour l'agent et pour le client : ce qu'on montre d'un cycle
/// — machine, prestation, temps restant, temps écoulé — est identique des deux
/// côtés. Seuls le périmètre (porté par le cubit) et le texte d'explication
/// changent. Deux pages jumelles auraient fini par diverger.
class WashCyclesPage extends StatelessWidget {
  const WashCyclesPage({
    super.key,
    required this.createCubit,
    required this.explanation,
    required this.layout,
    this.title = 'Mes cycles',
  });

  /// Fournit le cubit — c'est lui qui décide du périmètre.
  final WashCyclesCubit Function() createCubit;

  /// Ce que l'utilisateur doit comprendre de cette liste. Le mot juste n'est
  /// pas le même pour un agent et pour un client.
  final String explanation;

  /// Décide de l'ordre des sections et du libellé des cycles terminés.
  final CyclesLayout layout;
  final String title;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WashCyclesCubit>(
      create: (_) => createCubit()
        ..load()
        ..startTicking(),
      child: _WashCyclesView(
        title: title,
        explanation: explanation,
        layout: layout,
      ),
    );
  }
}

class _WashCyclesView extends StatelessWidget {
  const _WashCyclesView({
    required this.title,
    required this.explanation,
    required this.layout,
  });

  final String title;
  final String explanation;
  final CyclesLayout layout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(title),
      ),
      body: SafeArea(
        top: false,
        child: BlocConsumer<WashCyclesCubit, WashCyclesState>(
          listenWhen: (p, c) => p.error != c.error && c.error != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.error!),
                  backgroundColor: AppColors.danger,
                ),
              );
          },
          builder: (context, state) {
            if (state.status == WashCyclesStatus.loading ||
                state.status == WashCyclesStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == WashCyclesStatus.failure) {
              return _Message(
                icon: Icons.cloud_off_rounded,
                title: 'Chargement impossible',
                body: state.error ?? 'Vérifiez votre connexion.',
                onRetry: () => context.read<WashCyclesCubit>().load(),
              );
            }

            final toStart = state.toStart;
            final running = state.running;
            final finished = state.finished;

            return RefreshIndicator(
              onRefresh: () => context.read<WashCyclesCubit>().refresh(),
              child: state.isEmpty
                  ? const _Empty()
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.xl,
                      ),
                      children: [
                        _Explanation(text: explanation),
                        const SizedBox(height: AppSpacing.md),
                        // L'ordre des sections dépend de l'écran : voir
                        // [CyclesLayout]. Les sections elles-mêmes sont
                        // identiques des deux côtés.
                        for (final section in layout.order)
                          ...switch (section) {
                            CycleSection.toStart => _cycleSection(
                              context,
                              label: 'À démarrer',
                              cycles: toStart,
                              // Le second temps d'un cycle avec séchage n'est
                              // pas un démarrage comme les autres : il faut
                              // désigner une sécheuse, pas relancer la laveuse.
                              build: (cycle) =>
                                  cycle.state == CycleState.dryingToStart
                                  ? _DryingToStartCard(
                                      cycle: cycle,
                                      starting:
                                          state.startingToken == cycle.token,
                                      onPick: state.startingToken == null
                                          ? () => showPickDryerSheet(
                                              context,
                                              cycle,
                                              cycles: context
                                                  .read<WashCyclesCubit>(),
                                            )
                                          : null,
                                    )
                                  : _ToStartCard(
                                      cycle: cycle,
                                      starting:
                                          state.startingToken == cycle.token,
                                      // Aucun démarrage ne part tant qu'un autre est
                                      // en cours : deux machines lancées par erreur
                                      // coûteraient bien plus qu'une attente.
                                      //
                                      // `WashCyclesCubit` et non un sous-type : le
                                      // provider est déclaré sur le type de base pour
                                      // servir l'agent comme le client. Demander
                                      // `CounterSaleCyclesCubit` levait un
                                      // ProviderNotFoundException dans le callback —
                                      // avalé par Flutter, donc un bouton qui ne
                                      // faisait simplement rien.
                                      onStart: state.startingToken == null
                                          ? () => context
                                                .read<WashCyclesCubit>()
                                                .start(cycle)
                                          : null,
                                    ),
                            ),
                            CycleSection.running => _cycleSection(
                              context,
                              label: 'En cours',
                              cycles: running,
                              build: (cycle) => _RunningCard(cycle: cycle),
                            ),
                            CycleSection.finished => _cycleSection(
                              context,
                              label: layout.finishedLabel,
                              cycles: finished,
                              build: (cycle) => _FinishedCard(cycle: cycle),
                              gap: 8,
                            ),
                          },
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: AppColors.textSecondary,
    ),
  );
}

/// Libellé « machine · capacité », vide si rien n'est connu.
String _machineLine(WashCycle cycle) => [
  cycle.machineName,
  cycle.sizeKg != null ? '${cycle.sizeKg} kg' : null,
].whereType<String>().join(' · ');

/// Cycle payé dont la machine n'a pas encore tourné.
/// Temps mort entre lavage et séchage : le linge est prêt à passer en sécheuse.
///
/// Une carte à part et non une variante de [_ToStartCard] : le geste n'est pas
/// le même. Là, on relance une machine connue ; ici, on en choisit une.
class _DryingToStartCard extends StatelessWidget {
  const _DryingToStartCard({
    required this.cycle,
    required this.starting,
    required this.onPick,
  });

  final WashCycle cycle;
  final bool starting;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    final since = cycle.washCompletedAt;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.secondary, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColors.secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Lavage terminé',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (since != null)
                Text(
                  _since(since),
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textTertiary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Il reste le séchage, déjà payé. Sortez votre linge de '
            '${cycle.machineName ?? 'la laveuse'}, puis choisissez une '
            'sécheuse.',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: starting ? null : onPick,
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
                  : const Icon(Icons.dry_cleaning_rounded),
              label: Text(starting ? 'Démarrage…' : 'Lancer le séchage'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToStartCard extends StatelessWidget {
  const _ToStartCard({
    required this.cycle,
    required this.starting,
    required this.onStart,
  });

  final WashCycle cycle;
  final bool starting;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final refused = cycle.state == CycleState.failed;
    final machine = _machineLine(cycle);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: refused ? AppColors.danger : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cycle.formulaLabel ?? 'Cycle payé',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (machine.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        machine,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                formatFcfa(cycle.amount),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            [
              if (cycle.customerName != null) cycle.customerName!,
              // Le vendeur compte pour les relèves : la vente d'un collègue
              // parti reste à lancer, et il faut savoir de qui elle vient.
              if (cycle.soldByAgentName != null)
                'vendu par ${cycle.soldByAgentName}',
              _since(cycle.paidAt),
            ].join(' · '),
            style: const TextStyle(
              fontSize: 11.5,
              color: AppColors.textTertiary,
            ),
          ),

          // Un démarrage déjà refusé n'appelle pas le même geste : il faut
          // d'abord aller voir la machine.
          if (refused) ...[
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 15,
                  color: AppColors.danger,
                ),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Le démarrage a déjà échoué. Vérifiez que la machine est '
                    'disponible avant de réessayer.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.35,
                      color: AppColors.danger,
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: starting ? null : onStart,
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
                    : (refused
                          ? 'Réessayer le démarrage'
                          : 'Démarrer la machine'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Cycle en cours : la machine tourne, l'agent suit.
///
/// Deux durées, parce qu'elles ne répondent pas à la même question. Le temps
/// ÉCOULÉ se calcule ici, à la seconde, depuis l'instant de démarrage. Le
/// temps RESTANT vient de la machine — c'est elle qui sait combien dure
/// vraiment son cycle ; on le réaffiche sans jamais l'interpoler.
class _RunningCard extends StatelessWidget {
  const _RunningCard({required this.cycle});

  final WashCycle cycle;

  @override
  Widget build(BuildContext context) {
    final machine = _machineLine(cycle);
    final elapsed = cycle.elapsed;
    final remaining = cycle.remainingSeconds;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primaryLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.local_laundry_service_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cycle.formulaLabel ?? 'Cycle en cours',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (cycle.customerName != null)
                Text(
                  cycle.customerName!,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
          if (machine.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              machine,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],

          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _DurationBlock(
                  label: 'Restant',
                  // `null` tant que la machine n'a pas encore été relevée :
                  // afficher « 00:00 » laisserait croire que c'est fini.
                  value: remaining == null
                      ? '—'
                      : _clock(Duration(seconds: remaining)),
                  strong: true,
                ),
              ),
              Expanded(
                child: _DurationBlock(
                  label: 'Écoulé',
                  value: elapsed == null ? '—' : _clock(elapsed),
                ),
              ),
            ],
          ),

          if (remaining != null) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: _progress(elapsed, remaining),
                minHeight: 5,
                backgroundColor: AppColors.surfaceTint,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Part accomplie du cycle. Déduite d'écoulé et restant plutôt que d'une
  /// durée totale : celle-ci n'est jamais annoncée par la machine.
  static double? _progress(Duration? elapsed, int remaining) {
    if (elapsed == null) return null;
    final total = elapsed.inSeconds + remaining;
    if (total <= 0) return null;
    return (elapsed.inSeconds / total).clamp(0.0, 1.0);
  }
}

/// Cycle terminé, conservé 24 h.
///
/// Volontairement discret : ce n'est plus une tâche, c'est une trace. Elle
/// porte la durée totale et le moment de la fin — de quoi répondre à un client
/// qui demande si son linge est prêt.
class _FinishedCard extends StatelessWidget {
  const _FinishedCard({required this.cycle});

  final WashCycle cycle;

  @override
  Widget build(BuildContext context) {
    final total = cycle.elapsed;
    final remise = cycle.handoffCode;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                size: 18,
                color: AppColors.success,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      [
                        cycle.formulaLabel ?? 'Cycle',
                        if (cycle.customerName != null) cycle.customerName!,
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (cycle.machineName != null) cycle.machineName!,
                        if (total != null) 'durée ${_roughDuration(total)}',
                        if (cycle.endedAt != null)
                          'fini ${_since(cycle.endedAt!)}',
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // La finition achetée n'est pas rendue tant que le linge n'est pas
          // passé au comptoir. Le code apparaît ICI, à la fin du cycle : c'est
          // le seul moment où le client peut réellement l'apporter, et le seul
          // écran où il retrouve la commande concernée.
          if (remise != null) ...[
            const SizedBox(height: 10),
            _HandoffStrip(code: remise),
          ],
        ],
      ),
    );
  }
}

/// Consigne de remise, sur un cycle terminé qui comporte une finition.
class _HandoffStrip extends StatelessWidget {
  const _HandoffStrip({required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.storefront_rounded,
            size: 17,
            color: AppColors.secondary,
          ),
          const SizedBox(width: 9),
          const Expanded(
            child: Text(
              'Apportez votre linge au comptoir',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              code,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DurationBlock extends StatelessWidget {
  const _DurationBlock({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: strong ? 22 : 18,
            fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
            // Chasse fixe : sans elle, la largeur des chiffres change et le
            // compteur tressaute à chaque seconde.
            fontFeatures: const [FontFeature.tabularFigures()],
            color: strong ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

/// Dit à l'agent ce qu'il regarde : ces cycles ne sont dans aucune autre liste.
class _Explanation extends StatelessWidget {
  const _Explanation({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    // Scrollable malgré tout : sinon le pull-to-refresh ne fonctionne pas.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.24),
        const Icon(
          Icons.check_circle_outline_rounded,
          size: 44,
          color: AppColors.success,
        ),
        const SizedBox(height: 12),
        const Text(
          'Aucun cycle',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Text(
            'Vos ventes lancées apparaîtront ici jusqu\'à la fin du cycle.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    required this.onRetry,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: AppColors.textTertiary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
