import 'package:flutter/material.dart';

import '../../domain/entities/machine.dart';
import '../utils/machine_status_presentation.dart';

/// Pastille colorée d'état (Disponible / En cours / Hors ligne).
class MachineStatusBadge extends StatelessWidget {
  const MachineStatusBadge({super.key, required this.status});

  final MachineStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.softColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 12, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: status.color,
            ),
          ),
        ],
      ),
    );
  }
}
