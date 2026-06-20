import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage sécurisé des jetons de session et de l'utilisateur connecté.
///
/// Vit dans `core/` pour être partagé entre l'intercepteur Dio (couche réseau)
/// et la feature `auth`, sans créer de dépendance core → feature.
///
/// Le JWT d'accès est court ; le refresh token (longue durée) sert à le
/// renouveler. Le backend lit le refresh dans un cookie `jwt` — côté mobile on
/// le renvoie donc via un header `Cookie: jwt=<refresh>` (voir AuthInterceptor).
class AuthTokenStore {
  const AuthTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_user';

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccess, value: accessToken),
      _storage.write(key: _kRefresh, value: refreshToken),
      _storage.write(key: _kUser, value: jsonEncode(user)),
    ]);
  }

  /// Met à jour uniquement les jetons (après un refresh réussi).
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccess, value: accessToken),
      _storage.write(key: _kRefresh, value: refreshToken),
    ]);
  }

  Future<String?> accessToken() => _storage.read(key: _kAccess);

  Future<String?> refreshToken() => _storage.read(key: _kRefresh);

  Future<Map<String, dynamic>?> user() async {
    final raw = await _storage.read(key: _kUser);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _kAccess),
      _storage.delete(key: _kRefresh),
      _storage.delete(key: _kUser),
    ]);
  }
}
