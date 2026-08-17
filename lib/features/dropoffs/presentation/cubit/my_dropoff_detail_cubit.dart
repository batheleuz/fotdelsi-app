import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/drop_off.dart';
import '../../domain/repositories/drop_off_repository.dart';

part 'my_dropoff_detail_state.dart';

/// Détail d'un dépôt côté client (lecture seule, `GET /me/dropoffs/:id`).
class MyDropOffDetailCubit extends Cubit<MyDropOffDetailState> {
  MyDropOffDetailCubit(this._repository) : super(const MyDropOffDetailState());

  final DropOffRepository _repository;
  String _id = '';

  Future<void> load(String id) async {
    _id = id;
    emit(state.copyWith(status: MyDropOffDetailStatus.loading));
    final result = await _repository.getMyDropOffById(id);
    result.fold(
      (f) => emit(
        state.copyWith(status: MyDropOffDetailStatus.failure, error: f.message),
      ),
      (d) => emit(
        state.copyWith(
          status: MyDropOffDetailStatus.success,
          dropOff: d,
          clearError: true,
        ),
      ),
    );
  }

  Future<void> refresh() => load(_id);
}
