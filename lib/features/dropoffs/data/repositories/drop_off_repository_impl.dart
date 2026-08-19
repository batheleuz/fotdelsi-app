import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/error_mapper.dart';
import 'package:fotdelsi/core/network/exceptions.dart';
import 'package:fotdelsi/core/network/failures.dart';
import '../../domain/entities/agent_queue.dart';
import '../../domain/entities/drop_off.dart';
import '../../domain/entities/drop_off_history_page.dart';
import '../../domain/entities/pending_drop_off_payment.dart';
import '../../domain/entities/laundry_type.dart';
import '../../domain/repositories/drop_off_repository.dart';
import '../datasources/drop_off_api_data_source.dart';

class DropOffRepositoryImpl implements DropOffRepository {
  const DropOffRepositoryImpl(this._api);

  final DropOffApiDataSource _api;

  @override
  Future<Either<Failure, AgentQueue>> getQueue({String? day}) async {
    try {
      return Right(await _api.getQueue(day: day));
    } on DioException catch (e) {
      return Left(mapExceptionToFailure(AppException.fromDio(e)));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<DropOff>>> getHandoffs() async {
    try {
      return Right(await _api.getHandoffs());
    } on DioException catch (e) {
      return Left(mapExceptionToFailure(AppException.fromDio(e)));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<PendingDropOffPayment>>>
  getPendingPayments() async {
    try {
      return Right(await _api.getPendingPayments());
    } on DioException catch (e) {
      return Left(mapExceptionToFailure(AppException.fromDio(e)));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, String>> createDraft({
    required String contactPhone,
    required String customerName,
    required String formulaCode,
    required int sizeKg,
    required int pieces,
    required List<LaundryType> types,
    String? instructions,
  }) async {
    try {
      final draftId = await _api.createDraft(
        contactPhone: contactPhone,
        customerName: customerName,
        formulaCode: formulaCode,
        sizeKg: sizeKg,
        pieces: pieces,
        types: types,
        instructions: instructions,
      );
      return Right(draftId);
    } on DioException catch (e) {
      return Left(mapExceptionToFailure(AppException.fromDio(e)));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, List<DropOff>>> getMyDropOffs() =>
      _guard(() => _api.getMyDropOffs());

  @override
  Future<Either<Failure, DropOff>> getMyDropOffById(String id) =>
      _guard(() => _api.getMyDropOffById(id));

  @override
  Future<Either<Failure, DropOff>> getById(String id) =>
      _guard(() => _api.getById(id));

  @override
  Future<Either<Failure, DropOff>> getByCode(String code, {String? day}) =>
      _guard(() => _api.getByCode(code, day: day));

  @override
  Future<Either<Failure, DropOffHistoryPage>> getHistory({
    int? limit,
    int? offset,
  }) => _guard(() => _api.getHistory(limit: limit, offset: offset));

  @override
  Future<Either<Failure, void>> assignMachine(String id, String machineId) =>
      _guard(() => _api.assignMachine(id, machineId));

  @override
  Future<Either<Failure, void>> startDrying(String id, String dryerMachineId) =>
      _guard(() => _api.startDrying(id, dryerMachineId));

  @override
  Future<Either<Failure, void>> receiveHandoff(String id) =>
      _guard(() => _api.receiveHandoff(id));

  @override
  Future<Either<Failure, void>> markReady(String id) =>
      _guard(() => _api.markReady(id));

  @override
  Future<Either<Failure, void>> markCollected(String id) =>
      _guard(() => _api.markCollected(id));

  @override
  Future<Either<Failure, void>> updateLaundry(
    String id, {
    required int pieces,
    required List<LaundryType> types,
    String? instructions,
  }) => _guard(
    () => _api.updateLaundry(
      id,
      pieces: pieces,
      types: types,
      instructions: instructions,
    ),
  );

  /// Exécute [op] en traduisant toute exception technique en [Failure].
  Future<Either<Failure, T>> _guard<T>(Future<T> Function() op) async {
    try {
      return Right(await op());
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }
}
