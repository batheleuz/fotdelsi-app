part of 'drop_off_queue_cubit.dart';

enum DropOffQueueStatus { initial, loading, success, failure }

final class DropOffQueueState extends Equatable {
  const DropOffQueueState({
    this.status = DropOffQueueStatus.initial,
    this.queue,
    this.day,
    this.error,
  });

  final DropOffQueueStatus status;
  final AgentQueue? queue;

  /// Jour consulté (`YYYY-MM-DD`), `null` = aujourd'hui.
  final String? day;
  final String? error;

  DropOffQueueState copyWith({
    DropOffQueueStatus? status,
    AgentQueue? queue,
    String? day,
    String? error,
    bool clearError = false,
  }) {
    return DropOffQueueState(
      status: status ?? this.status,
      queue: queue ?? this.queue,
      day: day ?? this.day,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, queue, day, error];
}
