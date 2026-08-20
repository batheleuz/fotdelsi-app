import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/drop_off.dart';
import '../../domain/repositories/drop_off_repository.dart';

part 'my_dropoff_detail_state.dart';

/// Cadence du suivi en direct.
///
/// Le linge passe entre les mains d'un agent : les transitions se comptent en
/// minutes, pas en secondes. Un relevé toutes les quinze secondes suffit à
/// donner le sentiment du direct sans marteler le serveur.
const _pouls = Duration(seconds: 15);

/// Détail d'un dépôt côté client (lecture seule, `GET /me/dropoffs/:id`).
///
/// ─── Pourquoi un suivi en direct ───
///
/// C'est l'écran qu'un client ouvre pendant qu'il attend. Sans rafraîchissement,
/// il devait quitter puis rouvrir pour savoir si son linge avait avancé — et ne
/// pouvait pas distinguer « rien n'a bougé » de « l'écran ne bouge plus ».
///
/// Le battement s'arrête tout seul quand il n'y a plus rien à attendre : un
/// dépôt remis, perdu ou remboursé ne changera plus.
class MyDropOffDetailCubit extends Cubit<MyDropOffDetailState> {
  MyDropOffDetailCubit(this._repository) : super(const MyDropOffDetailState());

  final DropOffRepository _repository;
  String _id = '';
  Timer? _ticker;

  Future<void> load(String id) async {
    _id = id;
    emit(state.copyWith(status: MyDropOffDetailStatus.loading));
    await _fetch();
  }

  /// Démarre le suivi en direct. Sans effet si le dépôt n'évolue plus.
  void startWatching() {
    _ticker?.cancel();
    _ticker = Timer.periodic(_pouls, (_) => _fetch(silent: true));
  }

  void stopWatching() {
    _ticker?.cancel();
    _ticker = null;
  }

  Future<void> refresh() => _fetch();

  /// [silent] : relevé de fond. Un échec n'efface pas ce qui est affiché — le
  /// contenu reste juste, seule sa fraîcheur est en jeu.
  Future<void> _fetch({bool silent = false}) async {
    if (_id.isEmpty) return;

    final result = await _repository.getMyDropOffById(_id);
    if (isClosed) return;

    result.fold(
      (f) {
        if (silent && state.dropOff != null) return;
        emit(
          state.copyWith(
            status: MyDropOffDetailStatus.failure,
            error: f.message,
          ),
        );
      },
      (d) {
        emit(
          state.copyWith(
            status: MyDropOffDetailStatus.success,
            dropOff: d,
            clearError: true,
          ),
        );
        // Plus rien à attendre : continuer d'interroger n'apprendrait rien.
        if (d.status.isTerminal) stopWatching();
      },
    );
  }

  @override
  Future<void> close() {
    stopWatching();
    return super.close();
  }
}
