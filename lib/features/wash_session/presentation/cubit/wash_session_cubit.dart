import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import '../../domain/entities/machine_start_status.dart';
import '../../domain/entities/pending_wash_session.dart';
import '../../domain/entities/session_payment_status.dart';
import '../../domain/repositories/wash_session_repository.dart';

part 'wash_session_state.dart';

/// Cubit global — cycle de vie complet d'une session de lavage.
///
/// États successifs :
///   1. Session initiée, paiement en attente (pas de FAB visible).
///   2. Paiement confirmé (webhook) → FAB "Démarrer" visible.
///   3. Machine démarrée → FAB "Session en cours" + countdown.
///   4. Session terminée → état effacé.
///
/// Modèle temps réel **hybride** : le WebSocket `session.status` pousse chaque
/// transition (paiement confirmé, démarrage, échec, fin) tant que l'app est au
/// premier plan ; un rafraîchissement `GET /status` resynchronise à l'ouverture
/// et au retour au premier plan (la socket se déconnecte pendant le paiement).
class WashSessionCubit extends Cubit<WashSessionState> {
  WashSessionCubit(this._repository) : super(const WashSessionState()) {
    _init();
  }

  final WashSessionRepository _repository;

  StreamSubscription<SessionStatusResult>? _statusSub;

  /// Timer local d'interpolation — compte à rebours à 1 s/tick pour un
  /// affichage fluide entre deux mises à jour serveur.
  Timer? _countdownTimer;

  // ── Init ─────────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final session = _repository.load();
    print("Local Wash Session Loaded => ${session?.washSessionToken}");
    print("Local Wash Session Loaded => ${session?.machineId}");
    print("Local Wash Session Loaded => ${session?.machineStartStatus}");
    print("Local Wash Session Loaded => ${session?.sessionPaymentStatus}");
    print("Local Wash Session Loaded => ${session?.provider}");
    if (session == null) return;

    // Affiche immédiatement ce qu'on a en local (pas de flash vide).
    emit(state.copyWith(pendingSession: session));

    // Live (transitions futures) + snapshot immédiat (état courant).
    _subscribeToStatus(session.washSessionToken);
    await _refreshSessionStatus(session.washSessionToken);
  }

  Future<void> _refreshSessionStatus(String token) async {
    final result = await _repository.getSessionStatus(token);
    print("Result After getSessionStatus Token => $token");
    print("Result After getSessionStatus => $result");
    // Erreur réseau : on garde ce qu'on a en local, pas bloquant.
    result.fold((_) => null, _applyStatus);
  }

  /// Applique un statut (issu du WebSocket ou du GET) à l'état courant.
  void _applyStatus(SessionStatusResult status) {
    final session = state.pendingSession;
    if (session == null) return;

    // Cycle terminé côté backend → on clôt.
    if (status.isFinished) {
      endSession();
      return;
    }

    final updated = session.copyWith(
      sessionPaymentStatus: status.paymentStatus,
      machineStartStatus: status.machineStartStatus,
    );
    _repository.save(updated);

    final isStarted = status.machineStartStatus == MachineStartStatus.started;
    emit(
      state.copyWith(
        pendingSession: updated,
        canRetry: status.canRetry,
        failureReason: status.failureReason,
        clearFailureReason: status.failureReason == null,
        remainingSeconds: isStarted ? status.remainingSeconds : null,
      ),
    );

    if (isStarted) {
      _startLocalCountdown(status.remainingSeconds);
    }
  }

  // ── App lifecycle ────────────────────────────────────────────────────────────

  /// À appeler depuis `HomePage` lors d'un retour au premier plan.
  ///
  /// Resynchronise via `GET /status` (la socket a pu se déconnecter pendant que
  /// l'utilisateur était dans l'app Wave / Orange Money).
  Future<void> onAppResumed() async {
    final session = state.pendingSession;
    if (session == null) return;

    // Garantit la souscription temps réel (no-op si déjà active).
    _subscribeToStatus(session.washSessionToken);

    // Inutile de rafraîchir si la session est déjà démarrée.
    if (session.machineStartStatus == MachineStartStatus.started) return;
    await _refreshSessionStatus(session.washSessionToken);
  }

  // ── Paiement initié ──────────────────────────────────────────────────────────

  /// Appelé par [PaymentBloc] après une initiation de paiement réussie.
  Future<void> onPaymentInitiated(PendingWashSession session) async {
    await _repository.save(session);
    emit(state.copyWith(pendingSession: session));
    _subscribeToStatus(session.washSessionToken);
  }

  // ── Démarrer la machine ──────────────────────────────────────────────────────

  /// Appelé quand l'utilisateur appuie sur "Démarrer" ou "Réessayer".
  Future<void> startMachine(Machine machine) async {
    final session = state.pendingSession;
    if (session == null) return;

    emit(state.copyWith(startStatus: WashStartStatus.loading));

    final result = await _repository.startMachine(session.washSessionToken);

    result.fold(
      (failure) {
        final updated = session.copyWith(
          machineStartStatus: MachineStartStatus.startFailed,
        );
        _repository.save(updated);
        emit(
          state.copyWith(
            pendingSession: updated,
            startStatus: WashStartStatus.failure,
            startError: failure.message,
          ),
        );
      },
      (_) async {
        // Transition vers "session en cours". Le countdown sera alimenté par
        // l'événement `session.status` (wash_session.started) reçu en temps réel.
        final updated = session.copyWith(
          machineStartStatus: MachineStartStatus.started,
        );
        await _repository.save(updated);
        emit(
          state.copyWith(
            pendingSession: updated,
            startStatus: WashStartStatus.success,
            startedMachine: machine,
          ),
        );
        _subscribeToStatus(session.washSessionToken);
      },
    );
  }

  // ── Fin de session ───────────────────────────────────────────────────────────

  /// Termine la session (fin du cycle ou fermeture du running sheet).
  Future<void> endSession() async {
    _cancelRealtime();
    await _repository.clear();
    emit(const WashSessionState());
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  void resetStartStatus() {
    emit(state.copyWith(startStatus: WashStartStatus.idle));
  }

  Future<void> clearSession() async {
    _cancelRealtime();
    await _repository.clear();
    emit(const WashSessionState());
  }

  // ── Temps réel (WebSocket) + interpolation locale ────────────────────────────

  void _subscribeToStatus(String token) {
    _statusSub?.cancel();
    _statusSub = _repository.watchSessionStatus(token).listen(_applyStatus);
  }

  /// Lance un timer local à 1 s/tick pour interpoler entre deux mises à jour serveur.
  ///
  /// Sur un instantané à 0 (le temps restant n'est pas suivi tant que le job de
  /// polling EQLink est inactif), on n'enclenche pas de timer et on ne clôt pas :
  /// la fin réelle du cycle est signalée par `isFinished` (sessionStatus DONE).
  void _startLocalCountdown(int fromSeconds) {
    _countdownTimer?.cancel();
    emit(state.copyWith(remainingSeconds: fromSeconds));

    if (fromSeconds <= 0) return;

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state.remainingSeconds ?? 0;
      if (current <= 1) {
        _countdownTimer?.cancel();
        endSession();
      } else {
        emit(state.copyWith(remainingSeconds: current - 1));
      }
    });
  }

  void _cancelRealtime() {
    _statusSub?.cancel();
    _statusSub = null;
    _countdownTimer?.cancel();
    _countdownTimer = null;
  }

  @override
  Future<void> close() {
    _cancelRealtime();
    return super.close();
  }
}
