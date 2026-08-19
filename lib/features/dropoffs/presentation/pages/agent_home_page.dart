import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/motion/entrance.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/widgets/app_confirmation_dialog.dart';
import 'package:fotdelsi/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_cycles_cubit.dart';
import '../cubit/agent_handoffs_cubit.dart';
import '../cubit/drop_off_queue_cubit.dart';
import '../cubit/pending_payments_cubit.dart';

/// Point d'entrée de l'espace agent.
///
/// La file d'attente n'est plus imposée à l'arrivée : depuis que l'agent peut
/// aussi vendre un cycle au comptoir, elle est devenue une activité parmi
/// d'autres. On présente donc les actions d'abord, l'état du magasin ensuite.
class AgentHomePage extends StatelessWidget {
  const AgentHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Quatre chargements indépendants, parce que ces listes n'ont pas le même
    // rythme : la file se vide dans la journée, une remise peut attendre
    // plusieurs jours, un paiement se joue en quelques minutes. Aucune ne doit
    // retenir les autres — ni les faire disparaître en échouant.
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => serviceLocator<DropOffQueueCubit>()..load(),
        ),
        BlocProvider(
          create: (_) => serviceLocator<AgentHandoffsCubit>()..load(),
        ),
        BlocProvider(
          create: (_) => serviceLocator<CounterSaleCyclesCubit>()..load(),
        ),
        BlocProvider(
          create: (_) => serviceLocator<PendingPaymentsCubit>()
            ..load()
            // Temps réel : la confirmation du paiement crée le dépôt, ce qui
            // fait disparaître la ligne sans que l'agent touche à rien.
            ..startRealtime(),
        ),
      ],
      child: const _AgentHomeView(),
    );
  }
}

class _AgentHomeView extends StatelessWidget {
  const _AgentHomeView();

