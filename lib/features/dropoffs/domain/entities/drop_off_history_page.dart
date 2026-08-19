import 'package:equatable/equatable.dart';

import 'drop_off.dart';

/// Une page d'historique et l'existence d'une suite.
///
/// [hasMore] vient du serveur plutôt que d'une comparaison locale
/// (`length == limit`) : celle-ci se trompe exactement sur le dernier lot
/// plein, et l'écran promettrait alors une page qui n'existe pas.
class DropOffHistoryPage extends Equatable {
  const DropOffHistoryPage({required this.dropOffs, required this.hasMore});

  final List<DropOff> dropOffs;
  final bool hasMore;

  @override
  List<Object?> get props => [dropOffs, hasMore];
}
