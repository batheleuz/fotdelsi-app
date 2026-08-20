import 'dart:async';

import 'package:flutter/widgets.dart';

import 'package:fotdelsi/core/theme/app_curves.dart';
import 'app_motion.dart';

/// Fait entrer son enfant : fondu + léger glissement vers le haut.
///
/// Sert aux éléments qui arrivent à l'écran — cartes d'une liste, sections
/// d'une page. Passer [index] décale l'entrée pour obtenir une cascade ;
/// le décalage est plafonné par [AppMotion.maxStaggeredItems].
///
/// L'animation ne se joue **qu'une fois**, au premier affichage. Sans cela,
/// chaque rafraîchissement d'une liste temps réel — et ces listes se
/// rafraîchissent au moindre événement WebSocket — ferait re-clignoter tout
/// l'écran. C'est la différence entre une application vivante et une
/// application instable.
class EntranceFade extends StatefulWidget {
  const EntranceFade({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = AppDurations.normal,
    this.offset = AppMotion.slideOffset,
  });

  final Widget child;

  /// Position dans la liste, pour la cascade. `0` = pas de retard.
  final int index;
  final Duration duration;

  /// Distance parcourue vers le haut. Négatif pour entrer par le haut.
  final double offset;

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _delay;

  @override
  void initState() {
    super.initState();
    // `addPostFrameCallback` : `MediaQuery` n'est pas lisible depuis
    // `initState`, et c'est lui qui dit si l'utilisateur veut des animations.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (AppMotion.reduced(context)) {
        _controller.value = 1;
        return;
      }

      final delay = AppMotion.delayForIndex(widget.index);
      if (delay == Duration.zero) {
        _controller.forward();
      } else {
        _delay = Timer(delay, () {
          if (mounted) _controller.forward();
        });
      }
    });
  }

  @override
  void dispose() {
    _delay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppCurves.standard,
    );

    return AnimatedBuilder(
      animation: curved,
      // L'enfant est construit une seule fois et réutilisé à chaque image :
      // une carte de dépôt n'a aucune raison d'être reconstruite soixante fois
      // par seconde pour se déplacer de quatorze pixels.
      child: widget.child,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - curved.value)),
          child: child,
        ),
      ),
    );
  }
}

/// Apparition et disparition d'un élément conditionnel, sans à-coup.
///
/// Remplace le `if (vide) return SizedBox.shrink()` qui parsème l'accueil
/// agent : l'entrée surgissait d'un coup et poussait tout le contenu en
/// dessous. Ici la hauteur se déplie en même temps que l'opacité monte.
///
/// [visible] pilote les deux sens — c'est ce qui permet à une ligne de partir
/// proprement quand un client paie, plutôt que de disparaître entre deux
/// images.
///
/// Le dernier contenu visible est **conservé** pendant la disparition. Sans
/// cela il n'y aurait rien à faire fondre : le widget parent, lui, s'est déjà
/// reconstruit avec un compteur à zéro, et on verrait « 0 client doit apporter
/// son linge » s'effacer lentement. On fait donc sortir ce que l'utilisateur
/// avait sous les yeux.
class AnimatedReveal extends StatefulWidget {
  const AnimatedReveal({
    super.key,
    required this.visible,
    required this.child,
    this.duration = AppDurations.normal,
  });

  final bool visible;
  final Widget child;
  final Duration duration;

  @override
  State<AnimatedReveal> createState() => _AnimatedRevealState();
}

class _AnimatedRevealState extends State<AnimatedReveal> {
  /// Ce qui était affiché quand [AnimatedReveal.visible] valait encore `true`.
  Widget? _lastVisible;

  @override
  Widget build(BuildContext context) {
    if (widget.visible) _lastVisible = widget.child;

    return AnimatedCrossFade(
      // `AnimatedCrossFade` anime la taille ET l'opacité entre ses deux
      // enfants : c'est exactement le repli qu'on veut, sans piloter nous-mêmes
      // un contrôleur.
      firstChild: _lastVisible ?? const SizedBox.shrink(),
      secondChild: const SizedBox(width: double.infinity),
      crossFadeState: widget.visible
          ? CrossFadeState.showFirst
          : CrossFadeState.showSecond,
      duration: AppMotion.duration(context, widget.duration),
      sizeCurve: AppCurves.standard,
      firstCurve: AppCurves.standard,
      secondCurve: AppCurves.standard,
      alignment: Alignment.topCenter,
    );
  }
}
