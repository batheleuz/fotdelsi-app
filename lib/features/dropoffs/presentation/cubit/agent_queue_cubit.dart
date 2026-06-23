import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/agent_queue.dart';
import '../../domain/repositories/drop_off_repository.dart';

part 'agent_queue_state.dart';

/// Cubit de la file d'attente agent.
///
/// Charge `GET /drop-offs/queue`, puis rafraîchit en arrière-plan toutes les
/// 30 s (intérim, en attendant les events socket `dropoffs:created/ready`).
/// Le pull-to-refresh appelle [refresh].
class AgentQueueCubit extends Cubit<AgentQueueState> {
  AgentQueueCubit(this._repository) : super(const AgentQueueState());

  final DropOffRepository _repository;

  static const _pollInterval = Duration(seconds: 30);
  Timer? _poll;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: AgentQueueStatus.loading));

    final result = await _repository.getQueue(day: state.day);
    result.fold(
      (failure) => emit(state.copyWith(
        // En refresh silencieux, on garde les données affichées.
        status: silent && state.queue != null
            ? AgentQueueStatus.success
            : AgentQueueStatus.failure,
        error: failure.message,
      )),
      (queue) => emit(state.copyWith(
        status: AgentQueueStatus.success,
        queue: queue,
        clearError: true,
      )),
    );
  }

  Future<void> refresh() => load(silent: true);

  void startPolling() {
    _poll?.cancel();
    _poll = Timer.periodic(_pollInterval, (_) => load(silent: true));
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
