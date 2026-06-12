import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';

/// Réponse du backend après initiation d'un paiement.
///
/// Le `sessionId` sert de référence unique pour suivre le statut
/// via `GET /sessions/:token`.
class PaymentSession {
  const PaymentSession({
    required this.provider,
    required this.machineId,
    required this.paymentId,
    required this.externalRef,
    required this.amount,
    required this.reservedUntil,
    required this.washSessionToken,

    // Wave URL
    this.redirectUrl,

    // Orange Money URLs
    this.maxitUrl,
    this.omUrl,
    this.qrCodeUrl,
  });

  final PaymentProvider provider;

  /// Machine ciblée par cette session — renvoyée par le backend.
  final String machineId;
  final String paymentId;
  final String externalRef;
  final int amount;
  final String reservedUntil;
  final String washSessionToken;

  final String? redirectUrl;
  
  final String? maxitUrl;
  final String? omUrl;
  final String? qrCodeUrl;
}
