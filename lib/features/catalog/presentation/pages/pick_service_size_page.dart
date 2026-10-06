import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/router/app_router.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import '../../domain/entities/service_formula.dart';

/// Achat d'une prestation réalisée par l'agent, sans choix de machine.
class PickServiceSizePage extends StatelessWidget {
  const PickServiceSizePage({super.key, required this.formula});

  final ServiceFormula formula;

  @override
  Widget build(BuildContext context) {
    final sizes = [
      12,
      15,
      20,
    ].where((size) => formula.priceFor(size) != null).toList();
    return Scaffold(
      appBar: AppBar(title: Text(formula.label)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const Text(
            'Choisissez la taille de votre lot',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Cette prestation est réalisée par un agent. Après confirmation du paiement, remettez votre linge au comptoir.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (sizes.isEmpty)
            const Text('Aucune taille disponible pour cette formule.'),
          for (final size in sizes)
            Card(
              child: ListTile(
                title: Text('$size kg'),
                trailing: Text(formatFcfa(formula.priceFor(size)!)),
                onTap: formula.availability.selfService
                    ? () {
                        final ManualPaymentArgs args = (
                          formula: formula,
                          sizeKg: size,
                        );
                        context.push(AppRoutes.payment, extra: args);
                      }
                    : null,
              ),
            ),
          if (!formula.availability.selfService)
            Text(formula.availability.message ?? 'Prestation indisponible.'),
        ],
      ),
    );
  }
}
