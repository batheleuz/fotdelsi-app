import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Entrée d'un [AppPopupMenu].
class AppMenuEntry {
  const AppMenuEntry({
    required this.icon,
    required this.label,
    required this.onSelected,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelected;
  final bool destructive;
}

/// Menu contextuel custom (rendu identique iOS / Android), ancré sous le bouton.
///
/// N'utilise pas le `PopupMenuButton` de Material : carte arrondie, ombre
/// douce, séparateurs fins, animation d'ouverture (fondu + léger zoom depuis
/// le coin haut-droit), fermeture au tap extérieur.
class AppPopupMenu extends StatefulWidget {
  const AppPopupMenu({
    super.key,
    required this.entries,
    this.icon = Icons.more_vert,
    this.iconColor,
  });

  final List<AppMenuEntry> entries;
  final IconData icon;
  final Color? iconColor;

  @override
  State<AppPopupMenu> createState() => _AppPopupMenuState();
}

class _AppPopupMenuState extends State<AppPopupMenu> {
  OverlayEntry? _entry;

  void _open() {
    final box = context.findRenderObject() as RenderBox;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);

    final top = topLeft.dy + box.size.height + 6;
    final right = overlay.size.width - (topLeft.dx + box.size.width);

    _entry = OverlayEntry(
      builder: (_) => _MenuOverlay(
        top: top,
        right: right,
        entries: widget.entries,
        onClose: _close,
      ),
    );
    Overlay.of(context).insert(_entry!);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(widget.icon,
          color: widget.iconColor ?? AppColors.textSecondary),
      onPressed: _open,
    );
  }
}

class _MenuOverlay extends StatelessWidget {
  const _MenuOverlay({
    required this.top,
    required this.right,
    required this.entries,
    required this.onClose,
  });

  final double top;
  final double right;
  final List<AppMenuEntry> entries;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClose,
            child: const SizedBox.expand(),
          ),
        ),
        Positioned(
          top: top,
          right: right,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            builder: (_, t, child) => Opacity(
              opacity: t,
              child: Transform.scale(
                scale: 0.9 + 0.1 * t,
                alignment: Alignment.topRight,
                child: child,
              ),
            ),
            child: _card(),
          ),
        ),
      ],
    );
  }

  Widget _card() {
    return Material(
      color: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 210, maxWidth: 280),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md - 2),
            border: Border.all(color: AppColors.border, width: 0.5),
            boxShadow: const [
              BoxShadow(
                color: Color(0x1A0E2342),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: IntrinsicWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0)
                    const Divider(
                        height: 0.5, thickness: 0.5, color: AppColors.border),
                  _MenuItem(entry: entries[i], onClose: onClose),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  const _MenuItem({required this.entry, required this.onClose});

  final AppMenuEntry entry;
  final VoidCallback onClose;

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  /// Gris très clair (proche du blanc), façon menu natif iOS, au press.
  static const _pressedColor = Color(0xFFEFF0F3);

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.entry.destructive ? AppColors.danger : AppColors.textPrimary;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        // Pas de setState ici : l'overlay est retiré juste après.
        widget.onClose();
        widget.entry.onSelected();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        color: _pressed ? _pressedColor : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(widget.entry.icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.entry.label,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
