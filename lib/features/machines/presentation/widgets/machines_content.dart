import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_spacing.dart';
import '../../domain/entities/machine.dart';
import '../utils/machine_status_presentation.dart';
import 'machine_grid.dart';
import 'machines_summary.dart';

/// Contenu scrollable de l'accueil (titre + récap + machines).
///
/// Les machines sont présentées en deux sections distinctes :
/// les laveuses d'abord, puis les sécheuses.
class MachinesContent extends StatelessWidget {
  const MachinesContent({super.key, required this.machines, this.onTapMachine});

  final List<Machine> machines;
  final ValueChanged<Machine>? onTapMachine;

  @override
  Widget build(BuildContext context) {
    final washers =
        machines.where((m) => m.type == MachineType.washer).toList();
    final dryers =
        machines.where((m) => m.type == MachineType.dryer).toList();

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
          if (washers.isNotEmpty)
            _MachineSection(
              title: 'Laveuses',
              icon: MachineType.washer.icon,
              machines: washers,
              onTapMachine: onTapMachine,
            ),
          if (washers.isNotEmpty && dryers.isNotEmpty)
            const SizedBox(height: AppSpacing.xl),
          if (dryers.isNotEmpty)
            _MachineSection(
              title: 'Sécheuses',
              icon: MachineType.dryer.icon,
              machines: dryers,
              onTapMachine: onTapMachine,
            ),
        ],
      ),
    );
  }
}

/// Section d'un type de machine : en-tête (icône + libellé + nombre) + grille.
class _MachineSection extends StatelessWidget {
  const _MachineSection({
    required this.title,
    required this.icon,
    required this.machines,
    this.onTapMachine,
  });

  final String title;
  final IconData icon;
  final List<Machine> machines;
  final ValueChanged<Machine>? onTapMachine;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '${machines.length}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md - 4),
        MachineGrid(machines: machines, onTapMachine: onTapMachine),
      ],
    );
  }
}
