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
///
/// **Cache mémoire** : les jetons vivent en mémoire (source de vérité pour les
/// lectures du chemin critique). Sur iOS, une lecture Keychain peut se bloquer
/// au retour de veille ; comme l'[AuthInterceptor] est un `QueuedInterceptor`,
/// ce blocage gèlerait TOUTES les requêtes (spinner infini, redémarrage requis).
/// On lit donc en mémoire (préchargée via [preload] au démarrage) et le Keychain
/// ne sert plus qu'à la persistance entre lancements, en best-effort borné.
class AuthTokenStore {
  AuthTokenStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kUser = 'auth_user';

  String? _access;
  String? _refresh;
  bool _loaded = false;
  Future<void>? _loading;

  /// Précharge les jetons du Keychain en mémoire (à appeler au démarrage,
  /// appareil déverrouillé). Idempotent.
  Future<void> preload() => _ensureLoaded();

  Future<void> _ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _storage.read(key: _kAccess),
        _storage.read(key: _kRefresh),
      ]).timeout(const Duration(seconds: 5));
      _access = results[0];
      _refresh = results[1];
    } catch (_) {
      // Keychain indisponible/bloqué : on repart sans jeton en mémoire plutôt
      // que de bloquer indéfiniment. Un write ultérieur rétablira la cohérence.
    } finally {
      _loaded = true;
      _loading = null;
    }
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    _access = accessToken;
    _refresh = refreshToken;
    _loaded = true;
    await _bestEffort(
      Future.wait([
        _storage.write(key: _kAccess, value: accessToken),
        _storage.write(key: _kRefresh, value: refreshToken),
        _storage.write(key: _kUser, value: jsonEncode(user)),
      ]),
    );
  }

  /// Met à jour uniquement les jetons (après un refresh réussi).
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    // Mémoire d'abord (jamais bloquant), puis persistance bornée : ce chemin
    // est appelé depuis l'intercepteur, il ne doit jamais geler la file.
    _access = accessToken;
    _refresh = refreshToken;
    _loaded = true;
    await _bestEffort(
      Future.wait([
        _storage.write(key: _kAccess, value: accessToken),
        _storage.write(key: _kRefresh, value: refreshToken),
      ]),
    );
  }

  Future<String?> accessToken() async {
    await _ensureLoaded();
    return _access;
  }

  Future<String?> refreshToken() async {
    await _ensureLoaded();
    return _refresh;
  }

  Future<Map<String, dynamic>?> user() async {
    final raw = await _storage.read(key: _kUser);
    if (raw == null) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _loaded = true;
    await _bestEffort(
      Future.wait([
        _storage.delete(key: _kAccess),
        _storage.delete(key: _kRefresh),
        _storage.delete(key: _kUser),
      ]),
    );
  }

  /// Persistance Keychain qui ne peut ni bloquer ni faire échouer l'appelant :
  /// la mémoire est déjà à jour, on ignore un Keychain lent ou bloqué.
  Future<void> _bestEffort(Future<Object?> op) async {
    try {
      await op.timeout(const Duration(seconds: 5));
    } catch (_) {}
  }
}
