import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Affiche une confirmation custom, proche des dialogs iOS, sans dépendre du
/// rendu Material natif.
Future<bool> showAppConfirmationDialog({
  required BuildContext context,
  required String title,
  required String message,
  String cancelLabel = 'Annuler',
  String confirmLabel = 'Confirmer',
  bool destructive = false,
}) async {
  final result = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: cancelLabel,
    barrierColor: Colors.black.withValues(alpha: 0.32),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (context, animation, secondaryAnimation) =>
        _AppConfirmationDialog(
          title: title,
          message: message,
          cancelLabel: cancelLabel,
          confirmLabel: confirmLabel,
          destructive: destructive,
        ),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );

  return result ?? false;
}

class _AppConfirmationDialog extends StatelessWidget {
  const _AppConfirmationDialog({
    required this.title,
    required this.message,
    required this.cancelLabel,
    required this.confirmLabel,
    required this.destructive,
  });

  final String title;
  final String message;
  final String cancelLabel;
  final String confirmLabel;
  final bool destructive;

  static const _divider = Color(0xFFD8DDE8);

  @override
  Widget build(BuildContext context) {
    final confirmColor = destructive ? AppColors.danger : AppColors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 42),
        child: Material(
          color: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x260E2342),
                    blurRadius: 28,
                    offset: Offset(0, 14),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 310),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 21, 22, 18),
                      child: Column(
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 0.5, thickness: 0.5, color: _divider),
                    SizedBox(
                      height: 48,
                      child: Row(
                        children: [
                          Expanded(
                            child: _DialogAction(
                              label: cancelLabel,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                              onPressed: () => Navigator.pop(context, false),
                            ),
                          ),
                          const VerticalDivider(
                            width: 0.5,
                            thickness: 0.5,
                            color: _divider,
                          ),
                          Expanded(
                            child: _DialogAction(
                              label: confirmLabel,
                              color: confirmColor,
                              fontWeight: FontWeight.w700,
                              onPressed: () => Navigator.pop(context, true),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DialogAction extends StatefulWidget {
  const _DialogAction({
    required this.label,
    required this.color,
    required this.fontWeight,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final FontWeight fontWeight;
  final VoidCallback onPressed;

  @override
  State<_DialogAction> createState() => _DialogActionState();
}

class _DialogActionState extends State<_DialogAction> {
  static const _pressedColor = Color(0xFFEFF0F3);

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => widget.onPressed(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        alignment: Alignment.center,
        color: _pressed ? _pressedColor : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.label,
            maxLines: 1,
            style: TextStyle(
              color: widget.color,
              fontSize: 16,
              fontWeight: widget.fontWeight,
            ),
          ),
        ),
      ),
    );
  }
}
