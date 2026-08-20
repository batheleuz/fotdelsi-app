import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/failures.dart';
import '../entities/machine_start_status.dart';
import '../entities/pending_wash_session.dart';
import '../entities/session_payment_status.dart';
import '../entities/wash_cycle.dart';

/// Statut combiné d'une wash-session (miroir du DTO backend).
typedef SessionStatusResult = ({
  SessionPaymentStatus paymentStatus,
  MachineStartStatus machineStartStatus,

  /// `null` quand la machine n'a pas encore annoncé de durée.
  int? remainingSeconds,
  bool canRetry,
  bool isFinished,
  bool withDrying,
  bool canStartDrying,
  bool isDrying,
  String? handoffCode,
  String? failureReason,
});

abstract interface class WashSessionRepository {
  Future<void> save(PendingWashSession session);
  PendingWashSession? load();
  Future<void> clear();

  /// `GET /wash-session/{token}/status` — rafraîchit les statuts et le temps restant.
  Future<Either<Failure, SessionStatusResult>> getSessionStatus(
    String washSessionToken,
  );

  /// `GET /wash-sessions/counter-sales` — cycles vendus au comptoir : à
  /// démarrer, en cours, ou terminés depuis moins de 24 h.
  ///
  /// Le seul moyen de retrouver un cycle encaissé dont on a quitté l'écran de
  /// vente : le jeton de démarrage ne vit nulle part ailleurs.
  Future<Either<Failure, List<WashCycle>>> getCounterSaleCycles();

  /// `GET /me/cycles` — cycles du client authentifié : à démarrer, en cours,
  /// ou terminés depuis moins de 24 h.
  ///
  /// Source de vérité du parcours client. Le stockage local ne conserve plus
  /// que les liens de paiement, le temps d'ouvrir Wave ou Orange Money : tout
  /// le reste vit côté serveur, rattaché au numéro lié.
  /// Nécessite une session client (numéro lié par OTP).
  Future<Either<Failure, List<WashCycle>>> getMyCycles();

  /// `POST /wash-session/start` — démarre la machine via EQLink (token dans le body).
  Future<Either<Failure, void>> startMachine(String washSessionToken);

  /// `POST /wash-sessions/start-drying` — second temps du cycle.
  ///
  /// La sécheuse n'est pas réservée au paiement (elle tournerait à vide
  /// pendant le lavage) : le client la choisit ici parmi celles libres.
  Future<Either<Failure, void>> startDrying({
    required String washSessionToken,
    required String dryerMachineId,
  });

  /// Flux temps réel du statut de la session active (WebSocket `session.status`).
  ///
  /// À l'abonnement, rejoint la room `session:<token>` côté backend ; au
  /// désabonnement, la quitte. Émet à chaque transition (paiement confirmé,
  /// machine démarrée/échec, fin de cycle).
  Stream<SessionStatusResult> watchSessionStatus(String washSessionToken);
}
