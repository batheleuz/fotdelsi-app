import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/wash_session_repository.dart';
import 'direct_cycles_history_state.dart';

class DirectCyclesHistoryCubit extends Cubit<DirectCyclesHistoryState> {
  DirectCyclesHistoryCubit(this._repo) : super(const DirectCyclesHistoryState());

  final WashSessionRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(status: DirectCyclesHistoryStatus.loading, clearError: true));

    final result = await _repo.getCounterSaleCyclesHistory();
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DirectCyclesHistoryStatus.failure,
          error: failure.message,
        ),
      ),
      (cycles) => emit(
        state.copyWith(
          status: DirectCyclesHistoryStatus.success,
          cycles: cycles,
        ),
      ),
    );
  }

  void updateSearch(String query) {
    emit(state.copyWith(searchQuery: query));
  }
}
