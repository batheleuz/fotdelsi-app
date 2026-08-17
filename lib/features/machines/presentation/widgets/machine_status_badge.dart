import 'package:flutter/material.dart';

import 'package:fotdelsi/core/motion/app_motion.dart';
import 'package:fotdelsi/core/motion/status_transition.dart';
import 'package:fotdelsi/core/theme/app_curves.dart';
import '../../domain/entities/machine.dart';
import '../utils/machine_status_presentation.dart';

/// Pastille colorée d'état (Disponible / En cours / Hors ligne).
///
/// C'est l'affichage le plus mouvant de l'application : l'état vient des
/// relevés EQLink poussés par le serveur, et bascule pendant que le client
/// choisit sa machine. Le fond glisse d'une teinte à l'autre et le libellé se
/// substitue en fondu — sans quoi une machine devenue occupée changeait de
/// couleur entre deux images, juste avant que le client ne la touche.
class MachineStatusBadge extends StatelessWidget {
  const MachineStatusBadge({super.key, required this.status});

  final MachineStatus status;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.duration(context, AppDurations.fast),
      curve: AppCurves.standard,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.softColor,
        borderRadius: BorderRadius.circular(999),
      ),
      // Icône et libellé partent ensemble : ils décrivent le même état, les
      // séparer donnerait un instant où le badge se contredit lui-même.
      child: StatusTransition(
        statusKey: status,
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
      ),
    );
  }
}
