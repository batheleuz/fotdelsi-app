part of 'assign_machine_cubit.dart';

enum AssignLoad { initial, loading, success, failure }

enum AssignStatus { idle, loading, success, failure }

final class AssignMachineState extends Equatable {
  const AssignMachineState({
    this.status = AssignLoad.initial,
    this.machines = const [],
    this.selectedId,
    this.assignStatus = AssignStatus.idle,
    this.error,
  });

  final AssignLoad status;
  final List<Machine> machines;
  final String? selectedId;
  final AssignStatus assignStatus;
  final String? error;

  bool get isAssigning => assignStatus == AssignStatus.loading;

  AssignMachineState copyWith({
    AssignLoad? status,
    List<Machine>? machines,
    String? selectedId,
    AssignStatus? assignStatus,
    String? error,
    bool clearError = false,
  }) {
    return AssignMachineState(
      status: status ?? this.status,
      machines: machines ?? this.machines,
      selectedId: selectedId ?? this.selectedId,
      assignStatus: assignStatus ?? this.assignStatus,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props =>
      [status, machines, selectedId, assignStatus, error];
}
