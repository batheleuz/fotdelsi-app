import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/drop_off_queue_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/assign_machine_cubit.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/assign_machine_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/drop_off_detail_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/drop_off_search_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/new_dropoff_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/my_dropoffs_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/my_dropoff_detail_page.dart';
import 'package:fotdelsi/features/auth/domain/entities/auth_role.dart';
import 'package:fotdelsi/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fotdelsi/features/auth/presentation/pages/login_page.dart';
import 'package:fotdelsi/features/client_auth/presentation/pages/client_account_page.dart';
import 'package:fotdelsi/features/client_auth/presentation/pages/link_phone_page.dart';
import 'package:fotdelsi/features/client_auth/presentation/pages/otp_verify_page.dart';
import 'package:fotdelsi/features/machines/domain/entities/machine.dart';
import 'package:fotdelsi/features/machines/presentation/pages/home_page.dart';
import 'package:fotdelsi/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:fotdelsi/features/payment/presentation/pages/payment_page.dart';
import 'package:fotdelsi/features/payment/presentation/pages/scan_page.dart';
import 'package:fotdelsi/features/splash/presentation/pages/splash_page.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/onboarding/onboarding_store.dart';

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
    initialLocation: AppRoutes.splash,
    refreshListenable: _AuthRefresh(auth.stream),
    redirect: (context, state) {
      final authState = auth.state;
      final loccation = state.matchedLocation;
      final inAgentArea = loccation.startsWith('/agent');

      // Profil pas encore déterminé → on reste sur le splash.
      if (authState.status == AuthStatus.unknown) {
        return loccation == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final isAgent =
          authState.isAuthenticated && authState.user?.role == AuthRole.agent;

      // Profil connu → on quitte le splash vers la bonne destination.
      if (loccation == AppRoutes.splash) {
        if (isAgent) return AppRoutes.agentQueue;
        // Onboarding uniquement à la première ouverture.
        return serviceLocator<OnboardingStore>().hasSeen
            ? AppRoutes.home
            : AppRoutes.onboarding;
      }

      // Personnel authentifié (agent) → espace agent.
      if (isAgent) {
        return inAgentArea ? null : AppRoutes.agentQueue;
      }

      // Non authentifié tentant d'accéder à l'espace agent → login.
      if (inAgentArea) {
        return AppRoutes.login;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
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
        path: AppRoutes.linkPhone,
        builder: (context, state) => const LinkPhonePage(),
      ),
      GoRoute(
        path: AppRoutes.linkPhoneVerify,
        builder: (context, state) =>
            OtpVerifyPage(phone: state.extra! as String),
      ),
      GoRoute(
        path: AppRoutes.clientAccount,
        builder: (context, state) => const ClientAccountPage(),
      ),
      GoRoute(
        path: AppRoutes.myDropOffs,
        builder: (context, state) => const MyDropOffsPage(),
      ),
      GoRoute(
        path: '/my-dropoffs/:id',
        builder: (context, state) =>
            MyDropOffDetailPage(dropOffId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.agentQueue,
        builder: (context, state) => const DropOffQueuePage(),
      ),
      GoRoute(
        path: AppRoutes.agentNewDropOff,
        builder: (context, state) => const NewDropOffPage(),
      ),
      GoRoute(
        path: AppRoutes.agentSearch,
        builder: (context, state) => const DropOffSearchPage(),
      ),
      GoRoute(
        path: '/agent/dropoffs/:id',
        builder: (context, state) =>
            DropOffDetailPage(dropOffId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/agent/dropoffs/:id/assign-machine',
        builder: (context, state) =>
            AssignMachinePage(dropOffId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/agent/dropoffs/:id/start-drying',
        builder: (context, state) => AssignMachinePage(
          dropOffId: state.pathParameters['id']!,
          mode: AssignMode.dry,
        ),
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
