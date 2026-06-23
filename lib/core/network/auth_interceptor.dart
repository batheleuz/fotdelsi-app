import 'package:dio/dio.dart';

import '../auth/auth_token_store.dart';
import '../auth/client_session_store.dart';
import 'api_endpoints.dart';

/// Intercepteur d'authentification.
///
///  - Attache `Authorization: Bearer <accessToken>` à chaque requête
///    (sauf les endpoints `/auth/*` eux-mêmes).
///  - Sur un 401, tente UNE fois de renouveler le jeton via `/auth/refresh`
///    (le backend lit le refresh dans le cookie `jwt`), puis rejoue la requête.
///  - Si le refresh échoue, purge la session (l'app retombera en anonyme).
///
/// [QueuedInterceptor] sérialise les requêtes : un seul refresh à la fois même
/// si plusieurs appels échouent en 401 simultanément.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor(this._store, this._clientStore, this._baseUrl);

  final AuthTokenStore _store;
  final ClientSessionStore _clientStore;
  final String _baseUrl;

  bool _isAuthPath(String path) => path.contains('/auth/');

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_isAuthPath(options.path)) {
      // Personnel (JWT) prioritaire ; sinon jeton client (OTP). Les deux
      // identités sont mutuellement exclusives sur un même appareil.
      final token =
          await _store.accessToken() ?? await _clientStore.token();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final req = err.requestOptions;
    final shouldRefresh = err.response?.statusCode == 401 &&
        !_isAuthPath(req.path) &&
        req.extra['retried'] != true;

    if (shouldRefresh && await _tryRefresh()) {
      final token = await _store.accessToken();
      req.headers['Authorization'] = 'Bearer $token';
      req.extra['retried'] = true;
      try {
        final response = await Dio(BaseOptions(baseUrl: _baseUrl)).fetch<dynamic>(req);
        return handler.resolve(response);
      } catch (_) {
        // Le rejeu a échoué : on laisse l'erreur d'origine remonter.
      }
    }

    handler.next(err);
  }

  /// Renvoie `true` si un nouveau couple de jetons a été obtenu et stocké.
  Future<bool> _tryRefresh() async {
    final refresh = await _store.refreshToken();
    if (refresh == null) return false;

    try {
      final dio = Dio(BaseOptions(baseUrl: _baseUrl));
      final resp = await dio.post<Map<String, dynamic>>(
        ApiEndpoints.authRefresh,
        options: Options(headers: {'Cookie': 'jwt=$refresh'}),
      );
      final data = (resp.data?['data'] as Map<String, dynamic>?) ?? {};
      final tokens = data['tokens'] as Map<String, dynamic>?;
      if (tokens == null) return false;

      await _store.saveTokens(
        accessToken: tokens['accessToken'] as String,
        refreshToken: tokens['refreshToken'] as String,
      );
      return true;
    } catch (_) {
      await _store.clear();
      return false;
    }
  }
}
