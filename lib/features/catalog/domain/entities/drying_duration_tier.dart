/// Paliers de durée de séchage paramétrables.
///
/// Barème FOTDELSY :
/// - 15 min -> 1 pièce = 100 pulses EQLink -> 1 500 CFA
/// - 30 min -> 2 pièces = 200 pulses EQLink -> 3 000 CFA
/// - 45 min -> 3 pièces = 300 pulses EQLink -> 4 500 CFA (durée de base incluse par défaut dans les formules)
/// - 1h (60 min) -> 4 pièces = 400 pulses EQLink -> 5 000 CFA
enum DryingDurationTier {
  m15(minutes: 15, pulses: 100, basePrice: 1500, label: '15 minutes'),
  m30(minutes: 30, pulses: 200, basePrice: 3000, label: '30 minutes'),
  m45(minutes: 45, pulses: 300, basePrice: 4500, label: '45 minutes'),
  m60(minutes: 60, pulses: 400, basePrice: 5000, label: '1 heure');

  const DryingDurationTier({
    required this.minutes,
    required this.pulses,
    required this._basePrice,
    required this.label,
  });

  final int minutes;
  final int pulses;
  final int _basePrice;
  final String label;

  static const DryingDurationTier defaultTier = DryingDurationTier.m45;
  static DryingDurationTier configuredDefault = DryingDurationTier.m45;
  static final Map<int, int> customPrices = {};

  int get price => customPrices[minutes] ?? _basePrice;

  static void configure({Map<int, int>? prices, int? defaultMinutes}) {
    if (prices != null) {
      customPrices.addAll(prices);
    }
    if (defaultMinutes != null) {
      configuredDefault = fromMinutes(defaultMinutes);
    }
  }

  static void resetDefaults() {
    customPrices.clear();
    configuredDefault = defaultTier;
  }

  static DryingDurationTier fromMinutes(int? minutes) {
    if (minutes == null) return configuredDefault;
    for (final tier in values) {
      if (tier.minutes == minutes) return tier;
    }
    return configuredDefault;
  }

  /// Ajustement par rapport au forfait de base (45 min à 4 500 CFA par défaut)
  /// inclus dans les formules catalogue comprenant du séchage.
  int get priceAdjustment => price - configuredDefault.price;
}

