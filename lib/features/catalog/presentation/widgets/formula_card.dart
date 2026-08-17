import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import '../../domain/entities/service_formula.dart';

/// Carte d'une prestation du catalogue, telle que présentée sur l'accueil.
///
/// Annonce « à partir de » plutôt qu'un prix unique : le tarif dépend de la
/// capacité de la machine, choisie à l'étape suivante.
class FormulaCard extends StatelessWidget {
  const FormulaCard({
    super.key,
    required this.formula,
    required this.onTap,
    this.available = true,
  });

  final ServiceFormula formula;
  final VoidCallback onTap;

  /// `false` hors des heures de présence de l'agent. La carte reste visible —
  /// le client doit voir l'offre complète et comprendre pourquoi elle est
  /// fermée, pas la croire inexistante.
  final bool available;

  @override
  Widget build(BuildContext context) {
    final from = formula.lowestPrice;
    final message = formula.availability.message;

    return Opacity(
      opacity: available ? 1 : 0.55,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceTint,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    _iconFor(formula),
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formula.label,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Le titre dit le résultat ; cette ligne dit ce qu'il
                      // recouvre, sans rallonger le nom commercial.
                      Text(
                        formula.composition,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      // Sans l'horaire, le client ne saurait pas quand revenir.
                      if (!available && message != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          message,
                          style: const TextStyle(
                            fontSize: 11.5,
                            height: 1.35,
                            color: AppColors.secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (from != null && available)
                      Text(
                        'dès ${formatFcfa(from, withSuffix: false)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    Icon(
                      available
                          ? Icons.chevron_right_rounded
                          : Icons.schedule_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// L'icône reflète la prestation la plus « aboutie » de la formule.
  static IconData _iconFor(ServiceFormula formula) {
    if (formula.includesItem(ServiceItemKind.ironing)) {
      return Icons.iron_outlined;
    }
    if (formula.includesItem(ServiceItemKind.folding)) {
      return Icons.inventory_2_outlined;
    }
    if (formula.includesDrying) return Icons.dry_cleaning_outlined;
    return Icons.local_laundry_service_outlined;
  }
}
