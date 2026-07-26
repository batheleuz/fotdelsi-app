import 'package:flutter/material.dart';

import 'package:fotdelsi/core/constants/app_icons.dart';
import 'package:fotdelsi/core/theme/app_colors.dart';

/// Barre supérieure du scanner (fond sombre) : retour + bascule lampe torche.
class ScanTopBar extends StatelessWidget {
  const ScanTopBar({
    super.key,
    required this.torchOn,
    required this.onBack,
    required this.onToggleTorch,
  });

  final bool torchOn;
  final VoidCallback onBack;
  final VoidCallback onToggleTorch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassButton(icon: AppIcons.back, onTap: onBack),
          _GlassButton(
            icon: torchOn ? AppIcons.flashOn : AppIcons.flashOff,
            active: torchOn,
            onTap: onToggleTorch,
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.icon,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: active
              ? AppColors.secondary
              : Colors.white.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
