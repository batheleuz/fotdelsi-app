import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/motion/app_motion.dart';
import 'package:fotdelsi/core/motion/entrance.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_curves.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../../domain/entities/business_hours.dart';
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
              const SizedBox(height: AppSpacing.sm),
              // Avant les prestations, et pas après : une fermeture rend tout
              // ce qui suit inachetable. La découvrir au moment de payer,
              // après avoir choisi une formule et une machine, donnait
              // l'impression d'une panne.
              if (state.businessHours.isClosed) ...[
                _ClosedBanner(hours: state.businessHours),
                const SizedBox(height: AppSpacing.sm),
              ],
              // Le raccourci n'existait que sous forme d'un bouton rond sans
              // libellé, en bas de l'écran : personne ne pouvait deviner qu'on
              // pouvait partir de la machine plutôt que de la prestation.
              const _ScanHint(),
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
                      context.push(AppRoutes.scan, extra: formula);
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

/// Bandeau de fermeture — la laverie est hors de ses horaires d'ouverture.
///
/// Distinct de l'indisponibilité portée par chaque formule : là c'est l'agent
/// qui manque et seules les finitions s'arrêtent, ici plus aucune machine ne
/// démarre. Un seul bandeau plutôt que le même message répété sur chaque
/// carte.
class _ClosedBanner extends StatelessWidget {
  const _ClosedBanner({required this.hours});

  final BusinessHours hours;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.bedtime_rounded, size: 18, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service fermé',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ouverture de ${hours.opensAtLabel} à ${hours.closesAtLabel}. '
                  'Aucune machine ne peut être lancée d\'ici là.',
                  style: const TextStyle(
                    fontSize: 12,
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

/// Annonce le raccourci : partir de la machine plutôt que de la prestation.
///
/// Le client debout devant une machine libre n'a pas à retrouver laquelle
/// c'est dans une liste — il scanne le QR collé dessus. Encore fallait-il le
/// lui dire : le bouton, rond et muet, ne l'apprenait à personne.
class _ScanHint extends StatelessWidget {
  const _ScanHint();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: () => context.push(AppRoutes.scan),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.qr_code_scanner_rounded,
                size: 19,
                color: AppColors.onPrimary,
              ),
              const SizedBox(width: 10),
              // Deux lignes assumées plutôt qu'une phrase qui se casse où elle
              // veut : sur un écran étroit, « …son QR / code. » laissait un mot
              // orphelin. Découpé ainsi, le retour tombe toujours au bon
              // endroit, quelle que soit la largeur.
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Déjà devant une machine ?',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    SizedBox(height: 1),
                    Text(
                      'Scannez son QR code.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.surfaceTint,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.surfaceTint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
