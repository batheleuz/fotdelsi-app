import 'package:flutter/animation.dart';

/// Durées et courbes d'animation centralisées.
///
/// Préparées pour enrichir les transitions plus tard sans toucher aux widgets :
/// il suffira d'ajuster ces valeurs ou d'en ajouter de nouvelles.
abstract final class AppDurations {
  const AppDurations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 350);
  static const Duration slow = Duration(milliseconds: 600);

  /// Cycle des animations en boucle (bulles flottantes, etc.).
  static const Duration ambient = Duration(milliseconds: 2800);
}

/// Courbes d'animation standardisées.
abstract final class AppCurves {
  const AppCurves._();

  static const Curve standard = Curves.easeOutCubic;
  static const Curve emphasized = Curves.easeOutBack;
  static const Curve gentle = Curves.easeInOut;
}
