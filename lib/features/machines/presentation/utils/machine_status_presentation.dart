import 'package:flutter/material.dart';

import '../../domain/entities/machine.dart';

/// Mapping présentation des états machine vers couleurs/libellés/icônes.
/// Garde la couche domaine indépendante de Flutter.
extension MachineStatusX on MachineStatus {
  Color get color => switch (this) {
        MachineStatus.available => const Color(0xFF1D9E75),
        MachineStatus.inUse => const Color(0xFFC26A1A),
        MachineStatus.offline => const Color(0xFF7C8AA1),
      };

  Color get softColor => switch (this) {
        MachineStatus.available => const Color(0xFFE1F5EE),
        MachineStatus.inUse => const Color(0xFFFBECE2),
        MachineStatus.offline => const Color(0xFFEEF1F6),
      };

  String get label => switch (this) {
        MachineStatus.available => 'Disponible',
        MachineStatus.inUse => 'En cours',
        MachineStatus.offline => 'Hors ligne',
      };

  IconData get icon => switch (this) {
        MachineStatus.available => Icons.check_circle_outline_rounded,
        MachineStatus.inUse => Icons.autorenew_rounded,
        MachineStatus.offline => Icons.power_off_rounded,
      };
}

/// Mapping présentation du type de machine.
extension MachineTypeX on MachineType {
  IconData get icon => switch (this) {
        MachineType.washer => Icons.local_laundry_service_rounded,
        MachineType.dryer => Icons.dry_cleaning_rounded,
      };
}
