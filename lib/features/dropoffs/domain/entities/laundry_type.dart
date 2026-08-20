/// Type de linge — miroir de l'enum backend `COLORED|WHITE|DELICATE|HEAVY`.
enum LaundryType {
  colored,
  white,
  delicate,
  heavy;

  static LaundryType? fromApi(String value) => switch (value) {
    'COLORED' => colored,
    'WHITE' => white,
    'DELICATE' => delicate,
    'HEAVY' => heavy,
    _ => null,
  };

  String get apiValue => switch (this) {
    colored => 'COLORED',
    white => 'WHITE',
    delicate => 'DELICATE',
    heavy => 'HEAVY',
  };

  String get label => switch (this) {
    colored => 'Couleur',
    white => 'Blanc',
    delicate => 'Délicat',
    heavy => 'Lourd',
  };
}
