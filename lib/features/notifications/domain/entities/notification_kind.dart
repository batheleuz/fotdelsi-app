/// Type de notification push — miroir des kinds backend.
enum NotificationKind {
  paymentRequest,
  dropoffRegistered,
  washReady,
  unknown;

  static NotificationKind fromApi(String? value) => switch (value) {
        'PAYMENT_REQUEST' => paymentRequest,
        'DROPOFF_REGISTERED' => dropoffRegistered,
        'WASH_READY' => washReady,
        _ => unknown,
      };
}
