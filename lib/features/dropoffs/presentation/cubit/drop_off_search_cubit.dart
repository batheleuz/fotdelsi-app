import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:fotdelsi/core/network/failures.dart';
import '../../domain/entities/drop_off.dart';
import '../../domain/repositories/drop_off_repository.dart';

part 'drop_off_search_state.dart';

/// Recherche d'un dépôt par son code court (client revenu sans l'app).
class DropOffSearchCubit extends Cubit<DropOffSearchState> {
  DropOffSearchCubit(this._repository) : super(const DropOffSearchState());

  final DropOffRepository _repository;

  Future<void> search(String code, {String? day}) async {
    emit(state.copyWith(status: SearchStatus.loading));
    final result = await _repository.getByCode(code, day: day);
    result.fold(
      (failure) => emit(state.copyWith(
        status: failure is NotFoundFailure
            ? SearchStatus.notFound
            : SearchStatus.failure,
        error: failure.message,
      )),
      (dropOff) =>
          emit(state.copyWith(status: SearchStatus.found, result: dropOff)),
    );
  }

  void reset() => emit(const DropOffSearchState());
}
