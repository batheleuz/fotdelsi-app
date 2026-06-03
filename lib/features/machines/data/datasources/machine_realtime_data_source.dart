import '../../domain/entities/machine.dart';

/// Contrat de la source temps réel des machines.
abstract interface class MachineRealtimeDataSource {
  /// Flux des mises à jour d'état des machines.
  Stream<List<Machine>> watchMachines();

  /// Libère les ressources (socket, controller…).
  void dispose();
}
