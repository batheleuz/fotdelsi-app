import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/router/app_router.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import 'package:fotdelsi/core/widgets/primary_button.dart';
import '../../domain/entities/service_formula.dart';
import '../widgets/service_size_picker.dart';

/// Achat d'une prestation réalisée par l'agent, sans choix de machine.
class PickServiceSizePage extends StatefulWidget {
  const PickServiceSizePage({super.key, required this.formula});

  final ServiceFormula formula;

  @override
  State<PickServiceSizePage> createState() => _PickServiceSizePageState();
}

class _PickServiceSizePageState extends State<PickServiceSizePage> {
  int? _selectedSize;

  @override
  Widget build(BuildContext context) {
    final formula = widget.formula;
    final available = formula.availability.selfService;
    final price = _selectedSize == null
        ? null
        : formula.priceFor(_selectedSize!);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(formula.label)),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  const Text(
                    'Choisissez la taille de votre lot',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Cette prestation est réalisée par un agent. Après confirmation du paiement, remettez votre linge au comptoir.',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ServiceSizePicker(
                    formula: formula,
                    selected: _selectedSize,
                    onSelect: available
                        ? (size) => setState(() => _selectedSize = size)
                        : null,
                  ),
                  if (!available) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      formula.availability.message ??
                          'Prestation indisponible.',
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  if (price != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total à payer'),
                        Text(
                          formatFcfa(price),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  PrimaryButton(
                    label: 'Continuer',
                    icon: Icons.arrow_forward_rounded,
                    enabled: available && price != null,
                    onPressed: () {
                      if (_selectedSize == null ||
                          !available ||
                          price == null) {
                        return;
                      }
                      final ManualPaymentArgs args = (
                        formula: formula,
                        sizeKg: _selectedSize!,
                      );
                      context.push(AppRoutes.payment, extra: args);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
