import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:fotdelsi/core/network/api_endpoints.dart';
import 'ws_connection_status.dart';

/// Client Socket.IO partagé — **une seule** connexion temps réel multiplexée
/// pour toute l'application.
///
/// Modèle inspiré des grandes apps temps réel (WhatsApp, Slack, Discord) : un
/// unique tunnel persistant par appareil, dans lequel transitent tous les
/// types d'événements. Chaque feature reste découplée en s'abonnant via [on]
/// (réception) et [emit] (envoi) sans jamais ouvrir sa propre connexion —
/// l'organisation se fait au-dessus du transport, pas en multipliant les sockets.
///
/// La connexion est **comptée par références** : elle s'ouvre au premier
/// [acquire] et se ferme au dernier [release]. La reconnexion est gérée
/// nativement par socket.io ; les abonnés peuvent observer [connectionStatus]
/// pour re-souscrire leurs rooms après une reconnexion.
class RealtimeSocket {
  RealtimeSocket();

  io.Socket? _socket;
  int _refCount = 0;

  final StreamController<WsConnectionStatus> _connectionController =
      StreamController<WsConnectionStatus>.broadcast();

  /// Un controller diffusé par nom d'événement, partagé entre tous les abonnés.
  final Map<String, StreamController<dynamic>> _eventControllers = {};

  /// Flux des changements d'état de la connexion (connecté / reconnexion / déconnecté).
  Stream<WsConnectionStatus> get connectionStatus =>
      _connectionController.stream;

  /// Flux des payloads bruts reçus pour [event]. Le handler socket sous-jacent
  /// est branché paresseusement et re-branché à chaque (re)connexion.
  Stream<dynamic> on(String event) {
    final controller = _eventControllers.putIfAbsent(
      event,
      () => StreamController<dynamic>.broadcast(),
    );
    _socket?.on(event, controller.add);
    return controller.stream;
  }

  /// Émet un événement vers le serveur (no-op si pas encore connecté).
  void emit(String event, [dynamic data]) {
    _socket?.emit(event, data);
  }

  /// Incrémente le compteur de références ; ouvre la connexion si c'est le premier.
  void acquire() {
    _refCount++;
    if (_socket == null) _connect();
  }

  /// Décrémente le compteur ; ferme la connexion quand plus aucun abonné.
  void release() {
    if (_refCount > 0) _refCount--;
    if (_refCount == 0) _disconnect();
  }

  // ── Cycle de vie de la socket ─────────────────────────────────────────────────

  void _connect() {
    final socket = io.io(
      ApiEndpoints.webSocketUrl,
      io.OptionBuilder()
          .setTransports(const ['websocket'])
          .enableReconnection()
          .setReconnectionDelay(1000)
          .build(),
    );
    _socket = socket;

    socket
      ..onConnect((_) {
        if (kDebugMode) print('✅ Socket connecté — id: ${socket.id}');
        _connectionController.add(WsConnectionStatus.connected);
      })
      ..on('reconnect_attempt', (_) {
        if (kDebugMode) print('🔄 Socket reconnexion en cours…');
        _connectionController.add(WsConnectionStatus.reconnecting);
      })
      ..onDisconnect((reason) {
        if (kDebugMode) print('❌ Socket déconnecté: $reason');
        final intentional = reason == 'io client disconnect' ||
            reason == 'io server disconnect';
        _connectionController.add(
          intentional
              ? WsConnectionStatus.disconnected
              : WsConnectionStatus.reconnecting,
        );
      })
      ..onConnectError((error) {
        if (kDebugMode) print('⚠️  Socket connect error: $error');
        _connectionController.add(WsConnectionStatus.reconnecting);
      });

    // (Re)branche les handlers des événements déjà demandés sur cette instance.
    for (final entry in _eventControllers.entries) {
      socket.on(entry.key, entry.value.add);
    }

    socket.connect();
  }

  void _disconnect() {
    _socket?.dispose();
    _socket = null;
    _connectionController.add(WsConnectionStatus.disconnected);
  }

  /// Libère toutes les ressources (à appeler au teardown de l'app uniquement).
  void dispose() {
    _disconnect();
    _connectionController.close();
    for (final c in _eventControllers.values) {
      c.close();
    }
    _eventControllers.clear();
  }
}
