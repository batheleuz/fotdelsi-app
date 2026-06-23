part of 'agent_queue_cubit.dart';

enum AgentQueueStatus { initial, loading, success, failure }

final class AgentQueueState extends Equatable {
  const AgentQueueState({
    this.status = AgentQueueStatus.initial,
    this.queue,
    this.day,
    this.error,
  });

  final AgentQueueStatus status;
  final AgentQueue? queue;

  /// Jour consulté (`YYYY-MM-DD`), `null` = aujourd'hui.
  final String? day;
  final String? error;

  AgentQueueState copyWith({
    AgentQueueStatus? status,
    AgentQueue? queue,
    String? day,
    String? error,
    bool clearError = false,
  }) {
    return AgentQueueState(
      status: status ?? this.status,
      queue: queue ?? this.queue,
      day: day ?? this.day,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, queue, day, error];
}
