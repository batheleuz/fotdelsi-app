import 'package:flutter/material.dart';

/// Palette de la marque FOT DELSI.
///
/// Source unique de vérité pour les couleurs. Aucune couleur ne doit être
/// codée en dur ailleurs dans l'application : toujours référencer [AppColors].
abstract final class AppColors {
  const AppColors._();

  // --- Marque ---
  /// Bleu FOT DELSI — couleur principale (logo, boutons, illustrations).
  static const Color primary = Color(0xFF1747A6);
  static const Color primaryDark = Color(0xFF0F2E6E);
  static const Color primaryLight = Color(0xFF3D6FD4);

  /// Orange FOT DELSI — accent (indicateurs actifs, détails).
  static const Color secondary = Color(0xFFF47B20);
  static const Color secondaryLight = Color(0xFFFF9A4D);

  /// Bleu ciel — bulles, éléments décoratifs.
  static const Color accent = Color(0xFF3FA9F5);

  // --- Surfaces ---
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  /// Fond doux des zones d'illustration.
  static const Color surfaceTint = Color(0xFFEAF1FB);
  static const Color bubble = Color(0xFFDCEBFF);

  // --- Texte ---
  static const Color textPrimary = Color(0xFF0E2342);
  static const Color textSecondary = Color(0xFF5A6B85);
  static const Color textTertiary = Color(0xFF9AA7BD);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // --- Divers ---
  static const Color border = Color(0xFFE3E9F2);
  static const Color indicatorInactive = Color(0xFFD7E0EE);

  // --- États (préparés pour la suite) ---
  static const Color success = Color(0xFF1D9E75);
  static const Color warning = Color(0xFFEF9F27);
  static const Color danger = Color(0xFFE24B4A);
}
