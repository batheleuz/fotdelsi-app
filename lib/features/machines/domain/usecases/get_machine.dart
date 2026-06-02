import 'package:dartz/dartz.dart';

import '../../../../core/network/failures.dart';
import '../entities/machine.dart';
import '../repositories/machine_repository.dart';

/// Cas d'usage : récupérer une machine par identifiant (après scan QR).
class GetMachine {
  const GetMachine(this._repository);

  final MachineRepository _repository;

  Future<Either<Failure, Machine>> call(String id) =>
      _repository.getMachine(id);
}
