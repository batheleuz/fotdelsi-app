import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../../domain/entities/machine.dart';
import 'machine_grid.dart';
import 'machines_summary.dart';

/// Contenu scrollable de l'accueil (titre + récap + grille).
///
/// Partagé tel quel par les trois variantes de state management : seule la
/// récupération de `machines` change d'une variante à l'autre, pas le rendu.
class MachinesContent extends StatelessWidget {
  const MachinesContent({super.key, required this.machines, this.onTapMachine});

  final List<Machine> machines;
  final ValueChanged<Machine>? onTapMachine;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nos machines',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.md - 4),
          MachinesSummary(machines: machines),
          const SizedBox(height: AppSpacing.lg),
          MachineGrid(machines: machines, onTapMachine: onTapMachine),
        ],
      ),
    );
  }
}
