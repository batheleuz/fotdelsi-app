import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import '../../cubit/counter_sale_cubit.dart';

/// Étape 4 — paiement confirmé, la machine reste à lancer.
///
/// Le client n'a pas l'application : c'est l'agent qui démarre, une fois le
/// linge chargé. Un échec de démarrage ne fait pas échouer la vente — le
/// paiement reste acquis et le bouton redevient actionnable.
class SaleStartStep extends StatelessWidget {
  const SaleStartStep({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<CounterSaleCubit>().state;
    final started = state.saleStatus == SaleStatus.started;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      children: [
        _Banner(
          icon: started
              ? Icons.local_laundry_service_rounded
              : Icons.check_circle_rounded,
          color: started ? AppColors.primary : AppColors.success,
          title: started
              ? 'Machine lancée'
              : '${formatFcfa(state.total ?? 0)} reçus',
          subtitle: started
              ? 'La vente est terminée.'
              : '${state.provider?.name ?? ''} · ${state.customerName}',
        ),

        if (!started) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              'Faites charger le linge dans la machine '
              '${state.machine?.size ?? ''} kg, puis démarrez-la.',
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
