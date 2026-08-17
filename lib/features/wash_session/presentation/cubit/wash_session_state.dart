part of 'wash_session_cubit.dart';

/// L'achat en cours sur CE téléphone : paiement, premier démarrage, remise.
///
/// Cet état portait aussi l'affichage du cycle — temps restant, machine
/// démarrée, séchage à lancer. Ces champs venaient du stockage local et
/// pouvaient contredire le serveur ; ils ont été retirés une fois le bandeau,
/// la liste et la feuille de suivi passés à `MyCyclesCubit`, seule source du
/// cycle. Le code de remise a suivi le même chemin : il vit sur le cycle, où
/// une vente encaissée au comptoir le porte aussi. Ce qui reste ici n'existe
/// nulle part ailleurs.
final class WashSessionState extends Equatable {
  const WashSessionState({
    this.pendingSession,
    this.canRetry = false,
    this.failureReason,
  });

  /// Session stockée localement (présente de l'initiation jusqu'à la fin du cycle).
  final PendingWashSession? pendingSession;

  /// Le backend autorise une relance manuelle (paiement confirmé, session PENDING/FAILED).
  final bool canRetry;

  /// Raison du dernier échec de démarrage (null hors échec).
  final String? failureReason;

  // ── Dérivés ─────────────────────────────────────────────────────────────────

  /// Paiement confirmé ET machine pas encore démarrée.
  bool get hasConfirmedPendingSession =>
      pendingSession != null &&
      pendingSession!.sessionPaymentStatus == SessionPaymentStatus.confirmed &&
      pendingSession!.machineStartStatus != MachineStartStatus.started;

  /// Paiement définitivement échoué (échec / expiré / anomalie).
  bool get hasPaymentFailed =>
      pendingSession?.sessionPaymentStatus.isTerminalFailure ?? false;

  bool get hasPendingSession => pendingSession != null;

  WashSessionState copyWith({
    PendingWashSession? pendingSession,
    bool clearPendingSession = false,
    bool? canRetry,
    String? failureReason,
    bool clearFailureReason = false,
  }) {
    return WashSessionState(
      pendingSession: clearPendingSession
          ? null
          : pendingSession ?? this.pendingSession,
      canRetry: canRetry ?? this.canRetry,
      failureReason: clearFailureReason
          ? null
          : failureReason ?? this.failureReason,
    );
  }

  @override
  List<Object?> get props => [
    pendingSession?.washSessionToken,
    pendingSession?.sessionPaymentStatus,
    pendingSession?.machineStartStatus,
    canRetry,
    failureReason,
  ];
}
