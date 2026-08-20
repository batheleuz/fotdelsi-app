import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/router/app_router.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/motion/app_motion.dart';
import 'package:fotdelsi/core/motion/entrance.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_curves.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../cubit/service_catalog_cubit.dart';
import 'formula_card.dart';

/// Catalogue des prestations — contenu principal de l'accueil.
///
/// Remplace l'ancienne grille de machines : le client raisonne en besoin
/// (« laver et sécher »), pas en équipement. La machine est choisie ensuite,
/// une fois la prestation connue.
class ServiceCatalogContent extends StatelessWidget {
  const ServiceCatalogContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceCatalogCubit, ServiceCatalogState>(
      builder: (context, state) => AnimatedSwitcher(
        // Le catalogue passait du rond de chargement aux cartes d'un seul
        // coup, en changeant de hauteur au passage. Le fondu enchaîné adoucit
        // les deux : l'opacité ET la hauteur.
        duration: AppMotion.duration(context, AppDurations.normal),
        switchInCurve: AppCurves.standard,
        switchOutCurve: AppCurves.standard,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: switch (state.status) {
          CatalogStatus.initial || CatalogStatus.loading => const Padding(
            key: ValueKey('catalogue-chargement'),
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
          CatalogStatus.failure => _Error(
            key: const ValueKey('catalogue-erreur'),
            message: state.error ?? 'Impossible de charger nos services.',
            onRetry: () => context.read<ServiceCatalogCubit>().load(),
          ),
          CatalogStatus.success => Column(
            key: const ValueKey('catalogue-services'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nos services',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              const Text(
                'Choisissez une prestation, puis votre machine.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final (i, formula) in state.formulas.indexed) ...[
                EntranceFade(
                  index: i,
                  child: FormulaCard(
                    formula: formula,
                    // Parcours libre-service : le linge passera d'abord en
                    // machine, l'agent doit encore être là à la sortie du cycle.
                    available: formula.availability.selfService,
                    onTap: () {
                      final PickMachineArgs args = (formula: formula);
                      context.push(AppRoutes.pickMachine, extra: args);
                    },
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        },
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(onPressed: onRetry, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }
}
