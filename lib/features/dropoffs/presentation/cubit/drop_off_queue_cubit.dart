import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/datasources/agent_realtime_data_source.dart';
import '../../domain/entities/agent_queue.dart';
import '../../domain/repositories/drop_off_repository.dart';

part 'drop_off_queue_state.dart';

/// Cubit de la file d'attente agent.
///
/// Charge `GET /drop-offs/queue`, puis se met à jour **en temps réel** via la
/// room Socket.IO `agents` : à chaque nudge `dropoffs:changed` (nouveau dépôt,
/// lavage lancé, prêt, retiré) ou à chaque (re)connexion, il recharge
/// silencieusement la file. Cela remplace l'ancien polling 30 s.
/// Le pull-to-refresh appelle [refresh].
class DropOffQueueCubit extends Cubit<DropOffQueueState> {
  DropOffQueueCubit(this._repository, this._realtime)
    : super(const DropOffQueueState());

  final DropOffRepository _repository;
  final AgentRealtimeDataSource _realtime;

  StreamSubscription<AgentDropOffChange?>? _realtimeSub;

  Future<bool> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: DropOffQueueStatus.loading));

    final result = await _repository.getQueue(day: state.day);
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            // En refresh silencieux, on garde les données affichées.
            status: silent && state.queue != null
                ? DropOffQueueStatus.success
                : DropOffQueueStatus.failure,
            error: failure.message,
          ),
        );
        return false;
      },
      (queue) {
        emit(
          state.copyWith(
            status: DropOffQueueStatus.success,
            queue: queue,
            clearError: true,
          ),
        );
        return true;
      },
    );
  }

  Future<bool> refresh() => load(silent: true);

  /// S'abonne aux changements temps réel de la file (room `agents`). Chaque
  /// nudge déclenche un rechargement silencieux — pas de polling.
  void startRealtime() {
    _realtimeSub?.cancel();
    // Tout changement (quel que soit le dépôt) peut modifier la file.
    _realtimeSub = _realtime.watchChanges().listen((_) => load(silent: true));
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }
}
