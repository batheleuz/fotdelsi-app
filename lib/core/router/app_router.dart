import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fotdelsi/features/agent/presentation/pages/agent_queue_page.dart';
import 'package:fotdelsi/features/auth/domain/entities/auth_role.dart';
import 'package:fotdelsi/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fotdelsi/features/auth/presentation/pages/login_page.dart';
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
///
/// Le routeur est construit avec [AuthCubit] : le `redirect` aiguille selon le
/// rôle (un agent authentifié est verrouillé sur `/agent/*`), et
/// `refreshListenable` réévalue la navigation à chaque login/logout.
abstract final class AppRouter {
  const AppRouter._();

  static GoRouter create(AuthCubit auth) => GoRouter(
        initialLocation: AppRoutes.onboarding,
        refreshListenable: _AuthRefresh(auth.stream),
        redirect: (context, state) {
          final s = auth.state;
          final loc = state.matchedLocation;
          final inAgentArea = loc.startsWith('/agent');

          // Agent connecté : verrouillé sur l'espace agent.
          if (s.isAuthenticated && s.role == AuthRole.agent) {
            return inAgentArea ? null : AppRoutes.agentQueue;
          }

          // Non authentifié tentant d'accéder à l'espace agent → login.
          if (!s.isAuthenticated && inAgentArea) {
            return AppRoutes.login;
          }

          return null;
        },
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
          GoRoute(
            path: AppRoutes.login,
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: AppRoutes.agentQueue,
            builder: (context, state) => const AgentQueuePage(),
          ),
        ],
      );
}

/// Pont [Stream] → [Listenable] pour rafraîchir GoRouter à chaque changement
/// d'état d'auth (login / logout).
class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
