import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import 'package:fotdelsi/features/payment/presentation/utils/payment_provider_presentation.dart';
import 'package:fotdelsi/features/payment/presentation/widgets/payment_provider_logo.dart';
import '../../cubit/counter_sale_cubit.dart';

/// Étape 2 — qui paie et par quel moyen, puis le récapitulatif.
///
/// Le téléphone est demandé même si le client paie par QR : c'est lui qui
/// permettra de le prévenir quand son linge sera prêt, et de retrouver sa
/// commande s'il revient sans rien.
class SaleCustomerStep extends StatelessWidget {
  const SaleCustomerStep({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CounterSaleCubit>();
    final state = context.watch<CounterSaleCubit>().state;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        TextField(
          decoration: _decoration('Nom du client'),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          onChanged: cubit.setCustomerName,
        ),
        const SizedBox(height: 12),
        TextField(
          decoration: _decoration('Téléphone', prefix: '+221 '),
          keyboardType: TextInputType.phone,
          maxLength: 9,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: cubit.setCustomerPhone,
        ),
        const Padding(
          padding: EdgeInsets.only(top: 2, left: 2),
          child: Text(
            'Sert à prévenir le client quand son linge est prêt.',
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),
        const Text(
          'Opérateur',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            for (final p in PaymentProvider.values) ...[
              Expanded(
                child: _ProviderCard(
                  provider: p,
                  selected: state.provider == p,
                  onTap: () => cubit.selectProvider(p),
                ),
              ),
              if (p != PaymentProvider.values.last) const SizedBox(width: 10),
            ],
          ],
        ),

        if (state.total != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _Recap(
            label:
                '${state.selectedFormula!.label} · ${state.machine!.size} kg',
            total: state.total!,
          ),
        ],
      ],
    );
  }

  static InputDecoration _decoration(String label, {String? prefix}) =>
      InputDecoration(
        labelText: label,
        prefixText: prefix,
        counterText: '',
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      );
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({
    required this.provider,
    required this.selected,
    required this.onTap,
  });

  final PaymentProvider provider;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
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
              PaymentProviderLogo(provider: provider, size: 32),
              const SizedBox(height: 6),
              Text(
                provider.label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Ce que l'agent annonce au client avant de présenter le code.
class _Recap extends StatelessWidget {
  const _Recap({required this.label, required this.total});

  final String label;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Total à payer',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatFcfa(total),
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
