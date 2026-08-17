import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/datasources/agent_realtime_data_source.dart';
import '../../domain/entities/drop_off.dart';
import '../../domain/repositories/drop_off_repository.dart';

part 'agent_handoffs_state.dart';

/// Remises libre-service payées dont le linge n'est pas encore arrivé.
///
/// Chargement dédié (`GET /drop-offs/handoffs`) plutôt qu'une section de la
/// file : ces commandes ne suivent pas le même rythme. Le client revient quand
/// il veut — parfois le surlendemain — alors que la file agent se vide dans la
/// journée. Les mélanger obligeait à charger toute la file pour n'afficher
/// qu'une portion, et faisait dépendre cette liste du filtre de jour de l'autre.
///
/// Même mécanique temps réel que la file : le backend ne pousse qu'un signal
/// (`dropoffs:changed`), on recharge silencieusement. Une prise en charge fait
/// donc disparaître la ligne sans intervention.
class AgentHandoffsCubit extends Cubit<AgentHandoffsState> {
  AgentHandoffsCubit(this._repository, this._realtime)
    : super(const AgentHandoffsState());

  final DropOffRepository _repository;
  final AgentRealtimeDataSource _realtime;

  StreamSubscription<AgentDropOffChange?>? _realtimeSub;

  Future<bool> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: AgentHandoffsStatus.loading));

    final result = await _repository.getHandoffs();
    return result.fold(
      (failure) {
        // Un rafraîchissement de fond qui échoue alors que du contenu est
        // déjà affiché ne concerne pas l'utilisateur : ce qu'il voit reste
        // juste, seule sa fraîcheur est en jeu. On n'émet donc rien — poser un
        // message ici le faisait surgir en snackbar au milieu d'un écran
        // parfaitement correct.
        if (silent && state.handoffs != null) return false;

        emit(
          state.copyWith(
            status: AgentHandoffsStatus.failure,
            error: failure.message,
          ),
        );
        return false;
      },
      (handoffs) {
        emit(
          state.copyWith(
            status: AgentHandoffsStatus.success,
            handoffs: handoffs,
            clearError: true,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> refresh() => load(silent: true);

  /// S'abonne aux nudges de la room `agents`. Chaque changement déclenche un
  /// rechargement silencieux — pas de polling.
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
