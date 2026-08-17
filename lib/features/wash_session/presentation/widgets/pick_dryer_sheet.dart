import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/machines/presentation/bloc/machines_bloc.dart';
import 'package:fotdelsi/features/machines/presentation/bloc/machines_event.dart';
import '../../domain/entities/wash_cycle.dart';
import '../cubit/wash_cycles_cubit.dart';

/// Demande au client quelle sécheuse lancer, puis lance le second temps.
///
/// Une feuille et non une page : le geste est court et le contexte — la liste
/// de ses lavages — reste visible derrière. Même parti pris que la liaison du
/// numéro.
///
/// Pourquoi un choix, alors que le premier temps n'en demande pas : la laveuse
/// a été payée nommément, la sécheuse non. Elle est choisie au moment où le
/// linge sort, en fonction de ce qui est libre à cet instant.
///
/// [cycles] est passé, et non lu depuis [context].
///
/// `context.read<WashCyclesCubit>()` échouait sur l'accueil : le provider y
/// expose la sous-classe `MyCyclesCubit`, et un `read` par type de base ne la
/// trouve pas. L'exception partait dans le gestionnaire de geste, où elle est
/// avalée — le bouton « Lancer le séchage » ne faisait donc rien du tout, en
/// silence. Le passer en argument rend la dépendance statique : le compilateur
/// la vérifie, au lieu de la découvrir à l'exécution.
Future<void> showPickDryerSheet(
  BuildContext context,
  WashCycle cycle, {
  required WashCyclesCubit cycles,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => MultiBlocProvider(
      providers: [
        // `.value` : la feuille s'ouvre sur une autre branche de l'arbre, elle
        // n'hériterait pas des blocs fournis plus haut.
        //
        // Type explicite : l'appelant peut passer une sous-classe, et une
        // inférence sur son type dynamique rendrait le `read` ci-dessous
        // introuvable.
        BlocProvider<WashCyclesCubit>.value(value: cycles),
        BlocProvider.value(value: serviceLocator<MachinesBloc>()),
      ],
      child: _PickDryer(cycle: cycle),
    ),
  );
}

class _PickDryer extends StatefulWidget {
  const _PickDryer({required this.cycle});

  final WashCycle cycle;

  @override
  State<_PickDryer> createState() => _PickDryerState();
}

class _PickDryerState extends State<_PickDryer> {
  String? _starting;

  /// Motif du dernier refus, affiché ICI et non en snackbar : celui-ci
  /// s'afficherait derrière la feuille restée ouverte, donc invisible.
  String? _error;

  @override
  void initState() {
    super.initState();
    // Le bloc est un singleton : sa liste est déjà à jour si l'accueil a été
    // ouvert. Sinon on l'amorce ici, plutôt que d'afficher une feuille vide.
    final bloc = context.read<MachinesBloc>();
    if (bloc.state.machines.isEmpty) {
      bloc.add(const MachinesSubscriptionRequested());
    }
  }

  Future<void> _start(Machine dryer) async {
    setState(() {
      _starting = dryer.id;
      _error = null;
    });

    final message = await context.read<WashCyclesCubit>().startDrying(
      widget.cycle,
      dryer,
    );

    if (!mounted) return;

    // On ne ferme que si la sécheuse est réellement partie. Sinon le client
    // reste ici, lit pourquoi, et en choisit une autre.
    if (message == null) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _starting = null;
      _error = message;
    });

    // Un refus signifie presque toujours que la liste affichée est en retard :
    // la sécheuse paraissait libre, elle ne l'est plus. On redemande l'état
    // réel pour que la tuile se grise et que le refus s'explique de lui-même.
    context.read<MachinesBloc>().add(const MachinesSubscriptionRequested());
  }

  @override
  Widget build(BuildContext context) {
    final dryers = context.select<MachinesBloc, List<Machine>>(
      (b) =>
          b.state.machines.where((m) => m.type == MachineType.dryer).toList()
            ..sort((a, b) => (a.size ?? 0).compareTo(b.size ?? 0)),
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),

          const Text(
            'Choisissez votre sécheuse',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Le séchage est déjà payé. Chargez votre linge, puis lancez la '
            'machine que vous avez choisie.',
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFDECEC),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    size: 17,
                    color: AppColors.danger,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.lg),

          if (dryers.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
              child: Text(
                'Aucune sécheuse n\'est visible pour le moment. Réessayez dans '
                'un instant.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
            )
          else
            for (final dryer in dryers)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _DryerTile(
                  dryer: dryer,
                  starting: _starting == dryer.id,
                  // Un seul démarrage à la fois : deux sécheuses lancées par
                  // erreur, c'est un cycle payé pour rien.
                  onTap: _starting == null ? () => _start(dryer) : null,
                ),
              ),
        ],
      ),
    );
  }
}

class _DryerTile extends StatelessWidget {
  const _DryerTile({
    required this.dryer,
    required this.starting,
    required this.onTap,
  });

  final Machine dryer;
  final bool starting;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final free = dryer.status == MachineStatus.available;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        // Une sécheuse occupée ou hors ligne n'est pas proposée : la lancer
        // échouerait côté EQLink après avoir fait espérer le client.
        onTap: free ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(
                Icons.dry_cleaning_rounded,
                size: 20,
                color: free ? AppColors.primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dryer.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: free
                            ? AppColors.textPrimary
                            : AppColors.textTertiary,
                      ),
                    ),
                    Text(
                      free
                          ? [
                              if (dryer.size != null) '${dryer.size} kg',
                              'Disponible',
                            ].join(' · ')
                          : 'Indisponible',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (starting)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else if (free)
                const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
