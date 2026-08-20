import 'dart:async';

import 'package:fotdelsi/core/websocket/realtime_socket.dart';
import 'package:fotdelsi/core/websocket/ws_connection_status.dart';
import '../../domain/entities/machine.dart';
import '../models/machine_model.dart';
import 'machine_realtime_data_source.dart';

/// Source temps réel des machines, branchée sur la connexion partagée
/// [RealtimeSocket].
///
/// Écoute l'événement `machine.state` et émet la liste mise à jour. La
/// connexion partagée est acquise au premier `listen` de [watchMachines] et
/// relâchée au dernier `cancel` (comptage de références côté [RealtimeSocket]).
class MachineSocketDataSource implements MachineRealtimeDataSource {
  MachineSocketDataSource(this._socket);

  final RealtimeSocket _socket;

  static const String _eventMachinesUpdate = 'machine.state';

  StreamController<List<Machine>>? _machinesController;
  StreamSubscription<dynamic>? _machineSub;

  @override
  Stream<List<Machine>> watchMachines() {
    _machinesController ??= StreamController<List<Machine>>.broadcast(
      onListen: () {
        _socket.acquire();
        _machineSub = _socket
            .on(_eventMachinesUpdate)
            .listen(_onMachinesUpdate);
      },
      onCancel: () {
        _machineSub?.cancel();
        _machineSub = null;
        _socket.release();
      },
    );
    return _machinesController!.stream;
  }

  void _onMachinesUpdate(dynamic data) {
    try {
      final machine = MachineModel.fromJson(
        data as Map<String, dynamic>,
      ).toEntity();
      _machinesController?.add([machine]);
    } catch (e) {
      _machinesController?.addError(e);
    }
  }

  @override
  Stream<WsConnectionStatus> get connectionStatus => _socket.connectionStatus;

  @override
  void dispose() {
    _machineSub?.cancel();
    _machinesController?.close();
    _machinesController = null;
  }
}
