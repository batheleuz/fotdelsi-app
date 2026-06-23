part of 'drop_off_search_cubit.dart';

enum SearchStatus { idle, loading, found, notFound, failure }

final class DropOffSearchState extends Equatable {
  const DropOffSearchState({this.status = SearchStatus.idle, this.result, this.error});

  final SearchStatus status;
  final DropOff? result;
  final String? error;

  DropOffSearchState copyWith({
    SearchStatus? status,
    DropOff? result,
    String? error,
  }) {
    return DropOffSearchState(
      status: status ?? this.status,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [status, result, error];
}
