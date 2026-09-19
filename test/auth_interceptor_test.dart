import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fotdelsi/core/auth/auth_token_store.dart';
import 'package:fotdelsi/core/auth/client_session_store.dart';
import 'package:fotdelsi/core/network/auth_interceptor.dart';

class _MemoryStorage extends FlutterSecureStorage {
  _MemoryStorage();

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

class _AuthAdapter implements HttpClientAdapter {
  _AuthAdapter({this.refreshStatus = 200});

  final int refreshStatus;
  int refreshCalls = 0;
  int protectedCalls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path.endsWith('/auth/refresh')) {
      refreshCalls++;
      await Future<void>.delayed(const Duration(milliseconds: 20));
      if (refreshStatus != 200) {
        return _json(refreshStatus, '{"message":"Refresh refusé"}');
      }
      expect(options.headers['Cookie'], 'jwt=refresh-0');
      return _json(
        200,
        '{"data":{"tokens":{'
        '"accessToken":"access-1","refreshToken":"refresh-1"}}}',
      );
    }

    protectedCalls++;
    final authorization = options.headers['Authorization'];
    if (authorization == 'Bearer access-1') {
      return _json(200, '{"data":{"ok":true}}');
    }

    await Future<void>.delayed(const Duration(milliseconds: 10));
    return _json(401, '{"message":"Vous devez vous reconnecter."}');
  }

  ResponseBody _json(int status, String body) => ResponseBody.fromString(
    body,
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );

  @override
  void close({bool force = false}) {}
}

Future<({Dio dio, AuthTokenStore store})> _authenticatedClient(
  _AuthAdapter adapter, {
  Future<void> Function()? onExpired,
}) async {
  final storage = _MemoryStorage();
  final store = AuthTokenStore(storage);
  await store.saveSession(
    accessToken: 'access-0',
    refreshToken: 'refresh-0',
    user: const {'id': 'agent-1', 'role': 'AGENT'},
  );

  Dio plainDio() {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
    dio.httpClientAdapter = adapter;
    return dio;
  }

  final dio = plainDio();
  dio.interceptors.add(
    AuthInterceptor(
      store,
      ClientSessionStore(storage),
      'https://api.test',
      onAgentSessionExpired: onExpired,
      dioFactory: plainDio,
    ),
  );
  return (dio: dio, store: store);
}

void main() {
  group('AuthInterceptor — rotation du refresh token', () {
    test('un seul refresh récupère plusieurs requêtes agent en 401', () async {
      final adapter = _AuthAdapter();
      final client = await _authenticatedClient(adapter);

      final responses = await Future.wait([
        client.dio.get<dynamic>('/drop-offs/queue'),
        client.dio.get<dynamic>('/drop-offs/handoffs'),
        client.dio.get<dynamic>('/wash-sessions/counter-sales'),
        client.dio.get<dynamic>('/drop-offs/pending-payment'),
      ]);

      expect(
        responses.map((response) => response.statusCode),
        everyElement(200),
      );
      expect(adapter.refreshCalls, 1);
      expect(await client.store.accessToken(), 'access-1');
      expect(await client.store.refreshToken(), 'refresh-1');
    });

    test(
      'une panne du refresh conserve la session pour le prochain essai',
      () async {
        final adapter = _AuthAdapter(refreshStatus: 500);
        var expirations = 0;
        final client = await _authenticatedClient(
          adapter,
          onExpired: () async => expirations++,
        );

        await expectLater(
          client.dio.get<dynamic>('/drop-offs/queue'),
          throwsA(
            isA<DioException>().having(
              (error) => error.response?.statusCode,
              'refresh status',
              500,
            ),
          ),
        );

        expect(expirations, 0);
        expect(await client.store.accessToken(), 'access-0');
        expect(await client.store.refreshToken(), 'refresh-0');
      },
    );

    test('un refresh réellement refusé invalide la session agent', () async {
      final adapter = _AuthAdapter(refreshStatus: 401);
      var expirations = 0;
      final client = await _authenticatedClient(
        adapter,
        onExpired: () async => expirations++,
      );

      await expectLater(
        client.dio.get<dynamic>('/drop-offs/queue'),
        throwsA(
          isA<DioException>().having(
            (error) => error.response?.statusCode,
            'refresh status',
            401,
          ),
        ),
      );

      expect(expirations, 1);
      expect(await client.store.accessToken(), isNull);
      expect(await client.store.refreshToken(), isNull);
    });
  });
}
