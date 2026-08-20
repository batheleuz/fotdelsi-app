import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';

import '../../domain/entities/payment_session.dart';

/// DTO de la réponse `POST /payments/initiate`.
class PaymentSessionModel {
  const PaymentSessionModel({
    required this.provider,
    required this.paymentId,
    required this.externalRef,
    required this.amount,
    this.machineId,
    this.reservedUntil,
    this.washSessionToken,

    // Wave URL
    this.redirectUrl,

    // Orange Money URLs
    this.maxitUrl,
    this.omUrl,
    this.qrCodeUrl,
  });

  final String provider;
  /// `null` pour un dépôt : aucune machine n'est choisie à cet instant.
  final String? machineId;
  final String paymentId;
  final String externalRef;
  final int amount;
  final String? reservedUntil;
  final String? washSessionToken;

  final String? redirectUrl;

  final String? maxitUrl;
  final String? omUrl;
  final String? qrCodeUrl;

  factory PaymentSessionModel.fromJson(Map<String, dynamic> json) {
    return PaymentSessionModel(
      provider: json["provider"],
      machineId: json["machineId"],
      amount: json['amount'],
      externalRef: json['externalRef'],
      paymentId: json["paymentId"],
      reservedUntil: json["reservedUntil"],
      washSessionToken: json["washSessionToken"],

      redirectUrl: json["redirectUrl"],

      maxitUrl: json["maxitUrl"],
      omUrl: json["omUrl"],
      qrCodeUrl: json["qrCodeUrl"],
    );
  }

  PaymentSession toEntity() => PaymentSession(
    amount: amount,
    machineId: machineId,
    externalRef: externalRef,
    paymentId: paymentId,
    provider: fromApiValue(provider),
    reservedUntil: reservedUntil,
    washSessionToken: washSessionToken,
    maxitUrl: maxitUrl,
    omUrl: omUrl,
    qrCodeUrl: qrCodeUrl,
    redirectUrl: redirectUrl,
  );

  PaymentProvider fromApiValue(String provider) => switch (provider) {
    "WAVE" => PaymentProvider.wave,
    "ORANGE_MONEY" => PaymentProvider.orangeMoney,
    _ => throw ArgumentError("Provider inconnu: $provider"),
  };
}
