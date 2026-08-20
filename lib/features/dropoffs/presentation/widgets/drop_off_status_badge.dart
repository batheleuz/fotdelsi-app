import 'package:flutter/material.dart';

import 'package:fotdelsi/core/motion/app_motion.dart';
import 'package:fotdelsi/core/motion/status_transition.dart';
import 'package:fotdelsi/core/theme/app_curves.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import '../../domain/entities/drop_off_status.dart';
import '../utils/drop_off_status_presentation.dart';

/// Badge réutilisable d'un statut de dépôt : pastille + libellé.
///
/// Le statut change souvent **sans geste de l'utilisateur** — le serveur pousse
/// la transition pendant que l'agent regarde sa file. Le badge accompagne donc
/// le changement : la couleur de fond glisse d'une teinte à l'autre, le libellé
/// se substitue en fondu. C'est ce qui distingue un écran qui vit d'un écran
/// qui s'est rechargé dans le dos de celui qui le regarde.
class DropOffStatusBadge extends StatelessWidget {
  const DropOffStatusBadge({
    super.key,
    required this.status,
    this.pulse = false,
  });

  final DropOffStatus status;

  /// Fait respirer la pastille, pour un dépôt dont la machine tourne.
  ///
  /// Ce paramètre existait sans être ni lu ni transmis par personne. Il porte
  /// maintenant ce que son nom annonçait.
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.duration(context, AppDurations.fast),
      curve: AppCurves.standard,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: status.softColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseDot(color: status.dotColor, active: pulse),
          const SizedBox(width: 5),
          // Le libellé seul est échangé : la pastille, elle, garde son
          // battement au lieu de repartir de zéro à chaque transition.
          StatusTransition(
            statusKey: status,
            child: Text(
              status.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: status.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
