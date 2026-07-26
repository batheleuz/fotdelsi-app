import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/failures.dart';
import '../entities/machine_start_status.dart';
import '../entities/pending_wash_session.dart';
import '../entities/session_payment_status.dart';

/// Statut combiné d'une wash-session (miroir du DTO backend).
typedef SessionStatusResult = ({
  SessionPaymentStatus paymentStatus,
  MachineStartStatus machineStartStatus,
  int remainingSeconds,
  bool canRetry,
  bool isFinished,
  String? failureReason,
});

abstract interface class WashSessionRepository {
  Future<void> save(PendingWashSession session);
  PendingWashSession? load();
  Future<void> clear();

  /// `GET /wash-session/{token}/status` — rafraîchit les statuts et le temps restant.
  Future<Either<Failure, SessionStatusResult>> getSessionStatus(
      String washSessionToken);

  /// `POST /wash-session/start` — démarre la machine via EQLink (token dans le body).
  Future<Either<Failure, void>> startMachine(String washSessionToken);

  /// Flux temps réel du statut de la session active (WebSocket `session.status`).
  ///
  /// À l'abonnement, rejoint la room `session:<token>` côté backend ; au
  /// désabonnement, la quitte. Émet à chaque transition (paiement confirmé,
  /// machine démarrée/échec, fin de cycle).
  Stream<SessionStatusResult> watchSessionStatus(String washSessionToken);
}
