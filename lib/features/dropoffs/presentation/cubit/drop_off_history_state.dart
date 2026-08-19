part of 'drop_off_history_cubit.dart';

enum DropOffHistoryStatus { initial, loading, success, failure }

final class DropOffHistoryState extends Equatable {
  const DropOffHistoryState({
    this.status = DropOffHistoryStatus.initial,
    this.dropOffs,
    this.hasMore = false,
    this.loadingMore = false,
    this.error,
  });

  final DropOffHistoryStatus status;

  /// `null` tant qu'aucun chargement n'a abouti — à distinguer d'une liste
  /// vide, qui signifie « aucun dépôt, jamais ».
  final List<DropOff>? dropOffs;

  /// Vient du serveur, pas d'une comparaison locale : `length == pageSize` se
  /// trompe exactement sur le dernier lot plein, et l'écran promettrait alors
  /// une page qui n'existe pas.
  final bool hasMore;

  /// Chargement d'une page SUIVANTE. Distinct de [status] : le contenu déjà
  /// affiché reste visible pendant ce temps.
  final bool loadingMore;

  final String? error;

  bool get isEmpty => (dropOffs ?? const []).isEmpty;

  DropOffHistoryState copyWith({
    DropOffHistoryStatus? status,
    List<DropOff>? dropOffs,
    bool? hasMore,
    bool? loadingMore,
    String? error,
    bool clearError = false,
  }) {
    return DropOffHistoryState(
      status: status ?? this.status,
      dropOffs: dropOffs ?? this.dropOffs,
      hasMore: hasMore ?? this.hasMore,
      loadingMore: loadingMore ?? this.loadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, dropOffs, hasMore, loadingMore, error];
}
