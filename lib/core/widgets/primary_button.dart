import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_curves.dart';
import '../theme/app_radius.dart';

/// Bouton principal réutilisable dans toute l'application.
///
/// Inclut une micro-animation de pression (scale) prête à servir partout.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expanded = true,
    this.enabled = true,
    this.loading = false,
    this.backgroundColor = AppColors.primary,
    this.foregroundColor = AppColors.onPrimary,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool expanded;
  final bool enabled;
  final bool loading;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  void _setPressed(bool value) => setState(() => _pressed = value);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => _setPressed(true) : null,
      onTapUp: widget.enabled ? (_) => _setPressed(false) : null,
      onTapCancel: widget.enabled ? () => _setPressed(false) : null,
      onTap: widget.enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: AppDurations.fast,
        curve: AppCurves.standard,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          height: 54,
          width: widget.expanded ? double.infinity : null,
          padding: widget.expanded
              ? null
              : const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: widget.enabled
                ? widget.backgroundColor
                : widget.backgroundColor.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          alignment: Alignment.center,
          child: widget.loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: widget.foregroundColor,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: widget.foregroundColor,
                      ),
                    ),
                    if (widget.icon != null) ...[
                      const SizedBox(width: 8),
                      Icon(
                        widget.icon,
                        color: widget.foregroundColor,
                        size: 20,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
