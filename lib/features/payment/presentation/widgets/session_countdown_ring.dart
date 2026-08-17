import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';

/// Anneau de progression du cycle + temps restant au centre (MM:SS).
class SessionCountdownRing extends StatelessWidget {
  const SessionCountdownRing({
    super.key,
    required this.remaining,
    required this.total,
    this.size = 180,
  });

  /// Secondes restantes, ou `null` tant que la machine n'a rien annoncé.
  ///
  /// EQLink ne donne aucune durée à la commande de démarrage : il y a donc un
  /// intervalle, entre le lancement et le premier relevé utile, où la durée
  /// est inconnue. L'annoncer comme « 00:00 » dirait au client que son lavage
  /// est fini alors qu'il vient de commencer.
  final int? remaining;
  final int total;
  final double size;

  /// Anneau vide tant que la durée est inconnue : rien à représenter.
  double get _progress {
    final left = remaining;
    if (left == null || total <= 0) return 0;
    return (left / total).clamp(0.0, 1.0);
  }

  String get _formatted {
    final left = remaining;
    if (left == null) return '--:--';
    final m = (left ~/ 60).toString().padLeft(2, '0');
    final s = (left % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(_progress),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatted,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'restantes',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final center = size.center(Offset.zero);
    final radius = (size.width - stroke) / 2;

    final bg = Paint()
      ..color = AppColors.surfaceTint
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, bg);

    final fg = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      fg,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
