import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage sécurisé de la session client (identité par numéro, OTP SMS).
///
/// Distinct de [AuthTokenStore] (personnel/JWT) : le client a un jeton opaque
/// longue durée, sans refresh, envoyé en `Authorization: Bearer`. Les deux
/// identités sont mutuellement exclusives sur un même appareil.
///
/// Même modèle que [AuthTokenStore] : cache mémoire (source de vérité pour les
/// lectures du chemin critique de l'intercepteur), Keychain uniquement pour la
/// persistance — afin qu'une lecture Keychain bloquée au réveil iOS ne gèle pas
/// toutes les requêtes.
class ClientSessionStore {
  ClientSessionStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _kToken = 'client_session_token';
  static const _kPhone = 'client_session_phone';

  String? _token;
  String? _phone;
  bool _loaded = false;
  Future<void>? _loading;

  /// Précharge la session en mémoire (à appeler au démarrage). Idempotent.
  Future<void> preload() => _ensureLoaded();

  Future<void> _ensureLoaded() {
    if (_loaded) return Future<void>.value();
    return _loading ??= _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _storage.read(key: _kToken),
        _storage.read(key: _kPhone),
      ]).timeout(const Duration(seconds: 5));
      _token = results[0];
      _phone = results[1];
    } catch (_) {
      // Keychain bloqué/indisponible : on n'attend pas indéfiniment.
    } finally {
      _loaded = true;
      _loading = null;
    }
  }

  Future<void> save({required String token, required String phone}) async {
    _token = token;
    _phone = phone;
    _loaded = true;
    await _bestEffort(Future.wait([
      _storage.write(key: _kToken, value: token),
      _storage.write(key: _kPhone, value: phone),
    ]));
  }

  Future<String?> token() async {
    await _ensureLoaded();
    return _token;
  }

  Future<String?> phone() async {
    await _ensureLoaded();
    return _phone;
  }

  Future<void> clear() async {
    _token = null;
    _phone = null;
    _loaded = true;
    await _bestEffort(Future.wait([
      _storage.delete(key: _kToken),
      _storage.delete(key: _kPhone),
    ]));
  }

  Future<void> _bestEffort(Future<Object?> op) async {
    try {
      await op.timeout(const Duration(seconds: 5));
    } catch (_) {}
  }
}
