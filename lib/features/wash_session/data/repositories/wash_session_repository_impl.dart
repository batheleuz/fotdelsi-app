import 'package:dartz/dartz.dart';

import 'package:fotdelsi/core/network/error_mapper.dart';
import 'package:fotdelsi/core/network/failures.dart';
import '../../domain/entities/pending_wash_session.dart';
import '../../domain/repositories/wash_session_repository.dart';
import '../datasources/wash_session_api_data_source.dart';
import '../datasources/wash_session_local_data_source.dart';
import '../datasources/wash_session_socket_data_source.dart';
import '../models/wash_session_status_model.dart';

class WashSessionRepositoryImpl implements WashSessionRepository {
  const WashSessionRepositoryImpl(this._local, this._api, this._socket);

  final WashSessionLocalDataSource _local;
  final WashSessionApiDataSource _api;
  final WashSessionSocketDataSource _socket;

  @override
  Future<void> save(PendingWashSession session) => _local.save(session);

  @override
  PendingWashSession? load() => _local.load();

  @override
  Future<void> clear() => _local.clear();

  @override
  Future<Either<Failure, SessionStatusResult>> getSessionStatus(
      String washSessionToken) async {
    try {
      final model = await _api.getStatus(washSessionToken);
      return Right(_toResult(model));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, void>> startMachine(String washSessionToken) async {
    try {
      await _api.startMachine(washSessionToken);
      return const Right(null);
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Stream<SessionStatusResult> watchSessionStatus(String washSessionToken) =>
      _socket.watchStatus(washSessionToken).map(_toResult);

  SessionStatusResult _toResult(WashSessionStatusModel model) => (
        paymentStatus: model.paymentStatus,
        machineStartStatus: model.machineStartStatus,
        remainingSeconds: model.remainTimeSeconds,
        canRetry: model.canRetry,
        isFinished: model.isFinished,
        failureReason: model.failureReason,
      );
}
