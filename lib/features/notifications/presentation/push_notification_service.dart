import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
  PushNotificationService(this._messaging, this._repository, this._clientStore);

  final PushMessaging _messaging;
  final NotificationRepository _repository;
  final ClientSessionStore _clientStore;

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
    _tokenSub = _messaging.onTokenRefresh.listen((_) => registerDeviceIfLinked());

    _openedSub?.cancel();
    _openedSub = _messaging.onMessageOpenedApp
        .listen((data) => _handleTap(NotificationPayload.fromData(data)));

    final initial = await _messaging.getInitialMessage();
    if (initial != null) {
      await _handleTap(NotificationPayload.fromData(initial));
    }
  }

  /// Enregistre le jeton FCM si un numéro est lié (sinon no-op).
  ///
  /// Chaque condition de sortie est journalisée (en debug) pour diagnostiquer
  /// les cas « aucun token en base » : numéro non lié, jeton FCM indisponible
  /// (typique iOS simulateur / sans APNs), ou échec de l'appel `/me/devices`.
  Future<void> registerDeviceIfLinked() async {
    final phone = await _clientStore.phone();
    if (phone == null) {
      if (kDebugMode) {
        debugPrint('[push] device non enregistré : aucun numéro lié.');
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
        debugPrint('[push] device non enregistré : jeton FCM indisponible '
            '(APNs non configuré sur iOS / simulateur ?).');
      }
      return;
    }

    final platform = Platform.isIOS ? 'IOS' : 'ANDROID';
    final result = await _repository.registerDevice(
      phone: phone,
      fcmToken: token,
      platform: platform,
    );
    result.fold(
      (failure) {
        if (kDebugMode) {
          debugPrint('[push] échec enregistrement device ($platform) : '
              '${failure.message}');
        }
      },
      (_) {
        if (kDebugMode) {
          debugPrint('[push] device enregistré ($platform), '
              'token: ${token!.substring(0, 12)}…');
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
        _router?.go(AppRoutes.myDropOffs);
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
          await launchUrl(Uri.parse(fallback), mode: LaunchMode.externalApplication);
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
