import '../../domain/entities/pending_drop_off_payment.dart';

/// Désérialisation d'une ligne de `GET /drop-offs/pending-payment`.
abstract final class PendingDropOffPaymentModel {
  const PendingDropOffPaymentModel._();

  static PendingDropOffPayment fromJson(Map<String, dynamic> json) {
    return PendingDropOffPayment(
      kind: PendingPaymentKind.fromApi(json['kind'] as String?),
      draftId: json['draftId'] as String?,
      paymentId: json['paymentId'] as String?,
      customerName: json['customerName'] as String? ?? '',
      contactPhone: json['contactPhone'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      // Faute de date, on prend maintenant : le temps d'attente affiché sera
      // faux d'un instant, alors qu'une exception ferait disparaître un dépôt
      // dont le linge est bien au comptoir.
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      state: PendingPaymentState.fromApi(json['state'] as String?),
      formulaCode: json['formulaCode'] as String?,
      formulaLabel: json['formulaLabel'] as String?,
      sizeKg: (json['sizeKg'] as num?)?.toInt(),
      machineId: json['machineId'] as String?,
      machineName: json['machineName'] as String? ??
          (json['machine'] as Map<String, dynamic>?)?['name'] as String?,
      washSessionToken: json['washSessionToken'] as String?,
      provider: json['provider'] as String?,
      redirectUrl: json['redirectUrl'] as String?,
      omUrl: json['omUrl'] as String?,
      maxitUrl: json['maxitUrl'] as String?,
      requestedAt: _date(json['requestedAt']),
      expiresAt: _date(json['expiresAt']),
    );
  }

  static DateTime? _date(Object? raw) =>
      raw is String ? DateTime.tryParse(raw)?.toLocal() : null;
}
