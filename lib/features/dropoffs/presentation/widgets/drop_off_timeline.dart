import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import '../../domain/entities/drop_off.dart';
import '../../domain/entities/drop_off_status.dart';

/// Timeline verticale des étapes d'un dépôt :
/// Reçu → Lavage → Prêt → Remis.
class DropOffTimeline extends StatelessWidget {
  const DropOffTimeline({super.key, required this.dropOff});

  final DropOff dropOff;

  static const _green = Color(0xFF1D9E75);
  static const _future = Color(0xFFD7E0EE);

  int get _activeIndex => switch (dropOff.status) {
        DropOffStatus.received => 0,
        DropOffStatus.inProgress => 1,
        DropOffStatus.ready => 2,
        DropOffStatus.collected => 3,
        _ => 3,
      };

  @override
  Widget build(BuildContext context) {
    final stages = <(String, DateTime?)>[
      ('Reçu', dropOff.receivedAt),
      ('Lavage lancé', dropOff.startedAt),
      ('Prêt', dropOff.readyAt),
      ('Remis au client', dropOff.collectedAt),
    ];

    return Column(
      children: [
        for (var i = 0; i < stages.length; i++)
          _Row(
            label: stages[i].$1,
            time: stages[i].$2,
            done: stages[i].$2 != null,
            active: i == _activeIndex && !dropOff.status.isTerminal,
            isLast: i == stages.length - 1,
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.time,
    required this.done,
    required this.active,
    required this.isLast,
  });

  final String label;
  final DateTime? time;
  final bool done;
  final bool active;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final color = done ? DropOffTimeline._green : DropOffTimeline._future;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: done
                    ? const Icon(Icons.check, size: 11, color: Colors.white)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(width: 2, color: DropOffTimeline._future),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                    color: done || active
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                  ),
                ),
                if (time != null)
                  Text(_hhmm(time!),
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _hhmm(DateTime d) =>
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
