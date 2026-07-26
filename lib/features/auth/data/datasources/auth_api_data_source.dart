import 'package:dio/dio.dart';

import 'package:fotdelsi/core/network/api_endpoints.dart';
import '../models/auth_session_model.dart';

/// Source distante REST de l'authentification.
class AuthApiDataSource {
  const AuthApiDataSource(this._dio);

  final Dio _dio;

  Future<AuthSessionModel> login({
    required String email,
    required String password,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final data = (resp.data?['data'] as Map<String, dynamic>?) ?? {};
    return AuthSessionModel.fromData(data);
  }

  /// Révocation côté backend. Best-effort : l'appelant purge le stockage
  /// local quoi qu'il arrive.
  Future<void> logout() async {
    await _dio.post<dynamic>(ApiEndpoints.authLogout, data: const {});
  }
}
