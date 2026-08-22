import 'package:flutter/material.dart';
import 'package:fotdelsi/app.dart';

import 'core/connectivity/connectivity_cubit.dart';
import 'core/di/service_locator.dart';
import 'core/onboarding/onboarding_store.dart';
import 'core/push/noop_push_messaging.dart';
import 'core/router/app_router.dart';
import 'core/auth/client_session_store.dart';
import 'core/showcase/showcase_http_adapter.dart';
import 'core/showcase/showcase_story.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/notifications/presentation/push_notification_service.dart';

/// Point d'entrée « vitrine » — sert **uniquement** à prendre les captures
/// d'écran de la fiche App Store.
///
///     flutter run -t lib/main_showcase.dart
///
/// L'application est la vraie, entièrement : mêmes écrans, mêmes cubits, mêmes
/// dépôts, même désérialisation. Seules trois choses changent, et chacune pour
/// une raison précise :
///
///  1. **Le réseau** est servi par [ShowcaseHttpAdapter] au lieu du serveur.
///     Une laverie n'a pas quatre cycles photogéniques en cours au moment où
///     on décide de prendre les captures, et les remettre en scène à la main
///     exigerait un vrai paiement Wave et une vraie machine — à refaire à
///     chaque version.
///  2. **Le push** est neutralisé, ce qui permet de se passer de Firebase :
///     inutile ici, et `Firebase.initializeApp` exigerait une configuration
///     valide pour l'identifiant de développement.
///  3. **La session client est semée** : sans numéro lié, l'accueil s'affiche
///     en mode anonyme et aucune des captures intéressantes n'existe.
///  4. **La connectivité est déclarée en ligne** : sur simulateur,
///     `connectivity_plus` ne voit aucune interface et le bandeau « hors
///     ligne » se pose en travers de chaque capture.
///
/// Ce fichier n'est jamais compilé dans le binaire de production : `main.dart`
/// reste le point d'entrée par défaut, et rien n'importe celui-ci.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupLocator(
    httpAdapter: ShowcaseHttpAdapter(),
    pushMessaging: const NoopPushMessaging(),
    connectivityCubit: ConnectivityCubit.alwaysOnline(),
  );

  // Le client est déjà connu : on entre directement dans l'application, sans
  // onboarding ni écran de liaison de numéro.
  await serviceLocator<ClientSessionStore>().save(
    token: ShowcaseStory.sessionToken,
    phone: ShowcaseStory.clientPhone,
  );
  await serviceLocator<OnboardingStore>().markSeen();

  final authCubit = serviceLocator<AuthCubit>();
  final router = AppRouter.create(authCubit);

  serviceLocator<PushNotificationService>().init(router);

  runApp(FotDelsiApp(router: router));
}
