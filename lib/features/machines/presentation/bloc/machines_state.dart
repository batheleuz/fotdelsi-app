import 'package:equatable/equatable.dart';

import '../../domain/entities/machine.dart';

enum MachinesStatus { initial, loading, success, failure }

/// État immuable observé par l'UI.
final class MachinesState extends Equatable {
  const MachinesState({
    this.status = MachinesStatus.initial,
    this.machines = const [],
    this.error,
  });

  final MachinesStatus status;
  final List<Machine> machines;
  final String? error;

  MachinesState copyWith({
    MachinesStatus? status,
    List<Machine>? machines,
    String? error,
  }) {
    return MachinesState(
      status: status ?? this.status,
      machines: machines ?? this.machines,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, machines, error];
}
