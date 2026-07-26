import 'package:equatable/equatable.dart';

import 'drop_off.dart';

/// File d'attente de l'agent, déjà groupée par statut côté backend
/// (`GET /drop-offs/queue`).
class AgentQueue extends Equatable {
  const AgentQueue({
    this.received = const [],
    this.inProgress = const [],
    this.ready = const [],
  });

  /// À lancer (RECEIVED).
  final List<DropOff> received;

  /// En cours (IN_PROGRESS).
  final List<DropOff> inProgress;

  /// À remettre (READY).
  final List<DropOff> ready;

  int get total => received.length + inProgress.length + ready.length;
  bool get isEmpty => total == 0;

  @override
  List<Object?> get props => [received, inProgress, ready];
}
