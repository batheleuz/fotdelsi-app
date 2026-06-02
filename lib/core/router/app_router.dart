import 'package:fotdelsi/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Arguments typés passés via `extra` (records — pas de classe dédiée).
typedef PaymentArgs = ({String machineName, String programLabel, int total});
typedef ConfirmationArgs = ({String machineName, String programLabel});

/// Navigation centralisée de l'application.
///
/// Toutes les routes sont déclarées ici ; les écrans ne connaissent que les
/// constantes [AppRoutes] et `context.go/push`. Modifier le flux (ex. retirer
/// l'étape programme) se fait en un seul endroit.
abstract final class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingPage(),
      ),
    ],
  );
}
