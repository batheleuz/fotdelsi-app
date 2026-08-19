/// Chemins de navigation de l'application.
///
/// Source unique des routes : on ne référence jamais une chaîne en dur ailleurs.
abstract final class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/';
  static const scan = '/scan';

  /// Choix de la machine pour une prestation déjà choisie (parcours accueil).
  static const pickMachine = '/services/machine';

  /// Choix de la prestation pour une machine déjà scannée (parcours QR).
  static const pickFormula = '/services/formula';

  static const payment = '/payment';

  // Identité client (liaison du numéro par OTP)
  static const linkPhone = '/link-phone';
  static const linkPhoneVerify = '/link-phone/verify';
  static const clientAccount = '/account';
  static const myDropOffs = '/my-dropoffs';
  static String myDropOffDetail(String id) => '/my-dropoffs/$id';

  // Personnel (agent / admin)
  static const login = '/login';

  /// Point d'entrée de l'espace agent — actions d'abord, file ensuite.
  static const agentHome = '/agent';
  static const agentQueue = '/agent/queue';
  static const agentNewDropOff = '/agent/new-dropoff';

  /// Vente d'un cycle au comptoir, pour un client sans l'application.
  static const agentSale = '/agent/sale';

  /// Remises libre-service dont le linge n'est pas encore arrivé.
  static const agentHandoffs = '/agent/handoffs';

  /// Historique complet des dépôts — tous les jours, tous les statuts.
  static const agentHistory = '/agent/history';
  static const agentPendingPayments = '/agent/pending-payments';
  static const agentCycles = '/agent/cycles';
  static const myCycles = '/my-cycles';
  static const agentSearch = '/agent/search';
  static String agentDropOffDetail(String id) => '/agent/dropoffs/$id';
  static String agentAssignMachine(String id) =>
      '/agent/dropoffs/$id/assign-machine';
  static String agentStartDrying(String id) =>
      '/agent/dropoffs/$id/start-drying';
}
