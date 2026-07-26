/// Statut de la permission notifications.
enum PushPermissionStatus { granted, denied, notDetermined }

/// Port d'abstraction du service de messagerie push.
///
/// Indépendant de Firebase : l'implémentation concrète (FCM) sera branchée
/// une fois le projet Firebase configuré. Les messages sont exposés sous forme
/// de `Map<String, dynamic>` (le champ `data` brut) ; la conversion en
/// `NotificationPayload` se fait dans le service orchestrateur.
abstract interface class PushMessaging {
  /// Met en place le canal de notifications, l'affichage en premier plan et
  /// les écouteurs natifs. À appeler une fois au démarrage (après
  /// `Firebase.initializeApp`). No-op pour l'implémentation neutre.
  Future<void> initialize();

  /// Demande la permission (iOS, Android 13+).
  Future<PushPermissionStatus> requestPermission();

  /// Jeton FCM courant (null si indisponible / non configuré).
  Future<String?> getToken();

  /// Émet à chaque rotation du jeton FCM.
  Stream<String> get onTokenRefresh;

  /// Message reçu app au premier plan (`data`).
  Stream<Map<String, dynamic>> get onForegroundMessage;

  /// Message tapé alors que l'app est en arrière-plan (`data`).
  Stream<Map<String, dynamic>> get onMessageOpenedApp;

  /// Message ayant ouvert l'app depuis un état tué (`data`), s'il y en a un.
  Future<Map<String, dynamic>?> getInitialMessage();
}
