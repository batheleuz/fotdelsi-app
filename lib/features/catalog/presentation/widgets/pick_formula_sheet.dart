import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import 'package:fotdelsi/features/catalog/domain/entities/drying_duration_tier.dart';
import 'package:fotdelsi/features/catalog/domain/entities/service_formula.dart';
import 'package:fotdelsi/features/catalog/presentation/cubit/service_catalog_cubit.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';

/// Que veut-on de LA machine qu'on vient de scanner ?
///
/// Le second chemin d'achat : on est devant un appareil, on choisit ce qu'il
/// doit faire. L'inverse du premier, où la prestation est choisie sur l'accueil
/// et le scan ne fait que désigner la machine.
///
/// Ce chemin avait été retiré parce qu'il « promettait un pliage sur une
/// sécheuse » : l'écran proposait tout le catalogue, sans égard pour ce que
/// l'appareil sait faire. La liste est désormais filtrée sur la machine —
/// bon type, et capacité effectivement tarifée. Une sécheuse n'ouvre même pas
/// cette feuille : aucune formule du catalogue ne commence par un séchage,
/// elle se vend au prix qu'elle porte.
///
/// Renvoie la formule choisie, ou `null` si la feuille est refermée.
Future<ServiceFormula?> showPickFormulaSheet(
  BuildContext context, {
  required Machine machine,
}) {
  return showModalBottomSheet<ServiceFormula>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BlocProvider(
      create: (_) => serviceLocator<ServiceCatalogCubit>()..load(),
      child: _PickFormula(machine: machine),
    ),
  );
}

class _PickFormula extends StatelessWidget {
  const _PickFormula({required this.machine});

  final Machine machine;

  /// Prestations que CETTE machine sait rendre, à un tarif connu.
  List<ServiceFormula> _eligible(List<ServiceFormula> all) {
    final size = machine.size;
    if (size == null) return const [];
    return all
        .where(
          (f) =>
              f.needsWasher == (machine.type == MachineType.washer) &&
              f.priceFor(size) != null,
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ServiceCatalogCubit>().state;
    final formulas = _eligible(state.formulas);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Text(
            machine.name,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            machine.size == null
                ? 'Que voulez-vous faire ?'
                : '${machine.size} kg · que voulez-vous faire ?',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          switch (state.status) {
            CatalogStatus.success when formulas.isEmpty => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'Aucune prestation ne convient à cette machine.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            CatalogStatus.success => Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final formula in formulas)
                    _FormulaRow(
                      formula: formula,
                      // Le prix de CETTE capacité : `machine.size` est non nul
                      // dès qu'une formule a passé le filtre.
                      price: formula.includesDrying
                          ? formula.priceFor(machine.size!)! +
                              DryingDurationTier.configuredDefault.price
                          : formula.priceFor(machine.size!)!,
                      onTap: () => Navigator.of(context).pop(formula),
                    ),
                ],
              ),
            ),
            CatalogStatus.failure => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                state.error ?? 'Impossible de charger nos services.',
                style: const TextStyle(color: AppColors.danger),
              ),
            ),
            _ => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
          },
        ],
      ),
    );
  }
}

class _FormulaRow extends StatelessWidget {
  const _FormulaRow({
    required this.formula,
    required this.price,
    required this.onTap,
  });

  final ServiceFormula formula;
  final int price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Une prestation indisponible reste VISIBLE mais inerte : la masquer
    // laisserait croire qu'elle n'existe pas, alors qu'elle revient plus tard
    // dans la journée — c'est l'horaire de l'agent qui la retient.
    final available = formula.availability.selfService;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: available ? 1 : 0.55,
        child: Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: InkWell(
            onTap: available ? onTap : null,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Container(
              padding: const EdgeInsets.all(13),
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
                          formula.label,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          available
                              ? formula.composition
                              : (formula.availability.message ??
                                    formula.composition),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    formatFcfa(price),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
