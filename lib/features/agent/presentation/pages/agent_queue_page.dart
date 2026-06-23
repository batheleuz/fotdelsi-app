import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/drop_off.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/drop_off_status.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/agent_queue_cubit.dart';
import 'package:fotdelsi/features/dropoffs/presentation/utils/drop_off_status_presentation.dart';
import 'package:fotdelsi/features/dropoffs/presentation/widgets/drop_off_queue_card.dart';

/// Écran principal de l'agent : la file d'attente du jour, groupée en
/// À lancer / En cours / À remettre.
class AgentQueuePage extends StatelessWidget {
  const AgentQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          serviceLocator<AgentQueueCubit>()..load()..startPolling(),
      child: const _AgentQueueView(),
    );
  }
}

class _AgentQueueView extends StatefulWidget {
  const _AgentQueueView();

  @override
  State<_AgentQueueView> createState() => _AgentQueueViewState();
}

class _AgentQueueViewState extends State<_AgentQueueView>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<AgentQueueCubit>().refresh();
    }
  }

  void _soon(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label — bientôt disponible')));
  }

  Future<void> _openDetail(String id) async {
    await context.push(AppRoutes.agentDropOffDetail(id));
    if (mounted) context.read<AgentQueueCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        titleSpacing: AppSpacing.md,
        title: BlocBuilder<AgentQueueCubit, AgentQueueState>(
          builder: (context, state) {
            final total = state.queue?.total ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('File d\'attente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                Text(
                  'Aujourd\'hui · $total dépôt${total > 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.push(AppRoutes.agentSearch),
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined),
            onPressed: () => _soon('Choix du jour'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: () => context.read<AuthCubit>().logout(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<AgentQueueCubit, AgentQueueState>(
          builder: (context, state) => _body(context, state),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau dépôt'),
        onPressed: () async {
          await context.push(AppRoutes.agentNewDropOff);
          if (context.mounted) context.read<AgentQueueCubit>().refresh();
        },
      ),
    );
  }

  Widget _body(BuildContext context, AgentQueueState state) {
    if (state.status == AgentQueueStatus.loading ||
        state.status == AgentQueueStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == AgentQueueStatus.failure && state.queue == null) {
      return _ErrorView(
        message: state.error ?? 'Chargement impossible.',
        onRetry: () => context.read<AgentQueueCubit>().load(),
      );
    }

    final queue = state.queue;
    return RefreshIndicator(
      onRefresh: () => context.read<AgentQueueCubit>().refresh(),
      child: (queue == null || queue.isEmpty)
          ? _emptyList()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, 96),
              children: [
                _section('À lancer', queue.received, DropOffStatus.received),
                _section('En cours', queue.inProgress, DropOffStatus.inProgress),
                _section('À remettre', queue.ready, DropOffStatus.ready),
              ],
            ),
    );
  }

  Widget _section(String title, List<DropOff> items, DropOffStatus status) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, AppSpacing.md, 2, AppSpacing.sm),
          child: Row(
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                  color: status.textColor,
                ),
              ),
              const SizedBox(width: 7),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: BoxDecoration(
                  color: status.softColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${items.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: status.textColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        ...items.map((d) => DropOffQueueCard(
              dropOff: d,
              onTap: () => _openDetail(d.id),
              onAction: () => _openDetail(d.id),
            )),
      ],
    );
  }

  Widget _emptyList() => ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          const Icon(Icons.inbox_outlined,
              size: 48, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          const Center(
            child: Text(
              'Aucun dépôt pour le moment',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 44, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primaryLight),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
