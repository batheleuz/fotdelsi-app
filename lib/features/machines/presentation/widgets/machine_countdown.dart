import 'package:flutter/material.dart';

import '../utils/machine_status_presentation.dart';
import '../../domain/entities/machine.dart';

/// Affiche le temps restant d'un cycle au format MM:SS avec une icône horloge.
///
/// Le décompte (décrément des secondes) est piloté par l'état de la page ;
/// ce composant ne fait que formater et afficher.
class MachineCountdown extends StatelessWidget {
  const MachineCountdown({super.key, required this.seconds});

  final int seconds;

  String get _formatted {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final color = MachineStatus.inUse.color;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.schedule_rounded, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          _formatted,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}
