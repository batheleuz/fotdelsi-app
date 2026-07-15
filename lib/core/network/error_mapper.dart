import 'package:dio/dio.dart';

import 'exceptions.dart';
import 'failures.dart';

/// Traduit une exception technique de la couche data en [Failure] métier.
/// Utilisé par les repositories dans leur `catch`.
///
/// Accepte aussi bien une [AppException] déjà typée qu'une [DioException]
/// brute : dans ce dernier cas, on la convertit d'abord via
/// [AppException.fromDio] pour que le message (backend ou réseau) soit toujours
/// clair, quel que soit le repository appelant.
Failure mapExceptionToFailure(Object error) {
  if (error is DioException) {
    error = AppException.fromDio(error);
  }
  if (error is AppException) {
    return switch (error) {
      ServerException() => ServerFailure(error.message),
      NetworkException() => NetworkFailure(error.message),
      TimeoutException() => TimeoutFailure(error.message),
      UnauthorizedException() => UnauthorizedFailure(error.message),
      NotFoundException() => NotFoundFailure(error.message),
      ServiceUnavailableException() =>
        ServiceUnavailableFailure(error.message),
      UnknownException() => UnknownFailure(error.message),
    };
  }
  return const UnknownFailure();
}
