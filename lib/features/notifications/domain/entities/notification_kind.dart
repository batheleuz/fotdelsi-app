/// Type de notification push — miroir des kinds backend.
enum NotificationKind {
  paymentRequest,
  dropoffRegistered,

  /// Le lavage est fini, un séchage reste à lancer. Distinct de
  /// [washCycleDone] : il reste un geste, et le tap doit y mener.
  washToDry,

  /// Le cycle entier est terminé.
  washCycleDone,

  /// Un dépôt confié au comptoir est prêt à être récupéré. Ne pas confondre
  /// avec [washCycleDone] : ni le même écran, ni le même moment.
  washReady,
  unknown;

  static NotificationKind fromApi(String? value) => switch (value) {
    'PAYMENT_REQUEST' => paymentRequest,
    'DROPOFF_REGISTERED' => dropoffRegistered,
    'WASH_TO_DRY' => washToDry,
    'WASH_CYCLE_DONE' => washCycleDone,
    'WASH_READY' => washReady,
    _ => unknown,
  };
}
