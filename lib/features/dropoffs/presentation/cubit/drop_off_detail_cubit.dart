import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:fotdelsi/core/network/failures.dart';
import '../../domain/entities/drop_off.dart';
import '../../domain/entities/laundry_type.dart';
import '../../domain/repositories/drop_off_repository.dart';

part 'drop_off_detail_state.dart';

/// Détail d'un dépôt + actions agent (marquer prêt, remettre, modifier linge).
class DropOffDetailCubit extends Cubit<DropOffDetailState> {
  DropOffDetailCubit(this._repository) : super(const DropOffDetailState());

  final DropOffRepository _repository;
  String _id = '';

  Future<void> load(String id) async {
    _id = id;
    emit(state.copyWith(status: DetailStatus.loading));
    final result = await _repository.getById(id);
    result.fold(
      (f) => emit(state.copyWith(status: DetailStatus.failure, error: f.message)),
      (d) => emit(state.copyWith(status: DetailStatus.success, dropOff: d)),
    );
  }

  Future<void> markReady() => _runAction(() => _repository.markReady(_id));

  Future<void> markCollected() =>
      _runAction(() => _repository.markCollected(_id));

  Future<void> updateLaundry({
    required int pieces,
    required List<LaundryType> types,
    String? instructions,
  }) =>
      _runAction(() => _repository.updateLaundry(
            _id,
            pieces: pieces,
            types: types,
            instructions: instructions,
          ));

  Future<void> _runAction(
      Future<Either<Failure, void>> Function() action) async {
    emit(state.copyWith(actionStatus: ActionStatus.loading, clearActionError: true));
    final result = await action();
    await result.fold(
      (f) async => emit(state.copyWith(
        actionStatus: ActionStatus.failure,
        actionError: f.message,
      )),
      (_) async {
        emit(state.copyWith(actionStatus: ActionStatus.success));
        await load(_id);
      },
    );
  }
}
