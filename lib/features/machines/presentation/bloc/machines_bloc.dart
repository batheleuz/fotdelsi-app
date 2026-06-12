import 'dart:async';

import 'package:bloc/bloc.dart';

import 'package:fotdelsi/core/websocket/ws_connection_cubit.dart';
import 'package:fotdelsi/core/websocket/ws_connection_status.dart';
import '../../domain/entities/machine.dart';
import '../../domain/repositories/machine_repository.dart';
import 'machines_event.dart';
import 'machines_state.dart';

/// Bloc — flux explicite événement → traitement → état.
///
/// À l'abonnement : charge l'état courant via [MachineRepository.getMachines],
/// puis écoute le flux temps réel [MachineRepository.watchMachines] pour les
/// mises à jour.
///
/// L'état de la connexion WebSocket est délégué au [WsConnectionCubit] global
/// de sorte que n'importe quelle page peut l'observer sans dépendre de ce bloc.
/// En cas de coupure, la dernière liste de machines est conservée (pas de
/// basculement vers l'état failure).
class MachinesBloc extends Bloc<MachinesEvent, MachinesState> {
  MachinesBloc(this._repository, this._connectionCubit)
      : super(const MachinesState()) {
    on<MachinesSubscriptionRequested>(_onSubscriptionRequested);
  }

  final MachineRepository _repository;
  final WsConnectionCubit _connectionCubit;

  StreamSubscription<WsConnectionStatus>? _connectionSub;

  @override
  Future<void> close() async {
    await _connectionSub?.cancel();
    return super.close();
  }

  Future<void> _onSubscriptionRequested(
    MachinesSubscriptionRequested event,
    Emitter<MachinesState> emit,
  ) async {
    emit(state.copyWith(status: MachinesStatus.loading));

    // Écoute le stream de connexion et met à jour le cubit global.
    await _connectionSub?.cancel();
    _connectionSub = _repository.connectionStatus.listen(
      (status) => _connectionCubit.emit(status),
    );

    final result = await _repository.getMachines();

    await result.fold(
      // Échec du chargement initial (HTTP) → état failure.
      (failure) async => emit(state.copyWith(
        status: MachinesStatus.failure,
        error: failure.message,
      )),
      (machines) async {
        emit(state.copyWith(
          status: MachinesStatus.success,
          machines: machines,
        ));

        // Mises à jour temps réel — en cas d'erreur on conserve
        // les données existantes ; le cubit reflète la déconnexion.
        await emit.forEach<List<Machine>>(
          _repository.watchMachines(),
          onData: (updated) => state.copyWith(
            status: MachinesStatus.success,
            machines: updated,
          ),
          // ignore: avoid_types_on_closure_parameters
          onError: (Object e, StackTrace st) => state.copyWith(
            // On garde le status success + les machines déjà chargées.
            status: MachinesStatus.success,
          ),
        );
      },
    );
  }
}
