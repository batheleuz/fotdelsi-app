part of 'wash_session_cubit.dart';

enum WashStartStatus { idle, loading, success, failure }

final class WashSessionState extends Equatable {
  const WashSessionState({
    this.pendingSession,
    this.startStatus = WashStartStatus.idle,
    this.startError,
    this.startedMachine,
    this.remainingSeconds,
    this.canRetry = false,
    this.failureReason,
  });

  /// Session stockée localement (présente de l'initiation jusqu'à la fin du cycle).
  final PendingWashSession? pendingSession;

  final WashStartStatus startStatus;
  final String? startError;

  /// Machine démarrée — disponible une fois le démarrage confirmé.
  final Machine? startedMachine;

  /// Temps restant du cycle en cours (poussé par le WebSocket `session.status`).
  final int? remainingSeconds;

  /// Le backend autorise une relance manuelle (paiement confirmé, session PENDING/FAILED).
  final bool canRetry;

  /// Raison du dernier échec de démarrage (null hors échec).
  final String? failureReason;

  // ── Dérivés ─────────────────────────────────────────────────────────────────

  /// Paiement confirmé ET machine pas encore démarrée → afficher FAB "Démarrer".
  bool get hasConfirmedPendingSession =>
      pendingSession != null &&
      pendingSession!.sessionPaymentStatus == SessionPaymentStatus.confirmed &&
      pendingSession!.machineStartStatus != MachineStartStatus.started;

  /// Machine en cours de fonctionnement → afficher FAB "Session en cours".
  bool get isRunning =>
      pendingSession?.machineStartStatus == MachineStartStatus.started;

  bool get isStarting => startStatus == WashStartStatus.loading;

  /// Paiement définitivement échoué (échec / expiré / anomalie).
  bool get hasPaymentFailed =>
      pendingSession?.sessionPaymentStatus.isTerminalFailure ?? false;

  // ── Ancienne compatibilité (interne) ────────────────────────────────────────
  bool get hasPendingSession => pendingSession != null;

  WashSessionState copyWith({
    PendingWashSession? pendingSession,
    bool clearPendingSession = false,
    WashStartStatus? startStatus,
    String? startError,
    Machine? startedMachine,
    int? remainingSeconds,
    bool clearRemainingSeconds = false,
    bool? canRetry,
    String? failureReason,
    bool clearFailureReason = false,
  }) {
    return WashSessionState(
      pendingSession: clearPendingSession
          ? null
          : pendingSession ?? this.pendingSession,
      startStatus: startStatus ?? this.startStatus,
      startError: startError,
      startedMachine: startedMachine ?? this.startedMachine,
      remainingSeconds: clearRemainingSeconds
          ? null
          : remainingSeconds ?? this.remainingSeconds,
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
    startStatus,
    startError,
    startedMachine,
    remainingSeconds,
    canRetry,
    failureReason,
  ];
}
