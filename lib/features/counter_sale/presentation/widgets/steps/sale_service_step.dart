import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import 'package:fotdelsi/features/catalog/domain/entities/drying_duration_tier.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/core/widgets/quantity_stepper.dart';
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
        const _Label('Prestation'),
        const SizedBox(height: AppSpacing.sm),
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
            onTap: () => cubit.selectFormula(f),
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

          if (state.hasDrying) ...[
            const SizedBox(height: AppSpacing.md),
            const _Label('Durée de séchage'),
            const SizedBox(height: AppSpacing.sm),
            for (final tier in DryingDurationTier.values)
              Builder(
                builder: (context) {
                  final isDryerOnly = state.machine?.type == MachineType.dryer;
                  final String priceLabel = isDryerOnly
                      ? formatFcfa(tier.price)
                      : '+${formatFcfa(tier.price)}';

                  return SaleChoiceTile(
                    title: tier.label,
                    subtitle:
                        '${tier.pulses ~/ 100} pièce(s) · ${tier.pulses} pulses',
                    trailing: priceLabel,
                    selected: state.dryingTier == tier,
                    onTap: () => cubit.selectDryingTier(tier),
                  );
                },
              ),
          ],

          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Label('Nombre de cycles'),
                  Text(
                    'À lancer sur les machines libres',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              QuantityStepper(
                value: state.quantity,
                onChanged: cubit.selectQuantity,
              ),
            ],
          ),

          if (state.total != null) ...[
            const SizedBox(height: AppSpacing.lg),
            _TotalBanner(
              total: state.total!,
              hasDrying: state.hasDrying,
            ),
          ],
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

class _TotalBanner extends StatelessWidget {
  const _TotalBanner({required this.total, required this.hasDrying});

  final int total;
  final bool hasDrying;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total à payer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              if (hasDrying) ...[
                const SizedBox(height: 2),
                const Text(
                  'Séchage compris',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          Text(
            formatFcfa(total),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
