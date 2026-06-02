import 'exceptions.dart';
import 'failures.dart';

/// Traduit une exception technique de la couche data en [Failure] métier.
/// Utilisé par les repositories dans leur `catch`.
Failure mapExceptionToFailure(Object error) {
  if (error is AppException) {
    return switch (error) {
      ServerException() => ServerFailure(error.message),
      NetworkException() => NetworkFailure(error.message),
      TimeoutException() => TimeoutFailure(error.message),
      UnauthorizedException() => UnauthorizedFailure(error.message),
      NotFoundException() => NotFoundFailure(error.message),
      UnknownException() => UnknownFailure(error.message),
    };
  }
  return const UnknownFailure();
}
