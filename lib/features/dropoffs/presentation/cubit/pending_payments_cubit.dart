import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/datasources/agent_realtime_data_source.dart';
import '../../domain/entities/pending_drop_off_payment.dart';
import '../../domain/repositories/drop_off_repository.dart';

part 'pending_payments_state.dart';

/// Dépôts saisis dont le paiement n'est pas encore confirmé.
///
/// Chargement dédié (`GET /drop-offs/pending-payment`) : ces lignes ne sont
/// pas des dépôts. Un dépôt n'existe qu'une fois payé — avant, il n'y a qu'un
/// brouillon, et c'est précisément pour ça qu'il n'apparaissait nulle part.
///
/// Temps réel par le même nudge que la file (`dropoffs:changed`) : la
/// confirmation du paiement crée le dépôt, ce qui émet `registered`. Un
/// rechargement silencieux suffit donc à faire disparaître la ligne au moment
/// exact où le client paie, sans nouvel événement à inventer.
class PendingPaymentsCubit extends Cubit<PendingPaymentsState> {
  PendingPaymentsCubit(this._repository, this._realtime)
    : super(const PendingPaymentsState());

  final DropOffRepository _repository;
  final AgentRealtimeDataSource _realtime;

  StreamSubscription<AgentDropOffChange?>? _realtimeSub;

  Future<bool> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: PendingPaymentsStatus.loading));

    final result = await _repository.getPendingPayments();
    return result.fold(
      (failure) {
        // Un rafraîchissement de fond qui échoue alors que du contenu est
        // déjà affiché ne concerne pas l'utilisateur : ce qu'il voit reste
        // juste, seule sa fraîcheur est en jeu. On n'émet donc rien — poser un
        // message ici le faisait surgir en snackbar au milieu d'un écran
        // parfaitement correct.
        if (silent && state.pending != null) return false;

        emit(
          state.copyWith(
            status: PendingPaymentsStatus.failure,
            error: failure.message,
          ),
        );
        return false;
      },
      (pending) {
        emit(
          state.copyWith(
            status: PendingPaymentsStatus.success,
            pending: pending,
            clearError: true,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> refresh() => load(silent: true);

  void startRealtime() {
    _realtimeSub?.cancel();
    _realtimeSub = _realtime.watchChanges().listen((_) => load(silent: true));
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}
