import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/machines/domain/repositories/machine_repository.dart';
import '../../domain/repositories/drop_off_repository.dart';

part 'assign_machine_state.dart';

/// Deux usages de l'écran de choix machine : lancer le lavage (laveuse) ou
/// lancer le séchage (sécheuse).
enum AssignMode { wash, dry }

/// Choix d'une machine disponible pour lancer le lavage ou le séchage d'un dépôt.
class AssignMachineCubit extends Cubit<AssignMachineState> {
  AssignMachineCubit(this._machines, this._dropOffs)
    : super(const AssignMachineState());

  final MachineRepository _machines;
  final DropOffRepository _dropOffs;

  /// Charge les machines disponibles du [type] voulu (laveuses ou sécheuses).
  Future<void> loadMachines(MachineType type) async {
    emit(state.copyWith(status: AssignLoad.loading));
    final result = await _machines.getMachines();
    result.fold(
      (f) => emit(state.copyWith(status: AssignLoad.failure, error: f.message)),
      (all) => emit(
        state.copyWith(
          status: AssignLoad.success,
          machines: all
              .where(
                (m) => m.status == MachineStatus.available && m.type == type,
              )
              .toList(),
        ),
      ),
    );
  }

  void select(String machineId) => emit(state.copyWith(selectedId: machineId));

  /// Lance le lavage. Renvoie `true` en cas de succès.
  Future<bool> assign(String dropOffId) =>
      _run((machineId) => _dropOffs.assignMachine(dropOffId, machineId));

  /// Lance le séchage sur la sécheuse choisie. Renvoie `true` en cas de succès.
  Future<bool> startDrying(String dropOffId) =>
      _run((machineId) => _dropOffs.startDrying(dropOffId, machineId));

  Future<bool> _run(
    Future<Either<Failure, void>> Function(String machineId) action,
  ) async {
    final machineId = state.selectedId;
    if (machineId == null) return false;

    emit(state.copyWith(assignStatus: AssignStatus.loading, clearError: true));
    final result = await action(machineId);
    return result.fold(
      (f) {
        emit(
          state.copyWith(assignStatus: AssignStatus.failure, error: f.message),
        );
        return false;
      },
      (_) {
        emit(state.copyWith(assignStatus: AssignStatus.success));
        return true;
      },
    );
  }
}
