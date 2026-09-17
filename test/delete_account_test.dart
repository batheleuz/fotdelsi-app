import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/core/auth/client_session_store.dart';
import 'package:fotdelsi/core/network/api_endpoints.dart';
import 'package:fotdelsi/features/client_auth/data/datasources/client_auth_api_data_source.dart';
import 'package:fotdelsi/features/client_auth/data/repositories/client_auth_repository_impl.dart';

/// Stockage en mémoire : les tests ne touchent pas le Keychain.
class _InMemoryStorage extends FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async => values[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

/// Répond à `DELETE /me` : succès, ou l'échec demandé.
class _Adapter implements HttpClientAdapter {
  _Adapter({this.statut = 200});

  final int statut;
  final List<String> appels = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    appels.add('${options.method} ${options.path}');
    if (statut != 200) {
      throw DioException.badResponse(
        statusCode: statut,
        requestOptions: options,
        response: Response<dynamic>(
          requestOptions: options,
          statusCode: statut,
        ),
      );
    }
    return ResponseBody.fromString(
      '{"data":{"deleted":true}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

({ClientAuthRepositoryImpl repo, ClientSessionStore session, _Adapter adapter})
_monter({int statut = 200}) {
  final adapter = _Adapter(statut: statut);
  final dio = Dio()..httpClientAdapter = adapter;
  final session = ClientSessionStore(_InMemoryStorage());
  return (
    repo: ClientAuthRepositoryImpl(ClientAuthApiDataSource(dio), session),
    session: session,
    adapter: adapter,
  );
}

void main() {
  test(
    'la suppression appelle DELETE /me et purge la session locale',
    () async {
      final t = _monter();
      await t.session.save(token: 'jeton', phone: '771234567');

      final result = await t.repo.deleteAccount();

      expect(result.isRight(), isTrue);
      expect(t.adapter.appels, ['DELETE ${ApiEndpoints.clientAccount}']);
      expect(await t.session.phone(), isNull);
    },
  );

  test('un échec serveur laisse la session en place', () async {
    // Purger d'abord priverait le client du seul moyen de relancer la
    // suppression : sans jeton, `DELETE /me` répond 401. Son compte vivrait
    // encore, et son téléphone continuerait d'être notifié.
    final t = _monter(statut: 500);
    await t.session.save(token: 'jeton', phone: '771234567');

    final result = await t.repo.deleteAccount();

    expect(result.isLeft(), isTrue);
    expect(await t.session.phone(), '771234567');
  });
}
