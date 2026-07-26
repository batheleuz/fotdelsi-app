import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import 'package:fotdelsi/features/payment/presentation/utils/payment_provider_presentation.dart';
import 'package:fotdelsi/features/payment/presentation/widgets/payment_provider_logo.dart';
import '../../../domain/entities/prestation.dart';
import '../../cubit/new_dropoff_cubit.dart';

/// Étape 3 — prestation (montant) et opérateur de paiement.
class NewDropOffServiceStep extends StatelessWidget {
  const NewDropOffServiceStep({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<NewDropOffCubit>();
    final state = context.watch<NewDropOffCubit>().state;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const _Title('Prestation'),
        const SizedBox(height: AppSpacing.sm),
        _prestations(context, state, cubit),
        if (state.dryingPrice != null) ...[
          const SizedBox(height: AppSpacing.md),
          _DryingToggle(
            price: state.dryingPrice!,
            enabled: state.withDrying,
            onChanged: cubit.toggleDrying,
          ),
        ],
        if (state.total != null) ...[
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Column(
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
                  formatFcfa(state.total!),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _prestations(
    BuildContext context,
    NewDropOffState state,
    NewDropOffCubit cubit,
  ) {
    return switch (state.prestationsStatus) {
      LoadStatus.loading || LoadStatus.initial => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      LoadStatus.failure => _PrestationError(onRetry: cubit.retryPrestations),
      LoadStatus.success => Column(
        children: state.prestations
            .map(
              (p) => _PrestationCard(
                prestation: p,
                selected: state.amount == p.amount,
                onTap: () => cubit.selectPrestation(p.amount),
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

/// Option séchage : payée d'avance avec le dépôt, prix unique.
class _DryingToggle extends StatelessWidget {
  const _DryingToggle({
    required this.price,
    required this.enabled,
    required this.onChanged,
  });

  final int price;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!enabled),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: enabled ? AppColors.surfaceTint : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: enabled ? AppColors.primaryLight : AppColors.border,
            width: enabled ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.dry_cleaning_outlined,
                size: 20, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ajouter le séchage',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '+ ${formatFcfa(price, withSuffix: false)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Switch.adaptive(value: enabled, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _PrestationCard extends StatelessWidget {
  const _PrestationCard({
    required this.prestation,
    required this.selected,
    required this.onTap,
  });

  final Prestation prestation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = prestation.sizeKg != null
        ? 'Lavage ${prestation.sizeKg} kg'
        : 'Lavage';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
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
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            Text(
              formatFcfa(prestation.amount, withSuffix: false),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
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

class _PrestationError extends StatelessWidget {
  const _PrestationError({required this.onRetry});
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
