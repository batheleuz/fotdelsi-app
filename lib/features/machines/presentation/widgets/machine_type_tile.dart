import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import '../../domain/entities/machine.dart';
import '../utils/machine_status_presentation.dart';

/// Tuile arrondie portant l'icône du type de machine.
/// Grisée lorsque la machine est hors ligne.
class MachineTypeTile extends StatelessWidget {
  const MachineTypeTile({
    super.key,
    required this.type,
    required this.offline,
  });

  final MachineType type;
  final bool offline;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: offline ? const Color(0xFFEEF1F6) : AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(AppRadius.sm + 5),
      ),
      child: Icon(
        type.icon,
        size: 23,
        color: offline ? AppColors.textTertiary : AppColors.primary,
      ),
    );
  }
}
