/// Chemins de navigation de l'application.
///
/// Source unique des routes : on ne référence jamais une chaîne en dur ailleurs.
abstract final class AppRoutes {
  const AppRoutes._();

  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const home = '/';
  static const scan = '/scan';
  static const payment = '/payment';

  // Identité client (liaison du numéro par OTP)
  static const linkPhone = '/link-phone';
  static const linkPhoneVerify = '/link-phone/verify';
  static const clientAccount = '/account';
  static const myDropOffs = '/my-dropoffs';

  // Personnel (agent / admin)
  static const login = '/login';
  static const agentQueue = '/agent/queue';
  static const agentNewDropOff = '/agent/new-dropoff';
  static const agentSearch = '/agent/search';
  static String agentDropOffDetail(String id) => '/agent/dropoffs/$id';
  static String agentAssignMachine(String id) =>
      '/agent/dropoffs/$id/assign-machine';
}
