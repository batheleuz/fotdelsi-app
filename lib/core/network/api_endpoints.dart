/// Endpoints de l'API FOTDELSY.
///
/// Source unique des URLs : aucun chemin en dur ailleurs. La base est
/// injectable au build via `--dart-define=API_BASE_URL=...` (10.0.2.2 = host
/// de la machine depuis l'émulateur Android).
abstract final class ApiEndpoints {
  const ApiEndpoints._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://192.168.2.100:8080/api/v1',
  );

  static const String webSocketUrl = String.fromEnvironment(
    'WEB_SOCKET_URL',
    defaultValue: 'http://192.168.2.100:8080',
  );

  // Machines
  static const String machines = '/machines';
  static String machine(String id) => '/machines/$id';

  // Paiement
  static const String paymentsInitiate = '/payments/initiate';
  static String session(String token) => '/sessions/$token';

  // Auth
  static const String login = '/auth/login';
}
