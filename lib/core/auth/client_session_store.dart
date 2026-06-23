import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stockage sécurisé de la session client (identité par numéro, OTP SMS).
///
/// Distinct de [AuthTokenStore] (personnel/JWT) : le client a un jeton opaque
/// longue durée, sans refresh, envoyé en `Authorization: Bearer`. Les deux
/// identités sont mutuellement exclusives sur un même appareil.
class ClientSessionStore {
  const ClientSessionStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _kToken = 'client_session_token';
  static const _kPhone = 'client_session_phone';

  Future<void> save({required String token, required String phone}) async {
    await Future.wait([
      _storage.write(key: _kToken, value: token),
      _storage.write(key: _kPhone, value: phone),
    ]);
  }

  Future<String?> token() => _storage.read(key: _kToken);

  Future<String?> phone() => _storage.read(key: _kPhone);

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _kToken),
      _storage.delete(key: _kPhone),
    ]);
  }
}
