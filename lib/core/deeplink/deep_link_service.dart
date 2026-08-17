import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:fotdelsi/core/di/service_locator.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import 'package:fotdelsi/features/wash_session/presentation/cubit/wash_session_cubit.dart';

/// Écoute les deep links `fotdelsi://…` et réagit en conséquence.
///
/// Aujourd'hui un seul usage : le retour depuis le paiement Wave / Orange
/// Money. Les pages web servies par le backend (`/payments/return|cancel`)
/// affichent un bouton « Retourner à l'application » pointant sur :
///   - `fotdelsi://payment/return` → paiement confirmé
///   - `fotdelsi://payment/cancel` → paiement annulé
///
/// Le statut réel reste confirmé côté serveur (webhook) ; ce lien sert juste à
/// ramener l'utilisateur dans l'app et à forcer un rafraîchissement immédiat
/// de la session de lavage (au lieu d'attendre le simple retour au premier
/// plan).
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _sub;
  GoRouter? _router;
  GlobalKey<ScaffoldMessengerState>? _messengerKey;

  /// À appeler une fois au démarrage, après la création du routeur.
  void start({
    required GoRouter router,
    required GlobalKey<ScaffoldMessengerState> messengerKey,
  }) {
    _router = router;
    _messengerKey = messengerKey;

    // Lancement à froid via le lien (app fermée au moment du tap).
    unawaited(
      _appLinks.getInitialLink().then((uri) {
        if (uri != null) _handle(uri);
      }),
    );

    // App déjà lancée : liens reçus pendant l'exécution.
    _sub = _appLinks.uriLinkStream.listen(_handle);
  }

  void _handle(Uri uri) {
    if (uri.scheme != 'fotdelsi' || uri.host != 'payment') return;

    switch (uri.path) {
      case '/return':
        _router?.go(AppRoutes.home);
        // Force la resynchronisation immédiate de la session (paiement confirmé).
        serviceLocator<WashSessionCubit>().onAppResumed();
        _snack('Paiement reçu. Votre machine est prête à démarrer.');
      case '/cancel':
        _router?.go(AppRoutes.home);
        _snack('Paiement annulé. Vous pouvez réessayer quand vous voulez.');
    }
  }

  void _snack(String message) {
    final messenger = _messengerKey?.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
