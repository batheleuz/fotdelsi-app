import 'dart:async';

import 'package:fotdelsi/core/auth/auth_token_store.dart';
import 'package:fotdelsi/core/websocket/realtime_socket.dart';
import 'package:fotdelsi/core/websocket/ws_connection_status.dart';

/// Source temps réel de la file d'attente agent, branchée sur la connexion
/// partagée [RealtimeSocket].
///
/// Protocole (room Socket.IO `agents`, gardée par JWT côté backend) :
///   - `agents:subscribe   { token }`  → rejoint la room (token = access token agent)
///   - `dropoffs:changed`   (reçu)      → un dépôt a changé (nudge → recharger la file)
///   - `agents:unsubscribe`             → quitte la room
///
/// [watchQueueChanges] émet un signal (`void`) à chaque nudge. Il gère tout le
/// cycle de vie : acquiert la connexion et souscrit la room au premier `listen`,
/// **re-souscrit après chaque reconnexion** (les rooms sont liées à la
/// connexion), et **émet aussi un nudge à la (re)connexion** pour rattraper les
/// événements manqués pendant une coupure. Relâche tout au `cancel`.
class AgentQueueRealtimeDataSource {
  AgentQueueRealtimeDataSource(this._socket, this._tokenStore);

  final RealtimeSocket _socket;
  final AuthTokenStore _tokenStore;

  static const String _subscribeEvent = 'agents:subscribe';
  static const String _unsubscribeEvent = 'agents:unsubscribe';
  static const String _changedEvent = 'dropoffs:changed';

  /// Flux de "nudges" : un événement par changement de file (+ un à chaque
  /// (re)connexion pour resynchroniser).
  Stream<void> watchQueueChanges() {
    StreamSubscription<dynamic>? changedSub;
    StreamSubscription<WsConnectionStatus>? connSub;
    late final StreamController<void> controller;

    Future<void> subscribeRoom() async {
      final token = await _tokenStore.accessToken();
      if (token != null) _socket.emit(_subscribeEvent, {'token': token});
    }

    controller = StreamController<void>(
      onListen: () {
        _socket.acquire();
        subscribeRoom();

        // Les rooms sont liées à la connexion : on re-souscrit à chaque
        // reconnexion, et on pousse un nudge pour rattraper d'éventuels
        // changements survenus pendant la coupure.
        connSub = _socket.connectionStatus.listen((status) {
          if (status == WsConnectionStatus.connected) {
            subscribeRoom();
            controller.add(null);
          }
        });

        changedSub = _socket.on(_changedEvent).listen((_) {
          controller.add(null);
        });
      },
      onCancel: () async {
        _socket.emit(_unsubscribeEvent);
        await changedSub?.cancel();
        await connSub?.cancel();
        _socket.release();
      },
    );

    return controller.stream;
  }
}
