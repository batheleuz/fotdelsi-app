/// Paliers de durée de séchage paramétrables.
///
/// Barème FOTDELSY :
/// - 15 min -> 1 pièce = 100 pulses EQLink -> 1 500 CFA
/// - 30 min -> 2 pièces = 200 pulses EQLink -> 3 000 CFA (durée de base incluse dans les formules)
/// - 45 min -> 3 pièces = 300 pulses EQLink -> 4 500 CFA
/// - 1h (60 min) -> 4 pièces = 400 pulses EQLink -> 5 000 CFA
enum DryingDurationTier {
  m15(minutes: 15, pulses: 100, price: 1500, label: '15 minutes'),
  m30(minutes: 30, pulses: 200, price: 3000, label: '30 minutes'),
  m45(minutes: 45, pulses: 300, price: 4500, label: '45 minutes'),
  m60(minutes: 60, pulses: 400, price: 5000, label: '1 heure');

  const DryingDurationTier({
    required this.minutes,
    required this.pulses,
    required this.price,
    required this.label,
  });

  final int minutes;
  final int pulses;
  final int price;
  final String label;

  static const DryingDurationTier defaultTier = DryingDurationTier.m30;

  static DryingDurationTier fromMinutes(int? minutes) {
    if (minutes == null) return defaultTier;
    for (final tier in values) {
      if (tier.minutes == minutes) return tier;
    }
    return defaultTier;
  }

  /// Ajustement par rapport au forfait de base de 30 min (3 000 CFA)
  /// inclus dans les formules catalogue comprenant du séchage.
  int get priceAdjustment => price - defaultTier.price;
}
