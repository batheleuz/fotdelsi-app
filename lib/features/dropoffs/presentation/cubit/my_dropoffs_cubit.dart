import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/drop_off.dart';
import '../../domain/repositories/drop_off_repository.dart';

part 'my_dropoffs_state.dart';

/// Historique des dépôts du client lié (`GET /me/dropoffs`).
class MyDropOffsCubit extends Cubit<MyDropOffsState> {
  MyDropOffsCubit(this._repository) : super(const MyDropOffsState());

  final DropOffRepository _repository;

  Future<void> load({bool silent = false}) async {
    if (!silent) emit(state.copyWith(status: MyDropOffsStatus.loading));
    final result = await _repository.getMyDropOffs();
    result.fold(
      // Voir ci-dessus : un rafraîchissement de fond qui échoue sur un écran
      // déjà rempli ne vaut pas un message.
      (f) => silent && state.items != null
          ? null
          : emit(
              state.copyWith(
                status: MyDropOffsStatus.failure,
                error: f.message,
              ),
            ),
      (items) => emit(
        state.copyWith(
          status: MyDropOffsStatus.success,
          items: items,
          clearError: true,
        ),
      ),
    );
  }

  Future<void> refresh() => load(silent: true);
}
