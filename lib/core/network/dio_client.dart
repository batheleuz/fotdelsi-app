import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

import 'api_endpoints.dart';

/// Fabrique le client HTTP `Dio` configuré pour l'API FOTDELSY.
///
/// Centralise base URL, timeouts, headers et interceptors. Le token JWT
/// (auth admin/agent) est injecté via [AuthInterceptor], ajouté au niveau DI.
abstract final class DioClient {
  const DioClient._();

  static Dio create({String? token}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    // Empêche la réutilisation d'une connexion keep-alive morte après une
    // longue mise en veille iOS : une connexion inactive est fermée vite, ce
    // qui force l'ouverture d'un socket frais à la reprise. Sans cela, la
    // première requête au réveil peut se bloquer sur un socket mort.
    dio.httpClientAdapter = IOHttpClientAdapter(
      createHttpClient: () {
        final client = HttpClient();
        client.idleTimeout = const Duration(seconds: 5);
        return client;
      },
    );

    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (object) => debugPrint(object.toString()),
        ),
      );
    }

    return dio;
  }
}
