import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/motion/entrance.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../cubit/agent_handoffs_cubit.dart';
import '../widgets/drop_off_queue_card.dart';

/// Remises libre-service payées dont le linge n'est pas encore arrivé.
///
/// Ces commandes sont volontairement absentes de la file de travail : leur
/// linge est encore chez le client, l'agent n'a rien à en faire tant qu'il
/// n'est pas passé. Elles ont donc leur propre écran — une liste d'attente,
/// pas une liste de tâches.
///
/// L'agent y vient pour deux raisons : vérifier qui doit venir, et retrouver
/// une commande quand un client se présente avec son code.
class AgentHandoffsPage extends StatelessWidget {
  const AgentHandoffsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<AgentHandoffsCubit>()
        ..load()
        ..startRealtime(),
      child: const _HandoffsView(),
    );
  }
}

class _HandoffsView extends StatelessWidget {
  const _HandoffsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('À réceptionner'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Rechercher un code',
            onPressed: () => context.push(AppRoutes.agentSearch),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<AgentHandoffsCubit, AgentHandoffsState>(
          builder: (context, state) {
            if (state.status == AgentHandoffsStatus.loading ||
                state.status == AgentHandoffsStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == AgentHandoffsStatus.failure) {
              return _Error(
                message: state.error,
                onRetry: () => context.read<AgentHandoffsCubit>().load(),
              );
            }

            final attente = state.handoffs ?? const [];

            return RefreshIndicator(
              onRefresh: () => context.read<AgentHandoffsCubit>().refresh(),
              child: attente.isEmpty
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
                        const _Explanation(),
                        const SizedBox(height: AppSpacing.md),
                        for (final (i, dropOff) in attente.indexed)
                          EntranceFade(
                            key: ValueKey(dropOff.id),
                            index: i,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: DropOffQueueCard(
                                dropOff: dropOff,
                                onTap: () async {
                                  await context.push(
                                    AppRoutes.agentDropOffDetail(dropOff.id),
                                  );
                                  if (context.mounted) {
                                    context
                                        .read<AgentHandoffsCubit>()
                                        .refresh();
                                  }
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
            );
          },
        ),
      ),
    );
  }
}

/// Dit à l'agent ce qu'il regarde — ces commandes ne se comportent pas comme
/// les dépôts qu'il connaît.
class _Explanation extends StatelessWidget {
  const _Explanation();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Ces clients ont lavé leur linge eux-mêmes et payé une finition. '
              'Ouvrez la fiche pour la prendre en charge quand ils l\'apportent.',
              style: TextStyle(
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

class _Error extends StatelessWidget {
  const _Error({required this.onRetry, this.message});

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 40,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 12),
            Text(
              message ?? 'Impossible de charger les remises.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
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

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    // Liste scrollable malgré tout : sinon le pull-to-refresh ne fonctionne pas.
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.24),
        const Icon(
          Icons.inbox_outlined,
          size: 44,
          color: AppColors.textTertiary,
        ),
        const SizedBox(height: 12),
        const Text(
          'Aucun linge à réceptionner',
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
            'Les clients ayant payé une finition en libre-service '
            'apparaîtront ici.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}
