import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/utils/price_formatter.dart';
import 'package:fotdelsi/features/catalog/domain/entities/service_formula.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';

/// Récapitulatif de la commande en haut de l'écran de paiement.
///
/// Le montant affiché vient de la grille tarifaire (formule × capacité de la
/// machine). Il est indicatif : le serveur retarifie à l'initiation, et c'est
/// son prix qui est réellement débité.
class OrderRecapCard extends StatelessWidget {
  const OrderRecapCard({
    super.key,
    required this.formula,
    required this.machine,
  });

  /// `null` pour une machine scannée : il n'y a pas de prestation, seulement
  /// un appareil. Le récapitulatif décrit alors la machine.
  final ServiceFormula? formula;
  final Machine machine;

  /// Ce qu'une machine sait faire, et rien d'autre.
  ///
  /// Le scan ne vend pas de prestation composée : ni pliage, ni repassage, ni
  /// lavage+séchage. On achète l'appareil devant soi, donc son unique usage.
  static String _prestationDe(Machine machine) =>
      machine.type == MachineType.dryer ? 'Séchage seul' : 'Lavage seul';

  @override
  Widget build(BuildContext context) {
    final size = machine.size;
    final f = formula;
    final price = f == null
        ? machine.price.round()
        : (size == null ? null : f.priceFor(size));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Machine scannée : c'est l'appareil qu'on récapitule, puisque c'est
          // lui qu'on achète. Le titre porte donc son nom, et la ligne du
          // dessous dit la seule prestation possible — celle que la machine
          // sait faire.
          _Row(
            label: f?.label ?? machine.name,
            value: f == null
                ? (size == null ? '' : '$size kg')
                : (size == null ? machine.name : '$size kg'),
          ),
          const SizedBox(height: 3),
          // Le nom est court par choix : le client doit pouvoir vérifier ce
          // qu'il paie avant de valider.
          Text(
            f?.composition ?? _prestationDe(machine),
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          // Prévient avant le paiement : le linge ne repartira pas tout de suite.
          if (f?.requiresAgent ?? false) ...[
            const SizedBox(height: 6),
            const Text(
              'Linge à remettre au comptoir en fin de cycle.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 0.5, color: AppColors.border),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Text(
                price == null ? '—' : formatFcfa(price),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          textAlign: TextAlign.end,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
