import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'pulsing_dot.dart';

/// Pastille d'état de la connexion temps réel (WebSocket).
class ConnectionStatusChip extends StatelessWidget {
  const ConnectionStatusChip({super.key, required this.connected});

  final bool connected;

  @override
  Widget build(BuildContext context) {
    final color = connected ? AppColors.success : AppColors.textTertiary;
    final bg = connected
        ? const Color(0xFFE1F5EE)
        : const Color(0xFFEEF1F6);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (connected)
            PulsingDot(color: color)
          else
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const SizedBox(width: 6),
          Text(
            connected ? 'En direct' : 'Hors ligne',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: connected ? const Color(0xFF0F6E56) : color,
            ),
          ),
        ],
      ),
    );
  }
}
