part of 'my_dropoffs_cubit.dart';

enum MyDropOffsStatus { initial, loading, success, failure }

final class MyDropOffsState extends Equatable {
  const MyDropOffsState({
    this.status = MyDropOffsStatus.initial,
    this.items,
    this.error,
  });

  final MyDropOffsStatus status;
  final List<DropOff>? items;
  final String? error;

  bool get isEmpty => items != null && items!.isEmpty;

  MyDropOffsState copyWith({
    MyDropOffsStatus? status,
    List<DropOff>? items,
    String? error,
    bool clearError = false,
  }) {
    return MyDropOffsState(
      status: status ?? this.status,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, items, error];
}
