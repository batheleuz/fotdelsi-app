import 'package:flutter/widgets.dart';

import 'package:fotdelsi/core/theme/app_curves.dart';

/// Règles de mouvement communes à toute l'application.
///
/// Le vocabulaire (durées, courbes) vit déjà dans [AppDurations] et
/// [AppCurves] ; ce fichier ajoute ce qui manquait pour s'en servir sans
/// réécrire la même logique dans chaque écran.
///
/// Deux principes tiennent l'ensemble :
///
///  1. **Une animation accompagne un changement, elle ne le décore pas.** Un
///     élément qui apparaît glisse depuis le bas ; un élément qui disparaît
///     s'efface sur place. Le geste raconte ce qui vient de se passer.
///  2. **Le mouvement est court.** Sur un écran d'agent qu'on consulte entre
///     deux clients, une transition qu'on attend est une transition ratée.
abstract final class AppMotion {
  const AppMotion._();

  /// Décalage vertical d'entrée, en pixels logiques.
  ///
  /// Volontairement faible : au-delà, l'élément traverse l'écran au lieu de
  /// s'y poser, et la liste donne le tournis quand plusieurs lignes entrent.
  static const double slideOffset = 14;

  /// Retard entre deux éléments consécutifs d'une liste.
  static const Duration stagger = Duration(milliseconds: 45);

  /// Au-delà, on cesse de décaler.
  ///
  /// Sans ce plafond, la dixième ligne d'une file d'attente attendrait une
  /// demi-seconde avant d'exister. Une entrée en cascade doit se sentir sur
  /// les premières lignes, pas se subir sur les dernières.
  static const int maxStaggeredItems = 6;

  /// Retard d'entrée pour la position [index] d'une liste.
  static Duration delayForIndex(int index) =>
      stagger * index.clamp(0, maxStaggeredItems);

  /// L'utilisateur a-t-il demandé à réduire les animations ?
  ///
  /// Réglage système (iOS « Réduire les animations », Android « Supprimer les
  /// animations »). On le respecte partout : ces réglages sont souvent activés
  /// pour des raisons médicales — vertiges, troubles vestibulaires — et une
  /// application qui les ignore devient pénible à utiliser, pas seulement
  /// bavarde.
  static bool reduced(BuildContext context) =>
      MediaQuery.disableAnimationsOf(context);

  /// Durée effective : nulle si l'utilisateur a réduit les animations.
  ///
  /// Renvoyer zéro plutôt que sauter le widget garde un seul chemin de code —
  /// l'état final est identique, il est simplement atteint tout de suite.
  static Duration duration(BuildContext context, Duration wanted) =>
      reduced(context) ? Duration.zero : wanted;
}