  @override
  Widget build(BuildContext context) {
    final name = context.select<AuthCubit, String?>((c) => c.state.user?.name);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => Future.wait([
            context.read<DropOffQueueCubit>().refresh(),
            context.read<AgentHandoffsCubit>().refresh(),
            context.read<CounterSaleCyclesCubit>().refresh(),
            context.read<PendingPaymentsCubit>().refresh(),
          ]),
          child: BlocBuilder<DropOffQueueCubit, DropOffQueueState>(
            builder: (context, state) {
              final queue = state.queue;

              return ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xl,
                ),
                // Entrée en cascade à l'ouverture. L'agent arrive ici entre
                // deux clients : la page se pose au lieu de s'imposer d'un
                // bloc, et le regard suit l'ordre des actions.
                children: [
                  EntranceFade(child: _Header(name: name)),
                  const SizedBox(height: AppSpacing.lg),

                  const EntranceFade(
                    index: 1,
                    child: _SectionLabel('Que voulez-vous faire ?'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  EntranceFade(
                    index: 2,
                    child: _Action(
                      icon: Icons.qr_code_2_rounded,
                      accent: AppColors.secondary,
                      title: 'Vendre un cycle',
                      subtitle: 'Client sans l\'application',
                      onTap: () => context.push(AppRoutes.agentSale),
                    ),
                  ),
                  EntranceFade(
                    index: 3,
                    child: _Action(
                      icon: Icons.add_rounded,
                      title: 'Nouveau dépôt',
                      subtitle: 'Le client confie son linge',
                      onTap: () async {
                        await context.push(AppRoutes.agentNewDropOff);
                        if (context.mounted) {
                          context.read<DropOffQueueCubit>().refresh();
                          // Un dépôt qui vient d'être saisi attend son paiement :
                          // aucun événement serveur ne l'annonce, le dépôt
                          // n'existe pas encore.
                          context.read<PendingPaymentsCubit>().refresh();
                        }
                      },
                    ),
                  ),
                  EntranceFade(
                    index: 4,
                    child: _Action(
                      icon: Icons.search_rounded,
                      title: 'Rechercher un code',
                      subtitle: 'Retrait ou remise de linge',
                      onTap: () => context.push(AppRoutes.agentSearch),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  const EntranceFade(
                    index: 5,
                    child: _SectionLabel('En cours'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  EntranceFade(
                    index: 6,
                    child: _Action(
                      icon: Icons.list_alt_rounded,
                      title: 'File d\'attente',
                      subtitle: queue == null
                          ? 'Chargement…'
                          : _queueSummary(
                              queue.received.length + queue.inProgress.length,
                              queue.ready.length,
                            ),
                      badge: queue?.total,
                      onTap: () async {
                        await context.push(AppRoutes.agentQueue);
                        if (context.mounted) {
                          context.read<DropOffQueueCubit>().refresh();
                        }
                      },
                    ),
                  ),
                  // Linge au comptoir, argent pas encore encaissé : ces dépôts
                  // n'existent pas encore dans la file, qui ne liste que du payé.
                  const _PendingPaymentsAction(),
                  // Argent encaissé, machine jamais lancée : c'est le seul
                  // endroit qui rattrape une vente dont on a quitté l'écran.
                  const _CounterSaleCyclesAction(),

                  // Hors de « En cours », et c'est tout l'objet de cette
                  // section : rien n'y est en cours. Le linge est encore chez
                  // le client, aucune machine ne tourne, l'agent n'a rien à
                  // faire tant qu'il n'est pas passé. Rangée parmi son propre
                  // travail, cette entrée se lisait comme une consigne sur le
                  // dépôt qu'il venait de lancer — « à réceptionner » alors
                  // que c'est lui qui gère ce linge.
                  const _WaitingSection(),

                  const SizedBox(height: AppSpacing.lg),
                  const EntranceFade(
                    index: 7,
                    child: _SectionLabel('Consulter'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Toujours visible, sans compteur : la file ne montre que le
                  // jour et les statuts actifs, donc un dépôt rendu la veille
                  // n'était joignable nulle part. Un badge n'aurait aucun sens
                  // ici — rien n'y réclame de geste.
                  EntranceFade(
                    index: 8,
                    child: _Action(
                      icon: Icons.history_rounded,
                      title: 'Historique des dépôts',
                      subtitle: 'Tous les dépôts, avec le numéro du client',
                      onTap: () => context.push(AppRoutes.agentHistory),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static String _queueSummary(int aTraiter, int prets) {
    if (aTraiter == 0 && prets == 0) return 'Rien en attente';
    final parts = <String>[
      if (aTraiter > 0) '$aTraiter à traiter',
      if (prets > 0) '$prets prêt${prets > 1 ? 's' : ''}',
    ];
    return parts.join(' · ');
  }
}

/// Section « En attente du client », et son unique entrée.
///
/// Le libellé de section suit la visibilité de l'entrée : afficher un titre
/// au-dessus du vide donnerait une rubrique fantôme.
class _WaitingSection extends StatelessWidget {
  const _WaitingSection();

  @override
  Widget build(BuildContext context) {
    final count = context.select<AgentHandoffsCubit, int>((c) => c.state.count);

    return AnimatedReveal(
      visible: count > 0,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: AppSpacing.lg),
          _SectionLabel('En attente du client'),
          SizedBox(height: AppSpacing.sm),
          _HandoffsAction(),
        ],
      ),
    );
  }
}

/// Entrée « À réceptionner ».
///
/// Masquée avec sa section tant qu'il n'y a rien : ces commandes sont payées
/// mais leur linge est encore chez le client. On ne la montre que lorsqu'elle a
/// un sens — et on la masque aussi si le chargement échoue, plutôt que
/// d'annoncer un « 0 » qu'on ne sait pas vrai.
class _HandoffsAction extends StatelessWidget {
  const _HandoffsAction();

  @override
  Widget build(BuildContext context) {
    final count = context.select<AgentHandoffsCubit, int>((c) => c.state.count);

    return _Action(
      icon: Icons.schedule_rounded,
      accent: AppColors.secondary,
      title: 'À réceptionner',
      subtitle: count == 1
          ? '1 client doit apporter son linge'
          : '$count clients doivent apporter leur linge',
      badge: count,
      onTap: () async {
        await context.push(AppRoutes.agentHandoffs);
        if (context.mounted) {
          context.read<AgentHandoffsCubit>().refresh();
        }
      },
    );
  }
}

/// Entrée « En attente de paiement ».
///
/// Masquée quand il n'y a rien, comme les autres entrées conditionnelles : une
/// ligne « 0 » n'apprend rien et éloigne les actions utiles du pouce.
///
/// Le badge ne compte que ce qui réclame un geste — relancer un paiement
/// échoué, terminer une vente jamais lancée. Un client en train de payer n'est
/// pas une alerte : le compter en rouge apprendrait à l'agent à ignorer le
/// badge.
class _PendingPaymentsAction extends StatelessWidget {
  const _PendingPaymentsAction();

  @override
  Widget build(BuildContext context) {
    final count = context.select<PendingPaymentsCubit, int>(
      (c) => c.state.count,
    );
    final needingAction = context.select<PendingPaymentsCubit, int>(
      (c) => c.state.needingAction,
    );

    // La ligne part d'elle-même quand le client paie : le repli rend ce
    // moment lisible plutôt que brutal.
    return AnimatedReveal(
      visible: count > 0,
      child: _Action(
        icon: Icons.payments_outlined,
        accent: needingAction > 0 ? AppColors.danger : AppColors.secondary,
        title: 'En attente de paiement',
        subtitle: _subtitle(count, needingAction),
        badge: needingAction > 0 ? needingAction : null,
        onTap: () async {
          await context.push(AppRoutes.agentPendingPayments);
          if (context.mounted) {
            context.read<PendingPaymentsCubit>().refresh();
          }
        },
      ),
    );
  }

  static String _subtitle(int total, int needingAction) {
    final depots = total == 1 ? '1 dépôt' : '$total dépôts';
    if (needingAction == 0) return '$depots — le client doit payer';
    // « à reprendre » et non « à relancer » : le lot mélange des liens expirés,
    // des paiements refusés et des ventes jamais lancées.
    return needingAction == total
        ? '$depots à reprendre'
        : '$depots, dont $needingAction à reprendre';
  }
}

/// Entrée « Mes cycles ».
///
/// La visibilité dérive de `isEmpty`, et non d'une énumération d'états. Les
/// deux fois où cette entrée a disparu — d'abord pour les cycles en cours,
/// puis pour les terminés — c'était parce qu'un nouvel état avait été ajouté
/// sans être ajouté à la condition. Un état futur est désormais couvert
/// d'office.
///
/// Le compteur rouge, lui, ne porte que ce qui réclame un geste.
class _CounterSaleCyclesAction extends StatelessWidget {
  const _CounterSaleCyclesAction();

  @override
  Widget build(BuildContext context) {
    final isEmpty = context.select<CounterSaleCyclesCubit, bool>(
      (c) => c.state.isEmpty,
    );
    final toStart = context.select<CounterSaleCyclesCubit, int>(
      (c) => c.state.toStart.length,
    );
    final running = context.select<CounterSaleCyclesCubit, int>(
      (c) => c.state.running.length,
    );
    final finished = context.select<CounterSaleCyclesCubit, int>(
      (c) => c.state.finished.length,
    );

    // Un cycle qui se termine fait sortir l'entrée en douceur, au lieu de la
    // faire disparaître pendant que l'agent la regarde.
    return AnimatedReveal(
      visible: !isEmpty,
      child: _Action(
        icon: toStart > 0
            ? Icons.play_circle_outline_rounded
            : Icons.local_laundry_service_rounded,
        // Alerte uniquement s'il reste une machine à lancer : de l'argent est
        // encaissé sans contrepartie. Un cycle qui tourne, ou déjà fini, n'a
        // rien d'anormal.
        accent: toStart > 0 ? AppColors.danger : AppColors.primary,
        title: 'Mes cycles',
        subtitle: _summary(toStart, running, finished),
        badge: toStart,
        onTap: () async {
          await context.push(AppRoutes.agentCycles);
          if (context.mounted) {
            context.read<CounterSaleCyclesCubit>().refresh();
          }
        },
      ),
    );
  }

  static String _summary(int toStart, int running, int finished) {
    final parts = <String>[
      if (toStart > 0) toStart == 1 ? '1 à démarrer' : '$toStart à démarrer',
      if (running > 0) running == 1 ? '1 en cours' : '$running en cours',
      if (finished > 0) finished == 1 ? '1 terminé' : '$finished terminés',
    ];
    return parts.join(' · ');
  }
}

class _Header extends StatelessWidget {
  const _Header({this.name});
  final String? name;

  /// Quitter son service est un geste de fin de journée : sa place est ici,
  /// sur le seul écran où l'agent ne travaille pas — pas dans la file, à côté
  /// des actions qu'il enchaîne toute la journée.
  Future<void> _confirmLogout(BuildContext context) async {
    final ok = await showAppConfirmationDialog(
      context: context,
      title: 'Déconnexion agent ?',
      message:
          'Vous allez quitter l’espace agent. Vous devrez vous reconnecter pour reprendre votre service.',
      confirmLabel: 'Déconnecter',
      destructive: true,
    );
    if (!ok || !context.mounted) return;
    await context.read<AuthCubit>().logout();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name == null ? 'Bonjour' : 'Bonjour ${name!.split(' ').first}',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Espace agent',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          tooltip: 'Déconnexion',
          color: AppColors.textTertiary,
          onPressed: () => _confirmLogout(context),
        ),
      ],
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

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = AppColors.primary,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;

  /// Compteur affiché à droite — omis s'il vaut zéro, pour ne pas attirer
  /// l'œil sur une file vide.
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, size: 20, color: accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (badge != null && badge! > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${badge!}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: accent,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textTertiary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
