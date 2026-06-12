import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:fotdelsi/core/websocket/realtime_socket.dart';
import 'package:fotdelsi/core/websocket/ws_connection_status.dart';
import '../models/wash_session_status_model.dart';

/// Source temps réel d'une wash-session, branchée sur la connexion partagée
/// [RealtimeSocket].
///
/// Protocole (côté backend, rooms Socket.IO `session:<token>`) :
///   - `session:subscribe   { token }`  → rejoint la room de la session
///   - `session.status`      (reçu)      → statut combiné poussé par le serveur
///   - `session:unsubscribe  { token }`  → quitte la room
///
/// Le `watchStatus` gère tout le cycle de vie : il acquiert la connexion et
/// souscrit la room au premier `listen`, **re-souscrit automatiquement après
/// chaque reconnexion** (les rooms sont attachées à la connexion socket), et
/// relâche tout au `cancel`.
class WashSessionSocketDataSource {
  WashSessionSocketDataSource(this._socket);

  final RealtimeSocket _socket;

  static const String _subscribeEvent = 'session:subscribe';
  static const String _unsubscribeEvent = 'session:unsubscribe';
  static const String _statusEvent = 'session.status';

  /// Flux de statut pour la session identifiée par [token].
  Stream<WashSessionStatusModel> watchStatus(String token) {
    StreamSubscription<dynamic>? statusSub;
    StreamSubscription<WsConnectionStatus>? connSub;
    late final StreamController<WashSessionStatusModel> controller;

    void subscribeRoom() => _socket.emit(_subscribeEvent, {'token': token});

    controller = StreamController<WashSessionStatusModel>(
      onListen: () {
        _socket.acquire();
        subscribeRoom();

        // Les rooms sont liées à la connexion : on re-souscrit à chaque reconnexion.
        connSub = _socket.connectionStatus.listen((status) {
          if (status == WsConnectionStatus.connected) subscribeRoom();
        });

        statusSub = _socket.on(_statusEvent).listen((data) {
          try {
            controller.add(
              WashSessionStatusModel.fromJson(data as Map<String, dynamic>),
            );
          } catch (e) {
            if (kDebugMode) print('⚠️  session.status parse error: $e');
          }
        });
      },
      onCancel: () async {
        _socket.emit(_unsubscribeEvent, {'token': token});
        await statusSub?.cancel();
        await connSub?.cancel();
        _socket.release();
      },
    );

    return controller.stream;
  }
}
