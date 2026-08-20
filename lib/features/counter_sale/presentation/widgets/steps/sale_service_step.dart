import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import '../../cubit/counter_sale_cubit.dart';
import '../sale_choice_tile.dart';

/// Étape 1 — ce qui est vendu : la prestation, puis la machine.
///
/// Le prix affiché vient de la grille tarifaire ; l'agent ne saisit jamais de
/// montant. La machine n'apparaît qu'une fois la prestation choisie, sans quoi
/// on ne saurait pas quelles machines conviennent ni à quel tarif.
class SaleServiceStep extends StatelessWidget {
  const SaleServiceStep({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CounterSaleCubit>();
    final state = context.watch<CounterSaleCubit>().state;
    final formula = state.selectedFormula;
    final machines = cubit.eligibleMachines;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        // La vente au comptoir reste un cycle libre-service : le linge du
        // client passera en machine, l'agent doit encore être là à la sortie.
        // C'est donc la même règle que dans l'app cliente, pas celle du dépôt.
        for (final f in state.formulas)
          SaleChoiceTile(
            title: f.label,
            subtitle: f.availability.selfService
                ? f.composition
                : (f.availability.message ?? f.composition),
            trailing: f.lowestPrice == null
                ? null
                : 'dès ${formatFcfa(f.lowestPrice!, withSuffix: false)}',
            selected: state.formulaCode == f.code,
            onTap: f.availability.selfService
                ? () => cubit.selectFormula(f)
                : null,
          ),

        if (formula != null) ...[
          const SizedBox(height: AppSpacing.md),
          const _Label('Machine'),
          const SizedBox(height: AppSpacing.sm),
          if (machines.isEmpty)
            const Text(
              'Aucune machine ne propose cette prestation.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            )
          else
            for (final m in machines)
              SaleChoiceTile(
                title: '${m.size} kg',
                // La disponibilité est affichée mais ne filtre pas : l'agent
                // doit pouvoir annoncer une attente au client.
                subtitle: m.status == MachineStatus.available
                    ? 'Disponible'
                    : 'Occupée',
                trailing: formatFcfa(
                  formula.priceFor(m.size!)!,
                  withSuffix: false,
                ),
                selected: state.machine?.id == m.id,
                onTap: () => cubit.selectMachine(m),
              ),
        ],
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppColors.textSecondary,
    ),
  );
}
