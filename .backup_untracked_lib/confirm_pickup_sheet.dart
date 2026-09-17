import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';

/// Demande confirmation avant de clore un cycle.
///
/// Renvoie `true` seulement si la personne a confirmé. Une feuille refermée
/// d'un glissement, ou par le bouton retour, renvoie `false`.
///
/// ─── Pourquoi une confirmation ───
///
/// Ce geste TERMINE le cycle, et rien ne le rouvre : la commande passe en
/// historique, le code de remise est délivré, la machine est rendue aux
/// suivants. C'est le seul geste qui puisse le faire depuis qu'EQLink ne rend
/// plus l'état réel des machines.
///
/// Or il se présente à un moment trompeur : la notification annonce une fin
/// PRÉSUMÉE, pas constatée — le plancher d'un programme, pas sa durée. Le
/// tambour peut encore tourner. Confirmer trop vite, c'est déclarer fini un
/// cycle qui ne l'est pas, et ne plus rien voir bouger ensuite.
///
/// La question posée est donc celle du réel, pas celle du bouton : « votre
/// linge est-il sorti de la machine ? »
Future<bool> confirmLaundryPickup(BuildContext context) async {
  final confirme = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _ConfirmPickup(),
  );

  return confirme ?? false;
}

class _ConfirmPickup extends StatelessWidget {
  const _ConfirmPickup();

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
                  Icons.checkroom_rounded,
                  size: 20,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Votre linge est-il sorti de la machine ?',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),
          const Text(
            'Confirmer termine votre cycle : il rejoint vos lavages terminés '
            'et la machine est rendue aux autres clients. Si le cycle tourne '
            'encore, attendez qu\'il s\'arrête.',
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
              icon: const Icon(Icons.check_rounded),
              label: const Text('Oui, j\'ai récupéré mon linge'),
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
