import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/motion/entrance.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import '../../domain/entities/wash_cycle.dart';
import '../cubit/direct_cycles_history_cubit.dart';
import '../cubit/direct_cycles_history_state.dart';

/// Historique complet des Cycles Directs (ventes au comptoir).
class DirectCyclesHistoryPage extends StatelessWidget {
  const DirectCyclesHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => serviceLocator<DirectCyclesHistoryCubit>()..load(),
      child: const _DirectCyclesHistoryView(),
    );
  }
}

class _DirectCyclesHistoryView extends StatefulWidget {
  const _DirectCyclesHistoryView();

  @override
  State<_DirectCyclesHistoryView> createState() => _DirectCyclesHistoryViewState();
}

class _DirectCyclesHistoryViewState extends State<_DirectCyclesHistoryView> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FC),
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Historique Cycles Directs'),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Barre de recherche
            Container(
              color: AppColors.background,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) =>
                    context.read<DirectCyclesHistoryCubit>().updateSearch(val),
                decoration: InputDecoration(
                  hintText: 'Rechercher un client, numéro, machine…',
                  hintStyle: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textTertiary,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context
                                .read<DirectCyclesHistoryCubit>()
                                .updateSearch('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: const Color(0xFFF0F4F9),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Liste
            Expanded(
              child: BlocBuilder<DirectCyclesHistoryCubit, DirectCyclesHistoryState>(
                builder: (context, state) {
                  if (state.status == DirectCyclesHistoryStatus.loading ||
                      state.status == DirectCyclesHistoryStatus.initial) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state.status == DirectCyclesHistoryStatus.failure) {
                    return _HistoryMessage(
                      icon: Icons.cloud_off_rounded,
                      title: 'Chargement impossible',
                      body: state.error ?? 'Vérifiez votre connexion.',
                      onRetry: () =>
                          context.read<DirectCyclesHistoryCubit>().load(),
                    );
                  }

                  final filtered = state.filteredCycles;

                  if (filtered.isEmpty) {
                    if (state.searchQuery.isNotEmpty) {
                      return const _HistoryMessage(
                        icon: Icons.search_off_rounded,
                        title: 'Aucun résultat',
                        body: 'Aucun cycle direct ne correspond à votre recherche.',
                      );
                    }
                    return const _HistoryMessage(
                      icon: Icons.inbox_rounded,
                      title: 'Aucun Cycle Direct',
                      body: 'Les cycles directs enregistrés apparaîtront ici.',
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () =>
                        context.read<DirectCyclesHistoryCubit>().load(),
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final cycle = filtered[index];
                        return EntranceFade(
                          key: ValueKey(cycle.token),
                          index: index,
                          child: _CycleHistoryCard(cycle: cycle),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CycleHistoryCard extends StatelessWidget {
  const _CycleHistoryCard({required this.cycle});

  final WashCycle cycle;

  /// `jj/mm/aaaa · hh:mm`, à la main.
  ///
  /// `intl` n'est pas une dépendance du projet, et l'ajouter pour un seul
  /// horodatage coûterait plus que ces quatre lignes — le paquet tire les
  /// données de locale de toutes les langues.
  static String _horodatage(DateTime d) {
    String d2(int n) => n.toString().padLeft(2, '0');
    return '${d2(d.day)}/${d2(d.month)}/${d.year} · ${d2(d.hour)}:${d2(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _horodatage(cycle.paidAt);

    return Container(
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  cycle.customerName?.isNotEmpty == true
                      ? cycle.customerName!
                      : 'Client au comptoir',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                formatFcfa(cycle.amount),
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (cycle.customerPhone?.isNotEmpty == true) ...[
                Text(
                  '+221 ${cycle.customerPhone}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('·', style: TextStyle(color: AppColors.textTertiary)),
                const SizedBox(width: 8),
              ],
              Text(
                cycle.machineName ?? 'Machine',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (cycle.formulaLabel != null) ...[
                const SizedBox(width: 6),
                Text(
                  '(${cycle.formulaLabel})',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatusBadge(state: cycle.state),
              const Spacer(),
              Text(
                formattedDate,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          if (cycle.soldByAgentName?.isNotEmpty == true) ...[
            const SizedBox(height: 6),
            Text(
              'Encaissé par : ${cycle.soldByAgentName}',
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textTertiary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state});

  final CycleState state;

  @override
  Widget build(BuildContext context) {
    // Les cinq états réels de `CycleState`. Un `switch` exhaustif, sans cas
    // « inconnu » : le compilateur refusera de passer si le domaine en gagne
    // un sixième, plutôt que de l'afficher comme une anomalie.
    final (label, color, bg) = switch (state) {
      CycleState.toStart => (
        'À démarrer',
        const Color(0xFF8A6100),
        const Color(0xFFFFF5E0),
      ),
      CycleState.failed => (
        'Démarrage refusé',
        AppColors.danger,
        const Color(0xFFFDECEC),
      ),
      CycleState.running => (
        'En cours',
        AppColors.primary,
        AppColors.surfaceTint,
      ),
      CycleState.dryingToStart => (
        'Séchage à lancer',
        const Color(0xFF8A6100),
        const Color(0xFFFFF5E0),
      ),
      CycleState.finished => (
        'Terminé',
        AppColors.success,
        const Color(0xFFE8F5E9),
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _HistoryMessage extends StatelessWidget {
  const _HistoryMessage({
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
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: AppColors.textTertiary),
            const SizedBox(height: 12),
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
                color: AppColors.textSecondary,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
