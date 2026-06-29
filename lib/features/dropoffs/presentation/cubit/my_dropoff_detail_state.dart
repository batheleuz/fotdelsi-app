part of 'my_dropoff_detail_cubit.dart';

enum MyDropOffDetailStatus { initial, loading, success, failure }

final class MyDropOffDetailState extends Equatable {
  const MyDropOffDetailState({
    this.status = MyDropOffDetailStatus.initial,
    this.dropOff,
    this.error,
  });

  final MyDropOffDetailStatus status;
  final DropOff? dropOff;
  final String? error;

  MyDropOffDetailState copyWith({
    MyDropOffDetailStatus? status,
    DropOff? dropOff,
    String? error,
    bool clearError = false,
  }) {
    return MyDropOffDetailState(
      status: status ?? this.status,
      dropOff: dropOff ?? this.dropOff,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, dropOff, error];
}
