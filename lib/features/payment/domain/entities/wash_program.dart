/// Taille de lavage proposée (programme libre-service sur place).
enum WashSize { kg12, kg15, kg20 }

/// Programme de lavage et son tarif (FCFA).
///
/// Couche domaine — aucune dépendance à Flutter.
class WashProgram {
  const WashProgram({required this.size, required this.price});

  final WashSize size;
  final int price;
}
