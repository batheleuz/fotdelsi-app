import 'package:flutter/material.dart';

import '../../domain/entities/drop_off_status.dart';

/// Mapping présentation des statuts de dépôt (couleurs / libellés).
/// Garde la couche domaine indépendante de Flutter.
extension DropOffStatusX on DropOffStatus {
  String get label => switch (this) {
        DropOffStatus.received => 'Reçu',
        DropOffStatus.inProgress => 'En cours',
        DropOffStatus.ready => 'Prêt',
        DropOffStatus.collected => 'Remis',
        DropOffStatus.lost => 'Perdu',
        DropOffStatus.refunded => 'Remboursé',
      };

  /// Couleur de la pastille / accent.
  Color get dotColor => switch (this) {
        DropOffStatus.received => const Color(0xFFEF9F27),
        DropOffStatus.inProgress => const Color(0xFF3FA9F5),
        DropOffStatus.ready => const Color(0xFF1D9E75),
        DropOffStatus.collected => const Color(0xFF9AA7BD),
        DropOffStatus.lost => const Color(0xFFE24B4A),
        DropOffStatus.refunded => const Color(0xFF9AA7BD),
      };

  /// Fond doux du badge.
  Color get softColor => switch (this) {
        DropOffStatus.received => const Color(0xFFFDF3E2),
        DropOffStatus.inProgress => const Color(0xFFE7F1FF),
        DropOffStatus.ready => const Color(0xFFE1F6EF),
        DropOffStatus.collected => const Color(0xFFEEF1F6),
        DropOffStatus.lost => const Color(0xFFFCEBEB),
        DropOffStatus.refunded => const Color(0xFFEEF1F6),
      };

  /// Couleur du texte du badge (lisible sur [softColor]).
  Color get textColor => switch (this) {
        DropOffStatus.received => const Color(0xFF8A5A0E),
        DropOffStatus.inProgress => const Color(0xFF155A9E),
        DropOffStatus.ready => const Color(0xFF0F6E56),
        DropOffStatus.collected => const Color(0xFF5A6B85),
        DropOffStatus.lost => const Color(0xFFA32D2D),
        DropOffStatus.refunded => const Color(0xFF5A6B85),
      };
}
