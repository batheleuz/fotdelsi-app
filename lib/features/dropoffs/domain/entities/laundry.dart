import 'package:equatable/equatable.dart';

import 'laundry_type.dart';

/// Description du linge d'un dépôt.
class Laundry extends Equatable {
  const Laundry({
    required this.pieces,
    required this.types,
    this.instructions = '',
  });

  final int pieces;
  final List<LaundryType> types;
  final String instructions;

  /// Libellé court des types, ex. « Couleur, Blanc ».
  String get typesLabel => types.map((t) => t.label).join(', ');

  @override
  List<Object?> get props => [pieces, types, instructions];
}
