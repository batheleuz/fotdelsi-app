import 'package:fotdelsi/core/websocket/ws_connection_status.dart';

import '../../domain/entities/machine.dart';

/// Contrat de la source temps réel des machines.
///
/// Ne gère que les événements propres aux machines (`machine.state`). La
/// progression et le statut des sessions de lavage vivent désormais dans leur
/// propre data source (`WashSessionSocketDataSource`), branchée sur la même
/// connexion partagée `RealtimeSocket`.
abstract interface class MachineRealtimeDataSource {
  /// Flux des mises à jour d'état des machines.
  Stream<List<Machine>> watchMachines();

  /// Flux des changements d'état de la connexion WebSocket.
  Stream<WsConnectionStatus> get connectionStatus;

  /// Libère les ressources (souscriptions, controller…).
  void dispose();
}
