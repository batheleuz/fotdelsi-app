import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import '../../domain/entities/service_formula.dart';

/// Même présentation des tailles de lots pour l'agent et le client.
class ServiceSizePicker extends StatelessWidget {
  const ServiceSizePicker({
    super.key,
    required this.formula,
    required this.selected,
    required this.onSelect,
  });

  final ServiceFormula formula;
  final int? selected;
  final ValueChanged<int>? onSelect;

  @override
  Widget build(BuildContext context) {
    final sizes = formula.lotSizes;
    if (sizes.isEmpty) {
      return const Text('Aucune taille disponible pour cette formule.');
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final size in sizes)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: size == sizes.last ? 0 : 8),
              child: Semantics(
                button: true,
                selected: selected == size,
                child: Material(
                  color: selected == size
                      ? AppColors.surfaceTint
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: InkWell(
                    onTap: onSelect == null ? null : () => onSelect!(size),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 4,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(
                          color: selected == size
                              ? AppColors.primaryLight
                              : AppColors.border,
                          width: selected == size ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            '$size kg',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formatFcfa(
                              formula.priceFor(size)!,
                              withSuffix: false,
                            ),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: selected == size
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const Text(
                            'FCFA',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Icon(
                            selected == size
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 20,
                            color: selected == size
                                ? AppColors.primaryLight
                                : AppColors.border,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
