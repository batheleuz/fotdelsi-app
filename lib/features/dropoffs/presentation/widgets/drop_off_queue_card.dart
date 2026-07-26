import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import '../../domain/entities/drop_off.dart';
import '../../domain/entities/drop_off_status.dart';
import '../utils/relative_time.dart';
import 'drop_off_status_badge.dart';

/// Carte d'un dépôt dans la file d'attente agent.
///
/// Le contenu (sous-titre, pied, action principale) s'adapte au statut.
class DropOffQueueCard extends StatelessWidget {
  const DropOffQueueCard({
    super.key,
    required this.dropOff,
    this.onTap,
    this.onAction,
  });

  final DropOff dropOff;
  final VoidCallback? onTap;

  /// Action principale contextuelle (lancer le lavage / remettre au client).
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final highlight = dropOff.status == DropOffStatus.ready;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(
            color: highlight ? const Color(0xFF9FE1CB) : AppColors.border,
            width: 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  dropOff.code,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                DropOffStatusBadge(status: dropOff.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              dropOff.customerName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _subtitle(),
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              _footer(),
              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
            if (onAction != null && _actionLabel() != null) ...[
              const SizedBox(height: 11),
              _ActionButton(
                label: _actionLabel()!,
                icon: _actionIcon()!,
                color: _actionColor(),
                onTap: onAction!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _subtitle() {
    final pieces =
        '${dropOff.laundry.pieces} pièce${dropOff.laundry.pieces > 1 ? 's' : ''}';
    return switch (dropOff.status) {
      DropOffStatus.inProgress => 'Lavage en cours',
      _ => dropOff.laundry.types.isEmpty
          ? pieces
          : '$pieces · ${dropOff.laundry.typesLabel}',
    };
  }

  String _footer() => switch (dropOff.status) {
        DropOffStatus.received => 'déposé ${relativeTimeFr(dropOff.receivedAt)}',
        DropOffStatus.inProgress => dropOff.startedAt != null
            ? 'démarré ${relativeTimeFr(dropOff.startedAt!)}'
            : '',
        DropOffStatus.ready => dropOff.readyAt != null
            ? 'prêt ${relativeTimeFr(dropOff.readyAt!)}'
            : 'prêt à remettre',
        _ => '',
      };

  String? _actionLabel() => switch (dropOff.status) {
        DropOffStatus.received => 'Lancer le lavage',
        DropOffStatus.ready => 'Remettre au client',
        _ => null,
      };

  IconData? _actionIcon() => switch (dropOff.status) {
        DropOffStatus.received => Icons.play_arrow_rounded,
        DropOffStatus.ready => Icons.back_hand_outlined,
        _ => null,
      };

  Color _actionColor() => dropOff.status == DropOffStatus.ready
      ? AppColors.success
      : AppColors.primaryLight;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: AppColors.onPrimary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
