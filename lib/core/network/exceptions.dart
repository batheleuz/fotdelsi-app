import 'dart:io';

import 'package:dio/dio.dart';

/// Exceptions techniques levées par la couche data (datasources).
///
/// Elles sont ensuite traduites en [Failure] par le repository. On sépare
/// volontairement Exception (technique, couche data) et Failure (métier,
/// remontée à la présentation).
sealed class AppException implements Exception {
  const AppException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  /// Traduit une [DioException] en exception applicative typée.
  factory AppException.fromDio(DioException e) {
    
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const TimeoutException();
      
      case DioExceptionType.badResponse:
        final code = e.response?.statusCode;
        final serverMessage = _extractMessage(e.response?.data);
        return switch (code) {
          401 || 403 => UnauthorizedException(message: serverMessage),
          404        => NotFoundException(message: serverMessage),
          _          => ServerException(message: serverMessage, statusCode: code),
        };
      
      case DioExceptionType.connectionError:
        return const NetworkException();
      
      case DioExceptionType.cancel:
        return const UnknownException(message: 'Requête annulée.');
      
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        if (e.error is SocketException) return const NetworkException();
        return const UnknownException();
    }
  }

  static String? _extractMessage(Object? data) {
    if (data is! Map) return null;
    // Réponses succès / ApiResponse.error : { code, message, data }.
    if (data['message'] is String) {
      return data['message'] as String;
    }
    // ApplicationError / DomainError (globalErrorHandler) : { error: { message } }.
    final error = data['error'];
    if (error is Map && error['message'] is String) {
      return error['message'] as String;
    }
    if (error is String) return error;
    return null;
  }
}

final class ServerException extends AppException {
  const ServerException({String? message, super.statusCode})
      : super(message ?? 'Erreur serveur.');
}

final class NetworkException extends AppException {
  const NetworkException() : super('Pas de connexion internet.');
}

final class TimeoutException extends AppException {
  const TimeoutException() : super('Le serveur met trop de temps à répondre.');
}

final class UnauthorizedException extends AppException {
  const UnauthorizedException({String? message})
      : super(message ?? 'Accès non autorisé.', statusCode: 401);
}

final class NotFoundException extends AppException {
  const NotFoundException({String? message})
      : super(message ?? 'Ressource introuvable.', statusCode: 404);
}

final class UnknownException extends AppException {
  const UnknownException({String? message})
      : super(message ?? 'Une erreur inattendue est survenue.');
}
