import 'package:flutter/material.dart';

import 'package:fotdelsi/core/constants/app_icons.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';
import 'package:fotdelsi/core/theme/app_curves.dart';

/// Pastille de succès animée (cercle teinté + coche qui apparaît en scale).
class SuccessCheckBadge extends StatefulWidget {
  const SuccessCheckBadge({super.key, this.size = 96});

  final double size;

  @override
  State<SuccessCheckBadge> createState() => _SuccessCheckBadgeState();
}

class _SuccessCheckBadgeState extends State<SuccessCheckBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppDurations.slow,
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pop = CurvedAnimation(parent: _controller, curve: AppCurves.emphasized);
    return SizedBox(
      width: widget.size + 28,
      height: widget.size + 28,
      child: Stack(
        alignment: Alignment.center,
        children: [
          FadeTransition(
            opacity: _controller,
            child: Container(
              width: widget.size + 28,
              height: widget.size + 28,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          ScaleTransition(
            scale: pop,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: const BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
              ),
              child: Icon(AppIcons.check,
                  size: widget.size * 0.5, color: AppColors.onPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
