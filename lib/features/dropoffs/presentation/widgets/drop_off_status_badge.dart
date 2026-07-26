import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_radius.dart';
import '../../domain/entities/drop_off_status.dart';
import '../utils/drop_off_status_presentation.dart';

/// Badge réutilisable d'un statut de dépôt : pastille + libellé.
class DropOffStatusBadge extends StatelessWidget {
  const DropOffStatusBadge({super.key, required this.status, this.pulse = false});

  final DropOffStatus status;
  final bool pulse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: status.softColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: status.dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: status.textColor,
            ),
          ),
        ],
      ),
    );
  }
}
