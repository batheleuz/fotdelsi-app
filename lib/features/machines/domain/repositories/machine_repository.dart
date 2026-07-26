import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/core/websocket/ws_connection_status.dart';
import '../entities/machine.dart';

/// Contrat de la couche domaine pour accéder aux machines.
///
/// L'implémentation vit dans la couche data. Le domaine ignore tout du
/// transport (REST, WebSocket, mock) et de la gestion d'erreur technique.
abstract interface class MachineRepository {
  Future<Either<Failure, List<Machine>>> getMachines();
  Future<Either<Failure, Machine>> getMachine(String id);
  Future<Either<Failure, Machine>> getMachineByDeviceName(String deviceName);

  /// Flux temps réel de l'état des machines (alimenté par le WebSocket).
  Stream<List<Machine>> watchMachines();

  /// Flux de l'état de la connexion WebSocket.
  Stream<WsConnectionStatus> get connectionStatus;
}
