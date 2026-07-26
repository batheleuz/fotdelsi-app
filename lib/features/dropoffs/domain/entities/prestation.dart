import 'package:equatable/equatable.dart';

/// Prestation proposée à l'agent lors d'un dépôt.
///
/// Il n'existe pas de catalogue dédié côté backend (le draft ne porte qu'un
/// `amount`) : les prestations sont dérivées des tarifs des machines
/// (taille → prix), seule source de vérité des prix.
class Prestation extends Equatable {
  const Prestation({required this.amount, this.sizeKg});

  /// Montant à facturer, en FCFA (entier).
  final int amount;

  /// Taille associée en kg, si connue (pour le libellé).
  final int? sizeKg;

  @override
  List<Object?> get props => [amount, sizeKg];
}
