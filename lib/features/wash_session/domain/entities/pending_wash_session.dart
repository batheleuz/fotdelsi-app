import 'package:fotdelsi/features/payment/domain/entities/payment_provider.dart';
import 'package:fotdelsi/features/payment/domain/entities/payment_session.dart';
import 'machine_start_status.dart';
import 'session_payment_status.dart';

/// Session de lavage stockée localement après initiation de paiement.
///
/// Elle passe par plusieurs états :
///   1. [SessionPaymentStatus.pendingPayment] : paiement initié, pas encore confirmé.
///   2. [SessionPaymentStatus.confirmed]      : paiement confirmé → FAB "Démarrer" visible.
///   3. [MachineStartStatus.started]          : machine lancée → FAB "Session en cours".
class PendingWashSession {
  const PendingWashSession({
    required this.washSessionToken,
    required this.machineId,
    required this.provider,
    this.sessionPaymentStatus = SessionPaymentStatus.pendingPayment,
    this.machineStartStatus = MachineStartStatus.pending,
    this.redirectUrl,
    this.maxitUrl,
    this.omUrl,
    this.qrCodeUrl,
  });

  final String washSessionToken;

  /// Machine ciblée — sert à retrouver la machine dans la liste temps réel.
  final String machineId;
  final PaymentProvider provider;

  /// Statut du paiement côté provider (non confirmé → confirmé).
  final SessionPaymentStatus sessionPaymentStatus;

  /// Statut du démarrage de la machine via EQLink.
  final MachineStartStatus machineStartStatus;

  /// Wave — deep-link de redirection.
  final String? redirectUrl;

  /// Orange Money — Maxit (prioritaire).
  final String? maxitUrl;

  /// Orange Money — OM app.
  final String? omUrl;

  /// Orange Money — QR code de secours.
  final String? qrCodeUrl;

  /// URL à encoder en QR pour qu'un tiers paie depuis SON téléphone.
  ///
  /// Le lien direct de l'opérateur, court et en `https` — donc scannable par
  /// n'importe quel appareil photo. Surtout pas [qrCodeUrl] : malgré son nom,
  /// c'est une page HTML PayDunya affichant elle-même un QR (le PNG est encodé
  /// en base64 dans sa query string).
  String? get qrPayload => switch (provider) {
    PaymentProvider.wave => redirectUrl,
    PaymentProvider.orangeMoney => omUrl ?? maxitUrl,
  };

  PendingWashSession copyWith({
    SessionPaymentStatus? sessionPaymentStatus,
    MachineStartStatus? machineStartStatus,
  }) {
    return PendingWashSession(
      washSessionToken: washSessionToken,
      machineId: machineId,
      provider: provider,
      sessionPaymentStatus: sessionPaymentStatus ?? this.sessionPaymentStatus,
      machineStartStatus: machineStartStatus ?? this.machineStartStatus,
      redirectUrl: redirectUrl,
      maxitUrl: maxitUrl,
      omUrl: omUrl,
      qrCodeUrl: qrCodeUrl,
    );
  }

  /// Ne s'applique qu'à un paiement LIBRE-SERVICE : lui seul cible une machine
  /// et porte un jeton de démarrage. Un dépôt n'en a aucun — son linge est
  /// confié à l'agent, qui choisira la machine plus tard.
  factory PendingWashSession.fromPaymentSession(PaymentSession session) {
    return PendingWashSession(
      washSessionToken: session.washSessionToken!,
      machineId: session.machineId!,
      provider: session.provider,
      // Juste après initiation : paiement pas encore confirmé.
      sessionPaymentStatus: SessionPaymentStatus.pendingPayment,
      redirectUrl: session.redirectUrl,
      maxitUrl: session.maxitUrl,
      omUrl: session.omUrl,
      qrCodeUrl: session.qrCodeUrl,
    );
  }
}
