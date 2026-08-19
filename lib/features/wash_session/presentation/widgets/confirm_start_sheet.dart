import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';

/// Demande confirmation avant de lancer physiquement une machine.
///
/// Renvoie `true` seulement si la personne a confirmé. Une feuille refermée
/// d'un glissement, ou par le bouton retour, renvoie `false` : l'abandon est
/// toujours l'issue par défaut, jamais le démarrage.
///
/// ─── Pourquoi une confirmation ───
///
/// Le bouton « Démarrer » lance un vrai cycle sur une vraie machine. Un appui
/// involontaire — la liste qui défile, un pouce qui glisse — consommait la
/// prestation payée sur un tambour vide, sans aucun moyen de revenir en
/// arrière : ni EQLink ni le domaine ne savent annuler un cycle commencé.
///
/// Le même geste existe à quatre endroits (accueil client, « Mes lavages »,
/// « Mes cycles » de l'agent, fin de vente au comptoir). Une seule feuille pour
/// tous : le jour où le texte doit changer, il ne doit pas y avoir quatre
/// versions à retrouver.
///
/// Ne couvre PAS le démarrage du séchage : celui-ci passe par le choix d'une
/// sécheuse précise dans une liste, un geste déjà délibéré, et empiler une
/// feuille sur une feuille se paierait en confusion.
Future<bool> confirmMachineStart(
  BuildContext context, {
  String? machineName,
}) async {
  final confirme = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ConfirmStart(machineName: machineName),
  );

  return confirme ?? false;
}

class _ConfirmStart extends StatelessWidget {
  const _ConfirmStart({required this.machineName});

  final String? machineName;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.lg),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: const Icon(
                  Icons.local_laundry_service_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Votre linge est-il dans la machine ?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          if (machineName != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                machineName!,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.md),
          const Text(
            'La machine démarre tout de suite et le cycle payé est consommé. '
            'Un cycle lancé ne peut pas être annulé.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Démarrer la machine'),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Pas encore'),
            ),
          ),
        ],
      ),
    );
  }
}
