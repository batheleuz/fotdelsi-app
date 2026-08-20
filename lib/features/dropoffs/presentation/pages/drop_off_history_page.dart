import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/motion/entrance.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../../domain/entities/drop_off.dart';
import '../cubit/drop_off_history_cubit.dart';
import '../widgets/client_phone_row.dart';
import '../widgets/drop_off_status_badge.dart';

/// Historique complet des dépôts.
///
/// La file d'attente ne montre que le jour courant et les statuts actifs : un
/// dépôt rendu la veille en disparaît, et avec lui le numéro du client. Cet
/// écran existe pour les deux questions qui restent ensuite — « qu'est-ce qu'on
/// a fait ces jours-ci ? » et « comment je joins ce client ? ».
class DropOffHistoryPage extends StatelessWidget {
  const DropOffHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<DropOffHistoryCubit>()..load(),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatefulWidget {
  const _HistoryView();

  @override
  State<_HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<_HistoryView> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  /// Charge la suite AVANT d'atteindre le bas : arriver sur un vide puis
  /// attendre donne l'impression d'une liste finie.
  void _onScroll() {
    if (!_scroll.hasClients) return;

    final reste = _scroll.position.maxScrollExtent - _scroll.position.pixels;
    if (reste < 400) context.read<DropOffHistoryCubit>().loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Historique des dépôts'),
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
        child: BlocBuilder<DropOffHistoryCubit, DropOffHistoryState>(
          builder: (context, state) {
            if (state.status == DropOffHistoryStatus.loading ||
                state.status == DropOffHistoryStatus.initial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.status == DropOffHistoryStatus.failure) {
              return _Message(
                icon: Icons.cloud_off_rounded,
                title: 'Chargement impossible',
                body: state.error ?? 'Vérifiez votre connexion.',
                onRetry: () => context.read<DropOffHistoryCubit>().load(),
              );
            }

            if (state.isEmpty) {
              return const _Message(
                icon: Icons.inbox_rounded,
                title: 'Aucun dépôt',
                body: 'Les dépôts encaissés apparaîtront ici.',
              );
            }

            return RefreshIndicator(
              onRefresh: () => context.read<DropOffHistoryCubit>().load(),
              child: _Liste(state: state, controller: _scroll),
            );
          },
        ),
      ),
    );
  }
}

class _Liste extends StatelessWidget {
  const _Liste({required this.state, required this.controller});

  final DropOffHistoryState state;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final dropOffs = state.dropOffs!;

    return ListView.separated(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      itemCount: dropOffs.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == dropOffs.length) return _Pied(state: state);

        return EntranceFade(
          index: index,
          child: _HistoryCard(dropOff: dropOffs[index]),
        );
      },
    );
  }
}

/// Bas de liste : chargement, échec de page suivante, ou fin.
class _Pied extends StatelessWidget {
  const _Pied({required this.state});

  final DropOffHistoryState state;

  @override
  Widget build(BuildContext context) {
    if (state.loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Un échec de page SUIVANTE ne vide pas ce qui est déjà lu : les pages
    // précédentes restent justes, seule la suite manque.
    if (state.error != null) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg),
        child: Column(
          children: [
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: AppColors.danger),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => context.read<DropOffHistoryCubit>().loadMore(),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (state.hasMore) return const SizedBox(height: AppSpacing.lg);

    return const Padding(
      padding: EdgeInsets.only(top: AppSpacing.lg),
      child: Text(
        'Fin de l\'historique',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.dropOff});

  final DropOff dropOff;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => context.push(AppRoutes.agentDropOffDetail(dropOff.id)),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    dropOff.code,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      dropOff.customerName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  DropOffStatusBadge(status: dropOff.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  // Le geste que cet écran doit rendre possible : joindre le
                  // client pour convenir d'une remise.
                  ClientPhoneRow(phone: dropOff.contactPhone, dense: true),
                  const Spacer(),
                  Text(
                    _jour(dropOff),
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Date la plus parlante : quand le dépôt a été rendu, sinon quand il est
  /// passé en machine. C'est le repère qu'un agent a en tête quand il cherche.
  ///
  /// Repli sur `creationDay` et non sur `receivedAt` : ce dernier n'est pas
  /// renseigné pour une remise libre-service — le linge n'a jamais été reçu —
  /// et le modèle le remplace alors par l'instant présent. Chaque ligne
  /// afficherait la date du jour.
  String _jour(DropOff d) {
    final quand = d.collectedAt ?? d.readyAt ?? d.startedAt;
    if (quand == null) {
      final iso = d.creationDay.split('-');
      return iso.length == 3 ? '${iso[2]}/${iso[1]}' : d.creationDay;
    }

    final local = quand.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}';
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.body,
    this.onRetry,
  });

  final IconData icon;
  final String title;
  final String body;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: AppColors.textTertiary),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.lg),
            FilledButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ],
      ),
    ),
  );
}
