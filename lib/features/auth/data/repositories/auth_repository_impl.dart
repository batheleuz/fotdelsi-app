import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import 'package:fotdelsi/core/auth/auth_token_store.dart';
import 'package:fotdelsi/core/network/error_mapper.dart';
import 'package:fotdelsi/core/network/exceptions.dart';
import 'package:fotdelsi/core/network/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_api_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._api, this._store);

  final AuthApiDataSource _api;
  final AuthTokenStore _store;

  @override
  Future<Either<Failure, AuthUser>> login({
    required String email,
    required String password,
  }) async {
    try {
      final model = await _api.login(email: email, password: password);
      await _store.saveSession(
        accessToken: model.accessToken,
        refreshToken: model.refreshToken,
        user: model.user.toJson(),
      );
      return Right(model.user);
    } on DioException catch (e) {
      return Left(mapExceptionToFailure(AppException.fromDio(e)));
    } catch (e) {
      return Left(mapExceptionToFailure(e));
    }
  }

  @override
  Future<AuthUser?> restoreSession() async {
    final json = await _store.user();
    if (json == null) return null;
    return AuthUser.fromJson(json);
  }

  @override
  Future<void> logout() async {
    try {
      await _api.logout();
    } catch (_) {
      // Best-effort : on purge la session locale quoi qu'il arrive.
    } finally {
      await _store.clear();
    }
  }
}
