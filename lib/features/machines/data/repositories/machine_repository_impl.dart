import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/error_mapper.dart';
import 'package:fotdelsi/core/network/failures.dart';
import 'package:fotdelsi/features/machines/data/datasources/machine_realtime_data_source.dart';
import '../../domain/entities/machine.dart';
import '../../domain/repositories/machine_repository.dart';
import '../datasources/machine_api_data_source.dart';

/// Implémentation du contrat domaine.
///
/// - [getMachines] : appel REST via [MachineApiDataSource], mapping DTO → entité,
///   et conversion des exceptions en [Failure] (Either).
/// - [watchMachines] : flux temps réel — pour l'instant la source mock, à
///   remplacer par le WebSocket sans toucher au reste.
class MachineRepositoryImpl implements MachineRepository {
  const MachineRepositoryImpl(this._api, this._realtime);

  final MachineApiDataSource _api;
  final MachineRealtimeDataSource _realtime;

  @override
  Future<Either<Failure, List<Machine>>> getMachines() async {
    try {
      final models = await _api.fetchMachines();
      return Right(models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, Machine>> getMachine(String id) async {
    try {
      final model = await _api.fetchMachine(id);
      return Right(model.toEntity());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Stream<List<Machine>> watchMachines() => _realtime.watchMachines();
}
