import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'api_endpoints.dart';

/// Fabrique le client HTTP `Dio` configuré pour l'API FOTDELSY.
///
/// Centralise base URL, timeouts, headers et interceptors. Le token JWT
/// (auth admin/agent) sera injecté ici via un interceptor dédié.
abstract final class DioClient {
  const DioClient._();

  static Dio create({String? token}) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        contentType: Headers.jsonContentType,
        responseType: ResponseType.json,
      ),
    );

    if (token != null) {
      dio.options.headers['Authorization'] = 'Bearer $token';
    }

    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        logPrint: (object) => debugPrint(object.toString()),
      ));
    }

    return dio;
  }
}
