/// Chemins de navigation de l'application.
///
/// Source unique des routes : on ne référence jamais une chaîne en dur ailleurs.
abstract final class AppRoutes {
  const AppRoutes._();

  static const onboarding = '/onboarding';
  static const home = '/';
  static const scan = '/scan';
  static const payment = '/payment';

  // Personnel (agent / admin)
  static const login = '/login';
  static const agentQueue = '/agent/queue';
}
