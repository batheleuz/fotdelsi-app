import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/machine_start_status.dart';
import '../../domain/entities/pending_wash_session.dart';
import '../../domain/entities/session_payment_status.dart';
import '../../domain/repositories/wash_session_repository.dart';

part 'wash_session_state.dart';

/// Cycle de vie du paiement puis du démarrage, pour la session en cours d'achat.
///
/// États successifs :
///   1. Session initiée, paiement en attente.
///   2. Paiement confirmé (webhook) → la machine peut être lancée.
///   3. Machine démarrée.
///   4. Session terminée → état effacé.
///
/// Modèle temps réel **hybride** : le WebSocket `session.status` pousse chaque
/// transition tant que l'app est au premier plan ; un rafraîchissement
/// `GET /status` resynchronise à l'ouverture et au retour au premier plan (la
/// socket se déconnecte pendant le paiement).
///
/// Ne porte plus l'AFFICHAGE d'un cycle : celui-ci vient du serveur via
/// `MyCyclesCubit`, seule source du bandeau, de la liste et de la feuille de
/// suivi. Ce cubit ne garde que ce qui appartient à l'achat en cours sur CE
/// téléphone — le paiement, le premier démarrage, et le code de remise.
class WashSessionCubit extends Cubit<WashSessionState> {
  WashSessionCubit(this._repository) : super(const WashSessionState()) {
    _init();
  }

  final WashSessionRepository _repository;

  StreamSubscription<SessionStatusResult>? _statusSub;

  // ── Init ─────────────────────────────────────────────────────────────────────

  Future<void> _init() async {
    final session = _repository.load();
    if (session == null) return;

    // Affiche immédiatement ce qu'on a en local (pas de flash vide).
    emit(state.copyWith(pendingSession: session));

    // Live (transitions futures) + snapshot immédiat (état courant).
    _subscribeToStatus(session.washSessionToken);
    await _refreshSessionStatus(session.washSessionToken);
  }

  Future<void> _refreshSessionStatus(String token) async {
    final result = await _repository.getSessionStatus(token);
    // Erreur réseau : on garde ce qu'on a en local, pas bloquant.
    result.fold((_) => null, _applyStatus);
  }

  /// Applique un statut (issu du WebSocket ou du GET) à l'état courant.
  void _applyStatus(SessionStatusResult status) {
    final session = state.pendingSession;
    if (session == null) return;

    // Cycle terminé côté backend → on clôt… sauf si une finition manuelle
    // reste due : le client doit encore apporter son linge au comptoir, et
    // c'est le code de remise qui le lui rappelle. Il ne disparaît qu'une fois
    // la prise en charge faite (handoffCode repassé à null).
    if (status.isFinished && status.handoffCode == null) {
      endSession();
      return;
    }

    final updated = session.copyWith(
      sessionPaymentStatus: status.paymentStatus,
      machineStartStatus: status.machineStartStatus,
    );
    _repository.save(updated);

    emit(
      state.copyWith(
        pendingSession: updated,
        canRetry: status.canRetry,
        failureReason: status.failureReason,
        clearFailureReason: status.failureReason == null,
      ),
    );
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
    await _refreshSessionStatus(session.washSessionToken);
  }

  // ── Paiement initié ──────────────────────────────────────────────────────────

  /// Appelé par [PaymentBloc] après une initiation de paiement réussie.
  Future<void> onPaymentInitiated(PendingWashSession session) async {
    await _repository.save(session);
    emit(state.copyWith(pendingSession: session));
    _subscribeToStatus(session.washSessionToken);
  }

  // ── Fin de session ───────────────────────────────────────────────────────────

  /// Termine la session : le cycle est clos et le linge n'attend plus rien.
  Future<void> endSession() async {
    _cancelRealtime();
    await _repository.clear();
    emit(const WashSessionState());
  }

  // ── Temps réel (WebSocket) ───────────────────────────────────────────────────

  void _subscribeToStatus(String token) {
    _statusSub?.cancel();
    _statusSub = _repository.watchSessionStatus(token).listen(_applyStatus);
  }

  void _cancelRealtime() {
    _statusSub?.cancel();
    _statusSub = null;
  }

  @override
  Future<void> close() {
    _cancelRealtime();
    return super.close();
  }
}
