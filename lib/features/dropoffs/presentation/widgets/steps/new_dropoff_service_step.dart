import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import 'package:fotdelsi/features/catalog/domain/entities/service_formula.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
// Fournit l'extension `label` sur PaymentProvider.
import 'package:fotdelsi/features/payment/presentation/utils/payment_provider_presentation.dart';
import 'package:fotdelsi/features/payment/presentation/widgets/payment_provider_logo.dart';
import '../../cubit/new_dropoff_cubit.dart';

/// Étape 3 — formule de service, capacité, puis opérateur de paiement.
///
/// Les tarifs affichés viennent du catalogue serveur : l'agent choisit une
/// prestation, jamais un prix. Le montant définitif est recalculé côté serveur
/// à partir du couple (formule, capacité).
class NewDropOffServiceStep extends StatelessWidget {
  const NewDropOffServiceStep({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NewDropOffCubit>();
    final state = context.watch<NewDropOffCubit>().state;
    final formula = state.selectedFormula;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const _Title('Prestation'),
        const SizedBox(height: AppSpacing.sm),
        _formulas(state, cubit),
        if (formula != null) ...[
          const SizedBox(height: AppSpacing.lg),
          const _Title('Capacité'),
          const SizedBox(height: AppSpacing.sm),
          _SizePicker(
            formula: formula,
            selected: state.sizeKg,
            onSelect: cubit.selectSize,
          ),
        ],
        if (state.total != null && formula != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _TotalBanner(total: state.total!, formula: formula),
        ],
        const SizedBox(height: AppSpacing.lg),
        const _Title('Opérateur'),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _Operator(
                provider: PaymentProvider.wave,
                selected: state.provider == PaymentProvider.wave,
                onTap: () => cubit.selectProvider(PaymentProvider.wave),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Operator(
                provider: PaymentProvider.orangeMoney,
                selected: state.provider == PaymentProvider.orangeMoney,
                onTap: () => cubit.selectProvider(PaymentProvider.orangeMoney),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _formulas(NewDropOffState state, NewDropOffCubit cubit) {
    return switch (state.formulasStatus) {
      LoadStatus.loading || LoadStatus.initial => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      LoadStatus.failure => _CatalogError(onRetry: cubit.retryFormulas),
      LoadStatus.success => Column(
        children: state.formulas
            .map(
              (f) => _FormulaCard(
                formula: f,
                selected: state.formulaCode == f.code,
                // Règle du dépôt et non du libre-service : le linge est
                // confié maintenant, il n'a pas à attendre la fin d'un cycle.
                onTap: f.availability.dropOff
                    ? () => cubit.selectFormula(f)
                    : null,
              ),
            )
            .toList(),
      ),
    };
  }
}

class _Title extends StatelessWidget {
  const _Title(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
  );
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({
    required this.formula,
    required this.selected,
    required this.onTap,
  });

  final ServiceFormula formula;
  final bool selected;

  /// `null` hors des heures de présence : la carte reste visible pour que
  /// l'agent puisse expliquer, mais ne se sélectionne plus.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final from = formula.lowestPrice;
    final available = onTap != null;

    return Opacity(
      opacity: available ? 1 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.surfaceTint : AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: selected ? AppColors.primaryLight : AppColors.border,
              width: selected ? 2 : 1,
            ),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Le nom commercial dit le résultat ; l'agent a besoin du
                    // détail pour confirmer la commande au client.
                    Text(
                      available
                          ? formula.composition
                          : (formula.availability.message ??
                                formula.composition),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    // Prévient l'agent que le linge ne repart pas tout de suite.
                    if (formula.requiresAgent) ...[
                      const SizedBox(height: 2),
                      const Text(
                        'Traitement au comptoir',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.primaryLight,
                )
              else if (from != null)
                Text(
                  'dès ${formatFcfa(from, withSuffix: false)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Capacités tarifées pour la formule choisie, avec leur prix.
class _SizePicker extends StatelessWidget {
  const _SizePicker({
    required this.formula,
    required this.selected,
    required this.onSelect,
  });

  final ServiceFormula formula;
  final int? selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final sizes = formula.sizes;

    return Row(
      children: List.generate(sizes.length, (index) {
        final size = sizes[index];
        final price = formula.priceFor(size)!;
        final isSelected = selected == size;
        final isLast = index == sizes.length - 1;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: GestureDetector(
              onTap: () => onSelect(size),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surfaceTint : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primaryLight
                        : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      '$size kg',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatFcfa(price, withSuffix: false),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _TotalBanner extends StatelessWidget {
  const _TotalBanner({required this.total, required this.formula});

  final int total;
  final ServiceFormula formula;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Total à payer',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 0.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formatFcfa(total),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        if (formula.includesDrying) ...[
          const SizedBox(height: 4),
          const Text(
            'Séchage compris',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ],
    );
  }
}

class _Operator extends StatelessWidget {
  const _Operator({
    required this.provider,
    required this.selected,
    required this.onTap,
  });

  final PaymentProvider provider;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceTint : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            PaymentProviderLogo(provider: provider, size: 34),
            const SizedBox(height: 6),
            Text(
              provider.label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogError extends StatelessWidget {
  const _CatalogError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text(
            'Impossible de charger les tarifs.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onRetry, child: const Text('Réessayer')),
        ],
      ),
    );
  }
}
