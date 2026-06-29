import 'push_messaging.dart';

/// Implémentation neutre de [PushMessaging], utilisée tant que Firebase n'est
/// pas configuré. Ne fait rien et n'émet rien — l'app compile et tourne, la
/// plomberie (enregistrement device, ack, deep-links) est prête à recevoir la
/// vraie implémentation FCM.
class NoopPushMessaging implements PushMessaging {
  const NoopPushMessaging();

  @override
  Future<void> initialize() async {}

  @override
  Future<PushPermissionStatus> requestPermission() async =>
      PushPermissionStatus.notDetermined;

  @override
  Future<String?> getToken() async => null;

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage => const Stream.empty();

  @override
  Stream<Map<String, dynamic>> get onMessageOpenedApp => const Stream.empty();

  @override
  Future<Map<String, dynamic>?> getInitialMessage() async => null;
}
