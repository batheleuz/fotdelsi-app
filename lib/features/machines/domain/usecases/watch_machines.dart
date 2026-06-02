import '../entities/machine.dart';
import '../repositories/machine_repository.dart';

/// Cas d'usage : observer l'état des machines en temps réel.
///
/// Un use case = une intention métier. Il s'interpose entre la présentation
/// et le repository, ce qui permet aux trois solutions de state management
/// d'attaquer exactement le même point d'entrée.
class WatchMachines {
  const WatchMachines(this._repository);

  final MachineRepository _repository;

  Stream<List<Machine>> call() => _repository.watchMachines();
}
