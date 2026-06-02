import 'package:flutter/material.dart';

import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_curves.dart';

/// Bulle décorative flottante (animation ambiante en boucle).
///
/// Composant interne à l'onboarding — non réutilisé ailleurs.
class _Bubble {
  const _Bubble({
    required this.alignment,
    required this.size,
    required this.color,
    required this.delay,
  });

  final Alignment alignment;
  final double size;
  final Color color;
  final double delay;
}

/// Couche de bulles flottantes posée derrière l'illustration.
class OnboardingBubbles extends StatefulWidget {
  const OnboardingBubbles({super.key});

  @override
  State<OnboardingBubbles> createState() => _OnboardingBubblesState();
}

class _OnboardingBubblesState extends State<OnboardingBubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  static const List<_Bubble> _bubbles = [
    _Bubble(
      alignment: Alignment(-0.7, -0.6),
      size: 18,
      color: AppColors.secondary,
      delay: 0,
    ),
    _Bubble(
      alignment: Alignment(0.8, -0.4),
      size: 14,
      color: AppColors.accent,
      delay: 0.3,
    ),
    _Bubble(
      alignment: Alignment(0.6, 0.7),
      size: 20,
      color: AppColors.secondary,
      delay: 0.6,
    ),
    _Bubble(
      alignment: Alignment(-0.8, 0.5),
      size: 12,
      color: AppColors.accent,
      delay: 0.45,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.ambient,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Stack(
          children: [
            for (final bubble in _bubbles)
              Align(
                alignment: bubble.alignment,
                child: Transform.translate(
                  offset: Offset(
                    0,
                    -10 *
                        Curves.easeInOut.transform(
                          (_controller.value + bubble.delay) % 1.0,
                        ),
                  ),
                  child: Container(
                    width: bubble.size,
                    height: bubble.size,
                    decoration: BoxDecoration(
                      color: bubble.color.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
