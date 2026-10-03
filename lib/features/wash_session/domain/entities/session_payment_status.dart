/// Statut du paiement lié à la session de lavage (miroir du backend).
///
/// `pendingPayment` : paiement initié, en attente de confirmation du provider.
/// `confirmed`      : webhook du provider reçu par le backend — à temps ou tardif.
/// `failed`         : paiement échoué ou annulé par le provider.
/// `expired`        : paiement expiré avant confirmation.
/// `anomaly`        : incohérence détectée (montant, transition illégale…).
enum SessionPaymentStatus {
  pendingPayment,
  confirmed,
  failed,
  expired,
  anomaly;

  /// Mappe la valeur `paymentStatus` du backend
  /// (`PENDING | CONFIRMED | LATE_CONFIRMED | FAILED | EXPIRED | ANOMALY`).
  static SessionPaymentStatus fromApi(String value) => switch (value) {
    'CONFIRMED' => confirmed,
    'LATE_CONFIRMED' => confirmed,
    'FAILED' => failed,
    'EXPIRED' => expired,
    'ANOMALY' => anomaly,
    _ => pendingPayment,
  };

  /// Le paiement a définitivement échoué (plus aucune action possible).
  bool get isTerminalFailure =>
      this == failed || this == expired || this == anomaly;
}
