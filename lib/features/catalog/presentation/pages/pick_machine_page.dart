import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/router/app_router.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/machines/presentation/bloc/machines_bloc.dart';
import 'package:fotdelsi/features/machines/presentation/bloc/machines_event.dart';
import 'package:fotdelsi/features/machines/presentation/bloc/machines_state.dart';
import 'package:fotdelsi/features/machines/presentation/widgets/machine_status_badge.dart';
import '../../domain/entities/service_formula.dart';

/// Choix de la machine pour une prestation déjà sélectionnée.
///
/// Seules les machines du type attendu par la formule sont proposées : lancer
/// un lavage sur une sécheuse serait de toute façon refusé au paiement.
/// Le prix affiché est celui de la grille pour la capacité de chaque machine.
class PickMachinePage extends StatelessWidget {
  const PickMachinePage({super.key, required this.formula});

  final ServiceFormula formula;

  @override
  Widget build(BuildContext context) {
    // Bloc partagé : `.value` pour ne pas le fermer en quittant la page.
    // L'abonnement est déjà actif si l'accueil l'a demandé — le réémettre ne
    // recrée pas de connexion, il rafraîchit la liste.
    return BlocProvider.value(
      value: serviceLocator<MachinesBloc>()
        ..add(const MachinesSubscriptionRequested()),
      child: _PickMachineView(formula: formula),
    );
  }
}

class _PickMachineView extends StatelessWidget {
  const _PickMachineView({required this.formula});

  final ServiceFormula formula;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(formula.label),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<MachinesBloc, MachinesState>(
          builder: (context, state) => switch (state.status) {
            MachinesStatus.initial || MachinesStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            MachinesStatus.failure => _Message(
              text: 'Impossible de charger les machines.',
              onRetry: () => context.read<MachinesBloc>().add(
                const MachinesSubscriptionRequested(),
              ),
            ),
            MachinesStatus.success => _list(context, state.machines),
          },
        ),
      ),
    );
  }

  Widget _list(BuildContext context, List<Machine> machines) {
    final wanted = formula.needsWasher ? MachineType.washer : MachineType.dryer;

    // Une machine dont la capacité n'est pas tarifée pour cette formule n'est
    // pas vendable : mieux vaut ne pas la montrer que d'afficher « — ».
    final eligible =
        machines
            .where(
              (m) =>
                  m.type == wanted &&
                  m.size != null &&
                  formula.priceFor(m.size!) != null,
            )
            .toList()
          ..sort((a, b) => a.size!.compareTo(b.size!));

    if (eligible.isEmpty) {
      return const _Message(
        text: 'Aucune machine ne propose cette prestation pour le moment.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: eligible.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == 0) {
          return const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text(
              'Choisissez votre machine',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          );
        }

        final machine = eligible[index - 1];
        return _MachineTile(
          machine: machine,
          price: formula.priceFor(machine.size!)!,
          onTap: machine.status == MachineStatus.available
              ? () {
                  final PaymentArgs args = (formula: formula, machine: machine);
                  context.push(AppRoutes.payment, extra: args);
                }
              : null,
        );
      },
    );
  }
}

class _MachineTile extends StatelessWidget {
  const _MachineTile({
    required this.machine,
    required this.price,
    required this.onTap,
  });

  final Machine machine;
  final int price;

  /// `null` quand la machine n'est pas disponible — la tuile reste visible
  /// (le client voit l'offre complète) mais n'est pas cliquable.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${machine.size} kg',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      MachineStatusBadge(status: machine.status),
                    ],
                  ),
                ),
                Text(
                  formatFcfa(price),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                if (enabled)
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

class _Message extends StatelessWidget {
  const _Message({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(onPressed: onRetry, child: const Text('Réessayer')),
            ],
          ],
        ),
      ),
    );
  }
}
