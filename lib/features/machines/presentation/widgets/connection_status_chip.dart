import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/websocket/ws_connection_status.dart';
import 'pulsing_dot.dart';

/// Pastille d'état de la connexion temps réel (WebSocket).
///
/// Trois états : connecté (vert + dot pulsant), reconnexion en cours (orange
/// + indicateur rotatif), déconnecté (gris + dot statique).
class ConnectionStatusChip extends StatelessWidget {
  const ConnectionStatusChip({super.key, required this.status});

  final WsConnectionStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      WsConnectionStatus.connected => _Chip(
          bg: const Color(0xFFE1F5EE),
          dot: PulsingDot(color: AppColors.success),
          label: 'En direct',
          labelColor: const Color(0xFF0F6E56),
        ),
      WsConnectionStatus.reconnecting => const _Chip(
          bg: Color(0xFFFFF3E0),
          dot: _SpinnerDot(color: Color(0xFFE65100)),
          label: 'Reconnexion…',
          labelColor: Color(0xFFE65100),
        ),
      WsConnectionStatus.disconnected => _Chip(
          bg: const Color(0xFFEEF1F6),
          dot: _StaticDot(color: AppColors.textTertiary),
          label: 'Hors ligne',
          labelColor: AppColors.textTertiary,
        ),
    };
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.bg,
    required this.dot,
    required this.label,
    required this.labelColor,
  });

  final Color bg;
  final Widget dot;
  final String label;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          dot,
          const SizedBox(width: 6),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

class _StaticDot extends StatelessWidget {
  const _StaticDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Petit indicateur rotatif pour l'état "reconnexion".
class _SpinnerDot extends StatefulWidget {
  const _SpinnerDot({required this.color});
  final Color color;

  @override
  State<_SpinnerDot> createState() => _SpinnerDotState();
}

class _SpinnerDotState extends State<_SpinnerDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 9,
      height: 9,
      child: RotationTransition(
        turns: _ctrl,
        child: CircularProgressIndicator(
          strokeWidth: 1.8,
          color: widget.color,
        ),
      ),
    );
  }
}
