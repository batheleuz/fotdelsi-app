/// Endpoints de l'API FOTDELSY.
///
/// Source unique des URLs : aucun chemin en dur ailleurs. La base est
/// injectable au build via `--dart-define=API_BASE_URL=...` (10.0.2.2 = host
/// de la machine depuis l'émulateur Android).
abstract final class ApiEndpoints {
  const ApiEndpoints._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.fotdelsi.sn/api/v1',
    // defaultValue: 'http://192.168.2.100:8080/api/v1',
  );

  static const String webSocketUrl = String.fromEnvironment(
    'WEB_SOCKET_URL',
    defaultValue: 'https://api.fotdelsi.sn',
    // defaultValue: 'http://192.168.2.100:8080',
  );

  // Disponibilité des services (bannière) — public
  static const String status = '/status';

  // Catalogue de services (formules + grille tarifaire)
  static const String serviceFormulas = '/service-formulas';

  // Machines
  static const String machines = '/machines';
  static String machine(String id) => '/machines/$id';
  static String machineByDeviceName(String deviceName) =>
      '/machines/device/$deviceName';

  // Paiement
  static const String paymentsInitiate = '/payments/initiate';

  // Wash Session
  static String sessionStatus(String token) => '/wash-sessions/$token/status';
  static const String startMachine = '/wash-sessions/start';
  static const String startDrying = '/wash-sessions/start-drying';

  /// Cycles vendus au comptoir : à démarrer, en cours, terminés (24 h).
  static const String counterSaleCycles = '/wash-sessions/counter-sales';

  /// Cycles du client authentifié (jeton de session client).
  static const String myCycles = '/me/cycles';

  // Auth
  static const String login = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authLogout = '/auth/logout';

  // Identité client (OTP SMS)
  static const String linkPhoneStart = '/me/link-phone/start';
  static const String requestOtp = '/me/link-phone/request-otp';
  static const String verifyOtp = '/me/link-phone/verify-otp';
  static const String clientLogout = '/me/logout';

  /// Profil du client authentifié (lecture et modification du nom).
  static const String clientProfile = '/me/profile';
  static const String myDropOffs = '/me/dropoffs';
  static String myDropOff(String id) => '/me/dropoffs/$id';

  // Notifications push
  static const String devices = '/me/devices';
  static String ackNotification(String id) => '/notifications/$id/ack';

  // Drop-offs (agent / admin)
  static const String dropOffDraft = '/drop-offs/draft';
  static const String dropOffQueue = '/drop-offs/queue';
  static const String dropOffHandoffs = '/drop-offs/handoffs';
  static const String dropOffPendingPayment = '/drop-offs/pending-payment';
  static String dropOffByCode(String code) => '/drop-offs/by-code/$code';
  static String dropOff(String id) => '/drop-offs/$id';
  static String dropOffAssignMachine(String id) =>
      '/drop-offs/$id/assign-machine';
  static String dropOffStartDrying(String id) => '/drop-offs/$id/start-drying';
  static String dropOffReceive(String id) => '/drop-offs/$id/receive';
  static String dropOffMarkReady(String id) => '/drop-offs/$id/mark-ready';
  static String dropOffMarkCollected(String id) =>
      '/drop-offs/$id/mark-collected';
  static String dropOffLaundry(String id) => '/drop-offs/$id/laundry';
}
