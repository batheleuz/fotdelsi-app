import 'package:flutter/widgets.dart';

import 'package:fotdelsi/core/theme/app_curves.dart';
import 'app_motion.dart';

/// Fait changer un contenu de statut par fondu enchaîné.
///
/// Les statuts changent **tout seuls**, poussés par le serveur : un dépôt
/// passe de « en cours » à « prêt » alors que l'agent regarde l'écran sans y
/// toucher. Sans transition, le libellé se substitue d'une image à l'autre —
/// et un changement qu'on ne voit pas se produire est un changement qu'on rate.
///
/// [statusKey] identifie le statut courant : c'est lui, et non le contenu du
/// widget, qui déclenche la transition. Un compteur qui change à l'intérieur
/// de la carte ne doit pas la faire clignoter.
class StatusTransition extends StatelessWidget {
  const StatusTransition({
    super.key,
    required this.statusKey,
    required this.child,
    this.duration = AppDurations.fast,
  });

  final Object statusKey;
  final Widget child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppMotion.duration(context, duration),
      switchInCurve: AppCurves.standard,
      switchOutCurve: AppCurves.standard,
      // Les deux libellés se superposent au lieu de se pousser : la carte ne
      // change pas de largeur pendant l'échange.
      layoutBuilder: (current, previous) =>
          Stack(alignment: Alignment.center, children: [...previous, ?current]),
      child: KeyedSubtree(key: ValueKey(statusKey), child: child),
    );
  }
}

/// Pastille qui respire, pour un statut « en cours ».
///
/// Signale qu'une machine tourne en ce moment, sans compte à rebours ni texte
/// supplémentaire. Le battement est lent et l'amplitude faible : une pastille
/// qui clignote vite se lit comme une alerte, pas comme une activité normale.
class PulseDot extends StatefulWidget {
  const PulseDot({
    super.key,
    required this.color,
    this.size = 7,
    this.active = true,
  });

  final Color color;
  final double size;

  /// Immobile quand `false` : seul un statut réellement en cours respire.
  final bool active;

  @override
  State<PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(PulseDot old) {
    super.didUpdateWidget(old);
    if (old.active != widget.active) _sync();
  }

  void _sync() {
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Une animation en boucle tourne indéfiniment : sur un réglage « réduire
    // les animations », c'est exactement le genre de mouvement permanent qu'il
    // faut supprimer, pas seulement raccourcir.
    if (!widget.active || AppMotion.reduced(context)) return _dot(1);

    return FadeTransition(
      opacity: Tween(
        begin: 0.35,
        end: 1.0,
      ).animate(CurvedAnimation(parent: _controller, curve: AppCurves.gentle)),
      child: _dot(1),
    );
  }

  Widget _dot(double opacity) => Container(
    width: widget.size,
    height: widget.size,
    decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
  );
}
