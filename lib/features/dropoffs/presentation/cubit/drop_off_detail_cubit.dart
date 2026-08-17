import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:fotdelsi/core/network/failures.dart';
import '../../data/datasources/agent_realtime_data_source.dart';
import '../../domain/entities/drop_off.dart';
import '../../domain/entities/laundry_type.dart';
import '../../domain/repositories/drop_off_repository.dart';

part 'drop_off_detail_state.dart';

/// Détail d'un dépôt + actions agent (marquer prêt, remettre, modifier linge).
///
/// Se met à jour **en temps réel** : quand le backend signale un changement sur
/// CE dépôt (notamment la fin automatique du lavage/séchage détectée par le
/// polling), l'écran se recharge silencieusement — l'agent voit apparaître
/// « Lancer le séchage » / « Marquer prêt » sans rien faire.
class DropOffDetailCubit extends Cubit<DropOffDetailState> {
  DropOffDetailCubit(this._repository, this._realtime)
    : super(const DropOffDetailState());

  final DropOffRepository _repository;
  final AgentRealtimeDataSource _realtime;

  StreamSubscription<AgentDropOffChange?>? _realtimeSub;
  String _id = '';

  Future<void> load(String id, {bool silent = false}) async {
    _id = id;
    if (!silent) emit(state.copyWith(status: DetailStatus.loading));
    final result = await _repository.getById(id);
    result.fold(
      (f) => emit(
        // En rafraîchissement silencieux, on garde le détail affiché.
        silent && state.dropOff != null
            ? state
            : state.copyWith(status: DetailStatus.failure, error: f.message),
      ),
      (d) => emit(state.copyWith(status: DetailStatus.success, dropOff: d)),
    );
  }

  /// S'abonne aux changements temps réel et recharge quand ils concernent ce
  /// dépôt (ou à la resynchronisation de (re)connexion, signalée par `null`).
  void startRealtime() {
    _realtimeSub?.cancel();
    _realtimeSub = _realtime.watchChanges().listen((change) {
      if (_id.isEmpty) return;
      if (change == null || change.dropOffId == _id) {
        load(_id, silent: true);
      }
    });
  }

  @override
  Future<void> close() {
    _realtimeSub?.cancel();
    return super.close();
  }

  Future<void> receiveHandoff() =>
      _runAction(() => _repository.receiveHandoff(_id));

  Future<void> markReady() => _runAction(() => _repository.markReady(_id));

  Future<void> markCollected() =>
      _runAction(() => _repository.markCollected(_id));

  Future<void> updateLaundry({
    required int pieces,
    required List<LaundryType> types,
    String? instructions,
  }) => _runAction(
    () => _repository.updateLaundry(
      _id,
      pieces: pieces,
      types: types,
      instructions: instructions,
    ),
  );

  Future<void> _runAction(
    Future<Either<Failure, void>> Function() action,
  ) async {
    emit(
      state.copyWith(
        actionStatus: ActionStatus.loading,
        clearActionError: true,
      ),
    );
    final result = await action();
    await result.fold(
      (f) async => emit(
        state.copyWith(
          actionStatus: ActionStatus.failure,
          actionError: f.message,
        ),
      ),
      (_) async {
        emit(state.copyWith(actionStatus: ActionStatus.success));
        await load(_id);
      },
    );
  }
}
