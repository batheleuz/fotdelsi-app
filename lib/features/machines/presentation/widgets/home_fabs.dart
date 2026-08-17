import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/wash_session/domain/entities/wash_cycle.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_cycles_cubit.dart';
import 'package:fotdelsi/features/wash_session/presentation/widgets/wash_running_sheet.dart';

/// Boutons flottants de l'accueil : rouvrir le cycle suivi, et scanner.
///
/// Extraits de `home_page.dart` pour être éprouvables seuls : la page entière
/// exige quatre cubits enregistrés dans le conteneur, alors que ces boutons ne
/// dépendent que des cycles.
class HomeFabs extends StatelessWidget {
  const HomeFabs({super.key});

  @override
  Widget build(BuildContext context) {
    // Même source que le bandeau et « Mes lavages » : le serveur. Ce FAB
    // s'appuyait sur la session stockée localement, qui pouvait décrire un
    // cycle que le serveur ne connaissait plus.
    //
    // `followable` et non `running` : entre le lavage et le séchage, plus
    // aucune machine ne tourne. Le FAB disparaissait donc à l'instant précis où
    // la feuille de suivi devient utile, et refermer celle-ci laissait le
    // client sans aucun moyen d'y revenir.
    final suivi = context.select<MyCyclesCubit, WashCycle?>(
      (c) => c.state.followable,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Rouvre la feuille de suivi du cycle en cours ou en attente de
        // séchage. Le geste « Démarrer » vit, lui, dans le bandeau.
        if (suivi != null) ...[
          _SessionFab(cycle: suivi),
          const SizedBox(height: AppSpacing.sm),
        ],
        // FAB scan — toujours présent
        _ScanFab(),
      ],
    );
  }
}

class _SessionFab extends StatelessWidget {
  const _SessionFab({required this.cycle});

  final WashCycle cycle;

  @override
  Widget build(BuildContext context) {
    // Deux situations, deux annonces : une machine qui tourne se regarde, un
    // séchage à lancer se fait. Les confondre sous « En cours » laisserait
    // croire que le cycle avance alors qu'il attend le client.
    final aSecher = cycle.state == CycleState.dryingToStart;

    return FloatingActionButton.extended(
      heroTag: 'session_fab',
      onPressed: () => WashRunningSheet.show(
        context,
        cycle,
        cycles: context.read<MyCyclesCubit>(),
      ),
      backgroundColor: aSecher ? AppColors.secondary : AppColors.success,
      foregroundColor: Colors.white,
      icon: Icon(
        aSecher
            ? Icons.dry_cleaning_rounded
            : Icons.local_laundry_service_rounded,
      ),
      label: Text(
        aSecher ? 'Séchage à lancer' : 'En cours',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ScanFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'scan_fab',
      onPressed: () => context.push(AppRoutes.scan),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      child: const Icon(Icons.qr_code_scanner_rounded),
    );
  }
}
