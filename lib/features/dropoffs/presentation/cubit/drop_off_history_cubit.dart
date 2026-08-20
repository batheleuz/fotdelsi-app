import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/drop_off.dart';
import '../../domain/repositories/drop_off_repository.dart';

part 'drop_off_history_state.dart';

/// Taille d'une page. Assez pour couvrir plusieurs jours sans faire attendre.
const _pageSize = 30;

/// Historique complet des dépôts, du plus récent au plus ancien.
///
/// Distinct de la file d'attente : celle-ci ne montre que le jour courant et
/// les statuts actifs. Un dépôt rendu la veille en disparaît — et avec lui le
/// numéro du client, que l'agent peut vouloir rappeler pour convenir d'une
/// remise.
///
/// Pas de temps réel ici, contrairement à la file : un historique n'a pas
/// vocation à bouger sous les yeux de celui qui le consulte, et un rechargement
/// silencieux ferait sauter la position de lecture après plusieurs pages.
class DropOffHistoryCubit extends Cubit<DropOffHistoryState> {
  DropOffHistoryCubit(this._repository) : super(const DropOffHistoryState());

  final DropOffRepository _repository;

  /// Premier chargement, ou rechargement complet depuis le début.
  Future<void> load() async {
    emit(state.copyWith(status: DropOffHistoryStatus.loading));

    final result = await _repository.getHistory(limit: _pageSize, offset: 0);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: DropOffHistoryStatus.failure,
          error: failure.message,
        ),
      ),
      (page) => emit(
        state.copyWith(
          status: DropOffHistoryStatus.success,
          dropOffs: page.dropOffs,
          hasMore: page.hasMore,
          clearError: true,
        ),
      ),
    );
  }

  /// Page suivante, ajoutée à la suite.
  ///
  /// Un échec ne vide pas ce qui est déjà affiché : les pages précédentes
  /// restent justes, et seule la suite manque. L'écran garde donc son contenu
  /// et propose de réessayer.
  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore) return;

    final deja = state.dropOffs ?? const <DropOff>[];
    emit(state.copyWith(loadingMore: true, clearError: true));

    final result = await _repository.getHistory(
      limit: _pageSize,
      offset: deja.length,
    );
    result.fold(
      (failure) =>
          emit(state.copyWith(loadingMore: false, error: failure.message)),
      (page) => emit(
        state.copyWith(
          loadingMore: false,
          dropOffs: [...deja, ...page.dropOffs],
          hasMore: page.hasMore,
        ),
      ),
    );
  }
}
