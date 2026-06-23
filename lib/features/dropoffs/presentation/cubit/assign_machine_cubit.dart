import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/machines/domain/repositories/machine_repository.dart';
import '../../domain/repositories/drop_off_repository.dart';

part 'assign_machine_state.dart';

/// Choix d'une machine disponible pour lancer le lavage d'un dépôt.
class AssignMachineCubit extends Cubit<AssignMachineState> {
  AssignMachineCubit(this._machines, this._dropOffs)
      : super(const AssignMachineState());

  final MachineRepository _machines;
  final DropOffRepository _dropOffs;

  Future<void> loadMachines() async {
    emit(state.copyWith(status: AssignLoad.loading));
    final result = await _machines.getMachines();
    result.fold(
      (f) => emit(state.copyWith(status: AssignLoad.failure, error: f.message)),
      (all) => emit(state.copyWith(
        status: AssignLoad.success,
        machines: all
            .where((m) => m.status == MachineStatus.available)
            .toList(),
      )),
    );
  }

  void select(String machineId) =>
      emit(state.copyWith(selectedId: machineId));

  /// Lance le lavage. Renvoie `true` en cas de succès.
  Future<bool> assign(String dropOffId) async {
    final machineId = state.selectedId;
    if (machineId == null) return false;

    emit(state.copyWith(assignStatus: AssignStatus.loading, clearError: true));
    final result = await _dropOffs.assignMachine(dropOffId, machineId);
    return result.fold(
      (f) {
        emit(state.copyWith(assignStatus: AssignStatus.failure, error: f.message));
        return false;
      },
      (_) {
        emit(state.copyWith(assignStatus: AssignStatus.success));
        return true;
      },
    );
  }
}
