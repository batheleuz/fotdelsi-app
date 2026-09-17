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
    this.title,
  });

  final bool torchOn;
  final VoidCallback onBack;
  final VoidCallback onToggleTorch;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _GlassButton(icon: AppIcons.back, onTap: onBack),
          if (title != null)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
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
