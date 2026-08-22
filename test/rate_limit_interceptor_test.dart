import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fotdelsi/core/network/rate_limit_interceptor.dart';

/// Adaptateur scriptable : chaque appel consomme la réponse suivante.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.statuses);

  final List<int> statuses;
  final List<RequestOptions> calls = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    calls.add(options);
    final status = statuses.removeAt(0);
    return ResponseBody.fromString(
      '{"code":"OK","message":"","data":{}}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
        if (status == 429) 'ratelimit-reset': ['1'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

Dio _dio(_FakeAdapter adapter) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.test'));
  dio.httpClientAdapter = adapter;
  // Attente neutralisée : le test vérifie la reprise, pas l'horloge.
  dio.interceptors.add(RateLimitInterceptor(dio, delay: (_) async {}));
  return dio;
}

void main() {
  group('Refus de débit — reprise silencieuse', () {
    test('rejoue une lecture refusée et rend la seconde réponse', () async {
      // Un 429 isolé est un accident de synchronisation : cinq listes qui se
      // rechargent au même signal. Le remonter à l'agent ferait passer pour
      // une panne ce qu'une pause résout.
      final adapter = _FakeAdapter([429, 200]);

      final response = await _dio(adapter).get<dynamic>('/agent/queue');

      expect(response.statusCode, 200);
      expect(adapter.calls, hasLength(2));
    });

    test('ne rejoue jamais une écriture', () async {
      // Rejouer un démarrage de machine lancerait un cycle en double, sur un
      // tambour que personne n'a rechargé.
      final adapter = _FakeAdapter([429]);

      await expectLater(
        _dio(adapter).post<dynamic>('/wash-sessions/start'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            429,
          ),
        ),
      );
      expect(adapter.calls, hasLength(1));
    });

    test('abandonne après une seule reprise', () async {
      // Réessayer en boucle ajouterait de la charge à un serveur qui vient de
      // dire qu'il en a trop.
      final adapter = _FakeAdapter([429, 429]);

      await expectLater(
        _dio(adapter).get<dynamic>('/agent/queue'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, hasLength(2));
    });

    test('laisse passer les autres erreurs sans les rejouer', () async {
      final adapter = _FakeAdapter([500]);

      await expectLater(
        _dio(adapter).get<dynamic>('/agent/queue'),
        throwsA(isA<DioException>()),
      );
      expect(adapter.calls, hasLength(1));
    });
  });
}
