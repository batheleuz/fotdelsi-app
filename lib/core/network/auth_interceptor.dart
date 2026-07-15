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
      final token = await _store.accessToken() ?? await _clientStore.token();
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
    final shouldRefresh =
        err.response?.statusCode == 401 &&
        !_isAuthPath(req.path) &&
        req.extra['retried'] != true;

    if (shouldRefresh && await _tryRefresh()) {
      final token = await _store.accessToken();
      req.headers['Authorization'] = 'Bearer $token';
      req.extra['retried'] = true;
      try {
        final response = await _plainDio().fetch<dynamic>(req);
        return handler.resolve(response);
      } catch (e) {
        if (e is DioException && e.response?.statusCode != 401) {
          return handler.next(e);
        }

        // Si c'est une exception inconnue, on crée une nouvelle DioException
        return handler.next(DioException(requestOptions: req, error: e));
      }
    }

    handler.next(err);
  }

  /// Renvoie `true` si un nouveau couple de jetons a été obtenu et stocké.
  Future<bool> _tryRefresh() async {
    final refresh = await _store.refreshToken();
    if (refresh == null) {
      return false;
    }

    try {
      final resp = await _plainDio().post<Map<String, dynamic>>(
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
    } on DioException catch (e) {
      // Rejet d'authentification (refresh invalide/expiré) → session morte,
      // on purge pour retomber en anonyme. En revanche une erreur réseau /
      // timeout (typiquement une connexion tuée par iOS après une longue
      // suspension) NE DOIT PAS déconnecter : on échoue seulement cet appel,
      // la session reste, et un nouvel essai passera une fois la connexion
      // rétablie.
      final status = e.response?.statusCode;
      if (status == 401 || status == 403) {
        await _store.clear();
      }
      return false;
    } catch (e) {
      // Réponse inattendue (parsing) : on n'invalide pas la session.
      return false;
    }
  }

  /// Dio isolé (sans intercepteur, pour éviter la récursion) mais **avec des
  /// timeouts** : sans eux, un refresh ou un rejeu sur une connexion morte
  /// bloquerait indéfiniment — et comme cet intercepteur est un
  /// [QueuedInterceptor], il gèlerait toutes les requêtes suivantes.
  Dio _plainDio() => Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );
}
