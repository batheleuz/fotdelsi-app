import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';

/// Ce qu'il reste à faire une fois la commande de démarrage partie.
///
/// ─── Pourquoi cette feuille existe ───
///
/// « Démarrer » ne lance pas le tambour. Les machines du parc sont réglées sur
/// une pièce par cycle, et la commande EQLink ne fait que créditer cette pièce :
/// la machine affiche alors « démarrer » sur son propre écran, et c'est le
/// client, sur place, qui appuie. Sans ce geste, la pièce est dépensée pour
/// rien — et personne ne le voit côté serveur.
///
/// L'application affichait un compte à rebours à cet instant. Il décrivait un
/// cycle qui n'avait pas commencé, et il masquait le seul geste qui comptait.
///
/// ─── Pourquoi ici, et pas seulement dans le suivi ───
///
/// C'est l'instant où le regard est sur le bouton qu'on vient de toucher.
/// Le suivi porte la même consigne, mais il faut y aller ; celle-ci vient à
/// la rencontre du client, une fois, au moment utile.
Future<void> showStartCommandSent(
  BuildContext context, {
  /// La machine à charger, nommée. `null` si on ne la connaît pas.
  ///
  /// Passée à part et non lue sur le cycle : au second temps, la sécheuse
  /// vient d'être choisie et n'est pas encore rattachée au cycle en mémoire —
  /// le rechargement arrive derrière.
  String? machineName,

  /// Second temps du cycle : c'est la sécheuse qu'il faut charger.
  bool drying = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _StartCommandSent(machine: machineName, drying: drying),
  );
}

class _StartCommandSent extends StatelessWidget {
  const _StartCommandSent({required this.machine, required this.drying});

  final String? machine;
  final bool drying;

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
                  Icons.send_rounded,
                  size: 19,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Commande de démarrage envoyée',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          if (machine case final nom?) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Text(
                nom,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),
          _Step(
            number: '1',
            text: drying
                ? 'Mettez votre linge dans la sécheuse.'
                : 'Mettez votre linge à l\'intérieur de la machine.',
          ),
          const SizedBox(height: AppSpacing.sm),
          const _Step(
            number: '2',
            // La formulation exacte de l'écran de la machine : c'est ce mot-là
            // que le client doit reconnaître devant lui.
            text: 'Appuyez sur le bouton Démarrer sur l\'écran de la machine.',
          ),

          const SizedBox(height: AppSpacing.md),
          // Les 27 minutes reflètent `CYCLE_MIN_DURATION_MINUTES` côté serveur
          // — c'est LUI qui décide du moment de la notification. Un plancher,
          // jamais une estimation : aucun programme du parc ne descend en
          // dessous, et personne ne sait de combien il le dépasse.
          const Text(
            'Nous vous préviendrons dès que votre cycle devrait être terminé. '
            'Un programme dure au moins 27 minutes.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              child: const Text('J\'ai compris'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une étape numérotée. Deux gestes, dans l'ordre : l'un sans l'autre ne lance
/// rien, et c'est précisément ce que le client ignorait.
class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final String number;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.secondary,
          shape: BoxShape.circle,
        ),
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    ],
  );
}
