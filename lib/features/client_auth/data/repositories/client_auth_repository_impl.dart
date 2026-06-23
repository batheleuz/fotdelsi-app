import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:fotdelsi/core/auth/client_session_store.dart';
import 'package:fotdelsi/core/network/error_mapper.dart';
import 'package:fotdelsi/core/network/exceptions.dart';
import 'package:fotdelsi/core/network/failures.dart';
import '../../domain/repositories/client_auth_repository.dart';
import '../datasources/client_auth_api_data_source.dart';

class ClientAuthRepositoryImpl implements ClientAuthRepository {
  const ClientAuthRepositoryImpl(this._api, this._store);

  final ClientAuthApiDataSource _api;
  final ClientSessionStore _store;

  @override
  Future<Either<Failure, void>> requestOtp(String phone) async {
    try {
      await _api.requestOtp(phone);
      return const Right(null);
    } on DioException catch (e) {
      return Left(mapExceptionToFailure(AppException.fromDio(e)));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<Either<Failure, String>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    try {
      final session = await _api.verifyOtp(phone: phone, code: code);
      await _store.save(token: session.token, phone: session.phone);
      return Right(session.phone);
    } on DioException catch (e) {
      return Left(mapExceptionToFailure(AppException.fromDio(e)));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<String?> linkedPhone() => _store.phone();

  @override
  Future<void> unlink() async {
    try {
      await _api.logout();
    } catch (_) {
      // Best-effort : on purge la session locale quoi qu'il arrive.
    } finally {
      await _store.clear();
    }
  }
}
