import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/machines/presentation/pages/home_page.dart';
import 'package:fotdelsi/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:fotdelsi/features/payment/presentation/pages/payment_page.dart';
import 'package:fotdelsi/features/payment/presentation/pages/scan_page.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';

/// Arguments typés passés via `extra` (records — pas de classe dédiée).
typedef PaymentArgs = ({Machine machine});

/// Navigation centralisée de l'application.
abstract final class AppRouter {
  const AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.onboarding,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.scan,
        builder: (context, state) => const ScanPage(),
      ),
      GoRoute(
        path: AppRoutes.payment,
        builder: (context, state) {
          final args = state.extra! as PaymentArgs;
          return PaymentPage(machine: args.machine);
        },
      ),
    ],
  );
}
