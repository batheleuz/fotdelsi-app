part of 'agent_handoffs_cubit.dart';

enum AgentHandoffsStatus { initial, loading, success, failure }

final class AgentHandoffsState extends Equatable {
  const AgentHandoffsState({
    this.status = AgentHandoffsStatus.initial,
    this.handoffs,
    this.error,
  });

  final AgentHandoffsStatus status;

  /// `null` tant qu'aucun chargement n'a abouti — à distinguer d'une liste
  /// vide, qui signifie « personne n'a de linge à apporter ».
  final List<DropOff>? handoffs;
  final String? error;

  int get count => handoffs?.length ?? 0;

  AgentHandoffsState copyWith({
    AgentHandoffsStatus? status,
    List<DropOff>? handoffs,
    String? error,
    bool clearError = false,
  }) {
    return AgentHandoffsState(
      status: status ?? this.status,
      handoffs: handoffs ?? this.handoffs,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, handoffs, error];
}
