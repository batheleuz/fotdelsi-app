import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/agent_handoffs_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/drop_off_history_page.dart';
import 'package:fotdelsi/features/wash_session/presentation/pages/direct_cycles_history_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/pending_payments_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/agent_home_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/drop_off_queue_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/cubit/assign_machine_cubit.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/assign_machine_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/drop_off_detail_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/drop_off_search_page.dart';
import 'package:fotdelsi/features/counter_sale/presentation/pages/counter_sale_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/new_dropoff_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/my_dropoffs_page.dart';
import 'package:fotdelsi/features/dropoffs/presentation/pages/my_dropoff_detail_page.dart';
import 'package:fotdelsi/features/auth/domain/entities/auth_role.dart';
import 'package:fotdelsi/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:fotdelsi/features/auth/presentation/pages/login_page.dart';
import 'package:fotdelsi/features/client_auth/presentation/pages/client_account_page.dart';
import 'package:fotdelsi/features/client_auth/presentation/pages/link_phone_page.dart';
import 'package:fotdelsi/features/client_auth/presentation/pages/otp_verify_page.dart';
import 'package:fotdelsi/features/catalog/domain/entities/service_formula.dart';
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
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_cycles_cubit.dart';
import 'package:fotdelsi/features/wash_session/presentation/pages/wash_cycles_page.dart';

/// Arguments typés passés via `extra` (records — pas de classe dédiée).
///
/// Une commande libre-service, c'est toujours un couple (prestation, machine).
/// Les deux parcours n'en changent que l'ordre de saisie : depuis l'accueil on
/// choisit la formule puis la machine, depuis le QR la machine est déjà connue.
/// `formula` à `null` : vente à la machine, arrivée par le scan. Aucune
/// prestation n'a été choisie — il n'y en avait pas à choisir — et le prix
/// vient de la machine elle-même.
typedef PaymentArgs = ({ServiceFormula? formula, Machine machine});

/// Choix de la machine pour une formule déjà sélectionnée.
typedef PickMachineArgs = ({ServiceFormula formula});

/// Choix de la formule pour une machine déjà identifiée (parcours QR).
// `PickFormulaArgs` retiré avec l'écran qu'il servait : le scan menait au
// choix d'une prestation, et c'était son seul appelant. On part désormais de
// la prestation (accueil) ou de la machine (scan) — jamais de la machine VERS
// la prestation, qui promettait un pliage sur une sécheuse.

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
        if (isAgent) return AppRoutes.agentHome;
        // Onboarding uniquement à la première ouverture.
        return serviceLocator<OnboardingStore>().hasSeen
            ? AppRoutes.home
            : AppRoutes.onboarding;
      }

      // Personnel authentifié (agent) → espace agent.
      if (isAgent) {
        return inAgentArea ? null : AppRoutes.agentHome;
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
        builder: (context, state) {
          final formula = state.extra as ServiceFormula?;
          return ScanPage(formula: formula);
        },
      ),
      GoRoute(
        path: AppRoutes.pickMachine,
        builder: (context, state) {
          final formula = switch (state.extra) {
            final PickMachineArgs args => args.formula,
            final ServiceFormula f => f,
            _ => null,
          };
          return ScanPage(formula: formula);
        },
      ),
      GoRoute(
        path: AppRoutes.payment,
        builder: (context, state) {
          final args = state.extra! as PaymentArgs;
          return PaymentPage(formula: args.formula, machine: args.machine);
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
        // Même page que l'espace agent, autre périmètre : le cubit décide.
        path: AppRoutes.myCycles,
        builder: (context, state) => WashCyclesPage(
          createCubit: () => serviceLocator<MyCyclesCubit>(),
          layout: CyclesLayout.history,
          explanation:
              'Tous vos lavages. Lancez la machine une fois votre linge '
              'chargé, puis suivez le temps restant ici.',
        ),
      ),
      GoRoute(
        path: '/my-dropoffs/:id',
        builder: (context, state) =>
            MyDropOffDetailPage(dropOffId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.agentHome,
        builder: (context, state) => const AgentHomePage(),
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
        path: AppRoutes.agentSale,
        builder: (context, state) => const CounterSalePage(),
      ),
      GoRoute(
        path: AppRoutes.agentHandoffs,
        builder: (context, state) => const AgentHandoffsPage(),
      ),
      GoRoute(
        path: AppRoutes.agentHistory,
        builder: (context, state) => const DropOffHistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.agentDirectCyclesHistory,
        builder: (context, state) => const DirectCyclesHistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.agentPendingPayments,
        builder: (context, state) => const PendingPaymentsPage(),
      ),
      GoRoute(
        path: AppRoutes.agentCycles,
        builder: (context, state) => WashCyclesPage(
          createCubit: () => serviceLocator<CounterSaleCyclesCubit>(),
          layout: CyclesLayout.worklist,
          // Le défaut « Mes cycles » est celui de l'écran CLIENT : sur le
          // poste agent, ces cycles ne sont pas les siens, ce sont ceux qu'il
          // a vendus. Même nom que partout ailleurs dans l'espace agent.
          title: 'Cycles',
          explanation:
              'Ces cycles ont été vendus au comptoir et payés. Chargez le '
              'linge, puis lancez la machine ici.',
        ),
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
