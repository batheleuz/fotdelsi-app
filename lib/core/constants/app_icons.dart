import 'package:iconsax/iconsax.dart';

/// Set d'icônes centralisé (Iconsax — lignes fines, moderne).
///
/// Toute l'app référence [AppIcons] et jamais Iconsax directement : changer de
/// bibliothèque d'icônes ne touche que ce fichier. Si un nom de constante
/// diffère selon la version d'`iconsax`, c'est ici (et seulement ici) qu'on
/// l'ajuste.
abstract final class AppIcons {
  const AppIcons._();

  // Navigation
  static const back = Iconsax.arrow_left_2;

  // Scan
  static const scan = Iconsax.scan_barcode;
  static const flashOn = Iconsax.flash_1;
  static const flashOff = Iconsax.flash_slash;
  static const keyboard = Iconsax.keyboard;

  // Sélection / état
  static const check = Iconsax.tick_circle;
  static const lock = Iconsax.lock_1;

  // Programmes
  static const water = Iconsax.drop;
  static const drying = Iconsax.wind;
}
