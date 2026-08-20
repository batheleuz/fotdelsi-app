import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';

/// Réponse du backend après initiation d'un paiement.
///
/// Le `sessionId` sert de référence unique pour suivre le statut
/// via `GET /sessions/:token`.
class PaymentSession {
  const PaymentSession({
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

  final PaymentProvider provider;

  /// Machine ciblée, réservation et jeton de démarrage : trois faits propres au
  /// LIBRE-SERVICE.
  ///
  /// `null` pour un dépôt — le linge est confié à l'agent, aucune machine n'est
  /// choisie ni réservée à cet instant. Le serveur les rend nullables depuis
  /// toujours ; les typer non-nullables ici ne tenait que parce que seul le
  /// libre-service lisait cette réponse. Le dépôt s'y est mis, et un `null`
  /// affecté à un `String` fait tomber le parsing.
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

  /// URL à encoder en QR pour qu'un tiers puisse payer depuis SON téléphone.
  ///
  /// On prend le lien de paiement direct de l'opérateur — court, en `https`,
  /// donc scannable par n'importe quel appareil photo :
  ///   Wave : `https://pay.wave.com/c/…?a=4000&c=XOF`
  ///   OM   : `https://sugu.orange-sonatel.com/mp/…`
  ///
  /// Surtout PAS [qrCodeUrl] : malgré son nom, c'est une page HTML PayDunya
  /// qui affiche elle-même un QR (le PNG est encodé en base64 dans sa query
  /// string). L'encoder produirait un QR menant à une page au lieu du paiement.
  String? get qrPayload => switch (provider) {
    PaymentProvider.wave => redirectUrl,
    PaymentProvider.orangeMoney => omUrl ?? maxitUrl,
  };
}
