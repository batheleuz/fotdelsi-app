import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_radius.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';

/// Récapitulatif du cycle lancé.
class SessionRecapCard extends StatelessWidget {
  const SessionRecapCard({
    super.key,
    required this.machine,
    required this.durationLabel,
    required this.endTimeLabel,
  });

  final Machine machine;
  final String durationLabel;
  final String endTimeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Column(
        children: [
          _Row(label: 'Machine', value: machine.name),
          const _Line(),
          _Row(label: 'Programme', value: "${machine.size}kg"),
          const _Line(),
          _Row(label: 'Durée', value: durationLabel),
          const _Line(),
          _Row(label: 'Fin estimée', value: endTimeLabel),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) =>
      const Divider(height: 0.5, color: AppColors.border);
}
