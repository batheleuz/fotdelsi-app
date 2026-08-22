import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:fotdelsi/core/auth/auth_token_store.dart';
import 'package:fotdelsi/core/auth/client_session_store.dart';
import 'package:fotdelsi/core/push/push_messaging.dart';
import 'package:fotdelsi/core/router/app_routes.dart';
import '../domain/entities/notification_kind.dart';
import '../domain/entities/notification_payload.dart';
import '../domain/repositories/notification_repository.dart';

/// Orchestrateur des notifications push (indépendant de Firebase via
/// [PushMessaging]).
///
/// Responsabilités :
///  - demander la permission et enregistrer le device (`POST /me/devices`)
///    dès qu'un numéro est lié, + à chaque rotation du jeton ;
///  - au tap sur une notification (background / app tuée) : **acquitter**
///    (`POST /notifications/:id/ack`, annule le SMS de repli) puis **router**
///    selon le `kind` (ouvrir Wave/OM, ou naviguer vers « Mes dépôts »).
///
/// L'affichage des notifications en foreground (flutter_local_notifications)
/// sera ajouté avec l'implémentation Firebase.
class PushNotificationService {
  PushNotificationService(
    this._messaging,
    this._repository,
    this._clientStore,
    this._authStore,
  );

  final PushMessaging _messaging;
  final NotificationRepository _repository;
  final ClientSessionStore _clientStore;
  final AuthTokenStore _authStore;

  GoRouter? _router;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<Map<String, dynamic>>? _openedSub;

  /// À appeler une fois au démarrage (après création du routeur).
  Future<void> init(GoRouter router) async {
    _router = router;

    // La mise en place FCM peut lever sur certaines plateformes (ex. iOS
    // simulateur sans APNs). On isole chaque étape pour que l'enregistrement
    // du device soit tout de même tenté et que l'erreur soit visible.
    try {
      await _messaging.initialize();
      await _messaging.requestPermission();
    } catch (e) {
      if (kDebugMode) debugPrint('[push] init FCM a échoué : $e');
    }

    await registerDeviceIfLinked();

    _tokenSub?.cancel();
    _tokenSub = _messaging.onTokenRefresh.listen(
      (_) => registerDeviceIfLinked(),
    );

    _openedSub?.cancel();
    _openedSub = _messaging.onMessageOpenedApp.listen(
      (data) => _handleTap(NotificationPayload.fromData(data)),
    );

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      await _handleTap(NotificationPayload.fromData(initial));
    }
  }

  /// Enregistre le jeton FCM sous l'identité courante, s'il y en a une.
  ///
  /// Deux identités possibles, **mutuellement exclusives sur un appareil** :
  /// un agent connecté (jeton JWT) ou un client lié (numéro). L'agent passe
  /// en premier : quand il est connecté, c'est lui qui manipule le linge, et
  /// c'est lui que les fins de cycle concernent.
  ///
  /// Chaque condition de sortie est journalisée (en debug) pour diagnostiquer
  /// les cas « aucun token en base » : aucune identité, jeton FCM indisponible
  /// (typique iOS simulateur / sans APNs), ou échec de l'appel.
  Future<void> registerDeviceIfLinked() async {
    final agentConnecte = await _authStore.accessToken() != null;
    final phone = await _clientStore.phone();

    if (!agentConnecte && phone == null) {
      if (kDebugMode) {
        debugPrint('[push] device non enregistré : aucune identité.');
      }
      return;
    }

    String? token;
    try {
      token = await _messaging.getToken();
    } catch (e) {
      if (kDebugMode) debugPrint('[push] getToken a échoué : $e');
      return;
    }
    if (token == null) {
      if (kDebugMode) {
        debugPrint(
          '[push] device non enregistré : jeton FCM indisponible '
          '(APNs non configuré sur iOS / simulateur ?).',
        );
      }
      return;
    }

    final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
    final result = agentConnecte
        ? await _repository.registerAgentDevice(
            fcmToken: token,
            platform: platform,
          )
        : await _repository.registerDevice(
            phone: phone!,
            fcmToken: token,
            platform: platform,
          );
    result.fold(
      (failure) {
        if (kDebugMode) {
          debugPrint(
            '[push] échec enregistrement device ($platform) : '
            '${failure.message}',
          );
        }
      },
      (_) {
        if (kDebugMode) {
          debugPrint(
            '[push] device enregistré ($platform), '
            'token: ${token!.substring(0, 12)}…',
          );
        }
      },
    );
  }

  Future<void> _handleTap(NotificationPayload payload) async {
    // Acquittement d'abord (annule le SMS de repli).
    if (payload.notificationId != null) {
      await _repository.ack(
        notificationId: payload.notificationId!,
        smsFallbackId: payload.smsFallbackId,
      );
    }

    switch (payload.kind) {
      case NotificationKind.paymentRequest:
        await _openPaymentUrl(payload);
      case NotificationKind.dropoffRegistered:
      case NotificationKind.washReady:
        // Droit sur le suivi du dépôt concerné, quand il est connu.
        //
        // « Mes dépôts » ne liste QUE ce qui a été confié au comptoir : une
        // finition de libre-service n'y figure pas, et y renvoyer laissait le
        // client devant une liste où son linge n'était pas.
        final id = payload.dropOffId;
        _router?.go(
          id == null ? AppRoutes.myDropOffs : AppRoutes.myDropOffDetail(id),
        );
      case NotificationKind.washToDry:
      case NotificationKind.washCycleDone:
        // Le même événement s'adresse au client ou à l'agent selon qui gère le
        // linge — et ils n'ont pas le même écran. Router les deux vers « Mes
        // lavages » enverrait l'agent sur une liste vide, la sienne étant
        // rangée ailleurs.
        final estAgent = await _authStore.accessToken() != null;
        _router?.go(estAgent ? AppRoutes.agentHome : AppRoutes.myCycles);
      case NotificationKind.unknown:
        break;
    }
  }

  Future<void> _openPaymentUrl(NotificationPayload payload) async {
    final primary = payload.primaryUrl;
    if (primary == null) return;
    try {
      await launchUrl(Uri.parse(primary), mode: LaunchMode.externalApplication);
    } catch (e) {
      final fallback = payload.fallbackUrl;
      try {
        if (fallback != null) {
          await launchUrl(
            Uri.parse(fallback),
            mode: LaunchMode.externalApplication,
          );
        } else {
          await launchUrl(Uri.parse(primary), mode: LaunchMode.inAppWebView);
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Ouverture URL paiement impossible: $e');
      }
    }
  }

  void dispose() {
    _tokenSub?.cancel();
    _openedSub?.cancel();
  }
}
