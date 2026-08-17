/// Moyen de paiement mobile (SOFTPAY PayDunya).
///
/// Couche domaine — correspond à `payments.provider` en BDD.
enum PaymentProvider {
  wave,
  orangeMoney;

  /// Valeur envoyée au backend dans le corps de `POST /payments/initiate`.
  String get apiValue => switch (this) {
    PaymentProvider.wave => 'WAVE',
    PaymentProvider.orangeMoney => 'ORANGE_MONEY',
  };
}
