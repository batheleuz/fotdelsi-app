import 'package:dartz/dartz.dart';

import '../../../../core/network/failures.dart';
import '../entities/machine.dart';
import '../repositories/machine_repository.dart';

/// Cas d'usage : récupérer l'état courant des machines.
class GetMachines {
  const GetMachines(this._repository);

  final MachineRepository _repository;

  Future<Either<Failure, List<Machine>>> call() => _repository.getMachines();
}
