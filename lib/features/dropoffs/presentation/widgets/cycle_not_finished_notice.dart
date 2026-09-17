import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';

/// Ce qui remplace le bouton « Prendre en charge » tant que le client n'a pas
/// fini son cycle.
///
/// ─── Pourquoi un encart, et non un bouton grisé ───
///
/// Un bouton désactivé laisse croire qu'il manque une permission, ou que
/// l'écran a mal chargé. Ici rien ne cloche : le linge est simplement encore
/// dans une machine. La phrase le dit, et l'attente devient compréhensible.
///
/// L'écran se rafraîchit quand le cycle se termine — l'agent n'a rien à faire
/// d'autre que revenir.
class CycleNotFinishedNotice extends StatelessWidget {
  const CycleNotFinishedNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      // `min` sur les DEUX axes, sans quoi l'encart recouvre l'écran entier.
      //
      // Le Scaffold pose sa `bottomNavigationBar` avec des contraintes LÂCHES
      // sur toute la hauteur disponible : une colonne en `max` les remplit
      // jusqu'en haut, par-dessus l'AppBar et le contenu. Les boutons voisins
      // ne le montraient pas — ils ont une hauteur propre.
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.hourglass_bottom_rounded,
            size: 20,
            color: Color(0xFF8A5A0E),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Le cycle du client n\'est pas terminé',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A5A0E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'La prise en charge sera possible dès la fin du cycle.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.35,
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
