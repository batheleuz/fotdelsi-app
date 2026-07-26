import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import '../../domain/entities/machine.dart';
import '../utils/machine_status_presentation.dart';
import 'machine_countdown.dart';
import 'machine_status_badge.dart';
import 'machine_type_tile.dart';

/// Carte d'une machine : icône de type, badge d'état, nom, code, et
/// temps restant ou libellé de disponibilité.
class MachineCard extends StatelessWidget {
  const MachineCard({super.key, required this.machine, this.onTap});

  final Machine machine;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final offline = machine.status == MachineStatus.offline;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md + 2),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MachineTypeTile(type: machine.type, offline: offline),
                const Spacer(),
                MachineStatusBadge(status: machine.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              machine.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              machine.code,
              style: const TextStyle(
                fontSize: 11,
                letterSpacing: 0.5,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            _Footer(machine: machine),
          ],
        ),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.machine});

  final Machine machine;

  @override
  Widget build(BuildContext context) {
    if (machine.isInUse) {
      return MachineCountdown(seconds: machine.remainTime);
    }
    return Text(
      machine.status.label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: machine.status.color,
      ),
    );
  }
}
