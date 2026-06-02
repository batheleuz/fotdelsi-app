import 'package:bloc/bloc.dart';

import '../../domain/entities/machine.dart';
import '../../domain/usecases/get_machines.dart';
import '../../domain/usecases/watch_machines.dart';
import 'machines_event.dart';
import 'machines_state.dart';

/// Bloc — flux explicite événement → traitement → état.
///
/// À l'abonnement : charge l'état courant via [GetMachines] (gestion d'erreur
/// par Either → state failure), puis écoute le flux temps réel [WatchMachines]
/// pour les mises à jour.
class MachinesBloc extends Bloc<MachinesEvent, MachinesState> {
  MachinesBloc(this._getMachines, this._watchMachines)
      : super(const MachinesState()) {
    on<MachinesSubscriptionRequested>(_onSubscriptionRequested);
  }

  final GetMachines _getMachines;
  final WatchMachines _watchMachines;

  Future<void> _onSubscriptionRequested(
    MachinesSubscriptionRequested event,
    Emitter<MachinesState> emit,
  ) async {
    emit(state.copyWith(status: MachinesStatus.loading));

    final result = await _getMachines();

    await result.fold(
      (failure) async => emit(state.copyWith(
        status: MachinesStatus.failure,
        error: failure.message,
      )),
      (machines) async {
        emit(state.copyWith(
          status: MachinesStatus.success,
          machines: machines,
        ));
        // Mises à jour temps réel (WebSocket à terme).
        await emit.forEach<List<Machine>>(
          _watchMachines(),
          onData: (machines) => state.copyWith(
            status: MachinesStatus.success,
            machines: machines,
          ),
          onError: (error, _) => state.copyWith(
            status: MachinesStatus.failure,
            error: 'Connexion temps réel perdue.',
          ),
        );
      },
    );
  }
}
