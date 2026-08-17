import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/agent_queue.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/drop_off.dart';
import 'package:fotdelsi/features/dropoffs/domain/entities/drop_off_status.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/drop_off_queue_cubit.dart';
import 'package:fotdelsi/features/dropoffs/presentation/utils/drop_off_status_presentation.dart';
import 'package:fotdelsi/features/dropoffs/presentation/widgets/drop_off_queue_card.dart';

/// La file d'attente du jour, groupée en À lancer / En cours / À remettre.
///
/// Écran de travail, pas point d'entrée : l'agent y revient sans cesse pendant
/// son service. La déconnexion vit sur l'accueil agent — ici, elle était à un
/// doigt des actions de traitement, pour un geste qu'on fait une fois par jour.
class DropOffQueuePage extends StatelessWidget {
  const DropOffQueuePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<DropOffQueueCubit>()
        ..load()
        ..startRealtime(),
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
      context.read<DropOffQueueCubit>().refresh();
    }
  }

  void _soon(String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label — bientôt disponible')));
  }

  Future<void> _openDetail(String id) async {
    await context.push(AppRoutes.agentDropOffDetail(id));
    if (mounted) context.read<DropOffQueueCubit>().refresh();
  }

  /// Pull-to-refresh : recharge la file et, en cas d'échec, le signale
  /// clairement au lieu de laisser croire que tout est à jour.
  Future<void> _pullToRefresh(BuildContext context) async {
    final ok = await context.read<DropOffQueueCubit>().refresh();
    if (!ok && context.mounted) {
      final message =
          context.read<DropOffQueueCubit>().state.error ??
          'Mise à jour impossible. Vérifiez votre connexion.';
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(message)));
    }
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
        title: BlocBuilder<DropOffQueueCubit, DropOffQueueState>(
          builder: (context, state) {
            final total = state.queue?.total ?? 0;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'File d\'attente',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$total dépôt${total > 1 ? 's' : ''}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
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
        ],
      ),
      body: SafeArea(
        top: false,
        child: BlocBuilder<DropOffQueueCubit, DropOffQueueState>(
          builder: (context, state) => _body(context, state),
        ),
      ),
      // Seul le dépôt reste ici : c'est l'action qu'un agent déclenche sans
      // quitter sa file, quand un client se présente pendant qu'il travaille.
      // La vente au comptoir part du hub — c'est un autre parcours, avec son
      // propre point d'entrée.
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau dépôt'),
        onPressed: () async {
          await context.push(AppRoutes.agentNewDropOff);
          if (context.mounted) context.read<DropOffQueueCubit>().refresh();
        },
      ),
    );
  }

  Widget _body(BuildContext context, DropOffQueueState state) {
    if (state.status == DropOffQueueStatus.loading ||
        state.status == DropOffQueueStatus.initial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.status == DropOffQueueStatus.failure && state.queue == null) {
      return _ErrorView(
        message: state.error ?? 'Chargement impossible.',
        onRetry: () => context.read<DropOffQueueCubit>().load(),
      );
    }

    final queue = state.queue;
    return RefreshIndicator(
      onRefresh: () => _pullToRefresh(context),
      child: (queue == null || queue.isEmpty)
          ? _emptyList()
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.sm,
                AppSpacing.md,
                96,
              ),
              children: [
                for (final day in _daysDescending(queue))
                  ..._daySection(day, queue),
              ],
            ),
    );
  }

  List<String> _daysDescending(AgentQueue queue) {
    final days = <String>{
      for (final d in queue.received) d.creationDay,
      for (final d in queue.inProgress) d.creationDay,
      for (final d in queue.ready) d.creationDay,
    };
    return days.toList()..sort((a, b) => b.compareTo(a));
  }

  List<Widget> _daySection(String day, AgentQueue queue) {
    List<DropOff> onDay(List<DropOff> items) =>
        items.where((d) => d.creationDay == day).toList();

    final received = onDay(queue.received);
    final inProgress = onDay(queue.inProgress);
    final ready = onDay(queue.ready);
    final count = received.length + inProgress.length + ready.length;

    return [
      _dayHeader(_dayLabel(day), count),
      _section('À lancer', received, DropOffStatus.received),
      _section('En cours', inProgress, DropOffStatus.inProgress),
      _section('À remettre', ready, DropOffStatus.ready),
    ];
  }

  Widget _dayHeader(String label, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, AppSpacing.lg, 2, 0),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$count dépôt${count > 1 ? 's' : ''}',
            style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  String _iso(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  String _dayLabel(String isoDay) {
    if (isoDay.isEmpty) return 'Date inconnue';
    final now = DateTime.now();
    if (isoDay == _iso(now)) return "Aujourd'hui";
    if (isoDay == _iso(now.subtract(const Duration(days: 1)))) return 'Hier';

    final parts = isoDay.split('-');
    if (parts.length == 3) {
      final year = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final day = int.tryParse(parts[2]);
      bool dateValid =
          year != null &&
          month != null &&
          day != null &&
          month >= 1 &&
          month <= 12;

      if (dateValid) {
        const months = [
          'janvier',
          'février',
          'mars',
          'avril',
          'mai',
          'juin',
          'juillet',
          'août',
          'septembre',
          'octobre',
          'novembre',
          'décembre',
        ];
        return '$day ${months[month - 1]} $year';
      }
    }
    return isoDay;
  }

  Widget _section(String title, List<DropOff> items, DropOffStatus status) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            2,
            AppSpacing.md,
            2,
            AppSpacing.sm,
          ),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
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
        ...items.map(
          (d) => DropOffQueueCard(
            dropOff: d,
            onTap: () => _openDetail(d.id),
            onAction: () => _openDetail(d.id),
          ),
        ),
      ],
    );
  }

  Widget _emptyList() => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    children: [
      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
      const Icon(Icons.inbox_outlined, size: 48, color: AppColors.textTertiary),
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
            const Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
