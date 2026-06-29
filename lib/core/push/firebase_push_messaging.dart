import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'push_messaging.dart';

/// Handler des messages reçus alors que l'app est en arrière-plan / tuée.
///
/// Doit être une fonction top-level annotée `vm:entry-point` (exécutée dans un
/// isolate séparé). Le backend joint un bloc `notification` : c'est donc le
/// système qui affiche la notif dans la barre — rien à faire ici. Le tap est
/// géré au réveil via `onMessageOpenedApp` / `getInitialMessage`.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

/// Implémentation FCM du port [PushMessaging].
///
/// Le backend envoie des messages **hybrides** (`notification` + `data`) :
///  - app en background / tuée → le système affiche la notif, le tap est
///    capté par `onMessageOpenedApp` / `getInitialMessage` ;
///  - app au premier plan (Android n'affiche rien automatiquement) → on
///    affiche nous-mêmes via `flutter_local_notifications`, et le tap sur
///    cette notif locale est réinjecté dans [onMessageOpenedApp] pour que
///    l'orchestrateur le route exactement comme un tap natif.
class FirebasePushMessaging implements PushMessaging {
  FirebasePushMessaging({
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  // Récupéré paresseusement : `FirebaseMessaging.instance` exige que
  // `Firebase.initializeApp` ait déjà tourné.
  FirebaseMessaging get _fm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications;

  /// Unifie les taps natifs (background/killed) et les taps sur les notifs
  /// locales affichées en premier plan.
  final StreamController<Map<String, dynamic>> _opened =
      StreamController<Map<String, dynamic>>.broadcast();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'fotdelsi_default',
    'Notifications',
    description: 'Demandes de paiement et état des dépôts',
    importance: Importance.high,
  );

  @override
  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onLocalTap,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // iOS : afficher la bannière même au premier plan.
    await _fm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Premier plan → afficher une notif locale (nécessaire sur Android).
    FirebaseMessaging.onMessage.listen(_showForeground);

    // Tap natif (app en background) → réinjecté dans le flux unifié.
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _opened.add(m.data));
  }

  void _showForeground(RemoteMessage message) {
    final notification = message.notification;
    _localNotifications.show(
      id: message.hashCode,
      title: notification?.title ?? 'FOT DELSI',
      body: notification?.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(message.data),
    );
  }

  void _onLocalTap(NotificationResponse response) {
    final raw = response.payload;
    if (raw == null || raw.isEmpty) return;
    try {
      final data = (jsonDecode(raw) as Map).cast<String, dynamic>();
      _opened.add(data);
    } catch (e) {
      if (kDebugMode) debugPrint('Payload notif locale illisible: $e');
    }
  }

  @override
  Future<PushPermissionStatus> requestPermission() async {
    final settings = await _fm.requestPermission();
    return switch (settings.authorizationStatus) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional =>
        PushPermissionStatus.granted,
      AuthorizationStatus.denied => PushPermissionStatus.denied,
      AuthorizationStatus.notDetermined => PushPermissionStatus.notDetermined,
    };
  }

  @override
  Future<String?> getToken() => _fm.getToken();

  @override
  Stream<String> get onTokenRefresh => _fm.onTokenRefresh;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage =>
      FirebaseMessaging.onMessage.map((m) => m.data);

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp => _opened.stream;

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async {
    final message = await _fm.getInitialMessage();
    return message?.data;
  }
}
