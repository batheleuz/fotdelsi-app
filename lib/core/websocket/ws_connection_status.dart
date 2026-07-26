/// États possibles de la connexion WebSocket.
enum WsConnectionStatus {
  /// Connecté et flux actif.
  connected,

  /// Déconnecté — tentative de reconnexion en cours.
  reconnecting,

  /// Déconnecté sans tentative active.
  disconnected,
}
