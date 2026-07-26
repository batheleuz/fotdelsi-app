import 'dart:async';

import 'package:fotdelsi/core/auth/auth_token_store.dart';
import 'package:fotdelsi/core/websocket/realtime_socket.dart';
import 'package:fotdelsi/core/websocket/ws_connection_status.dart';

/// Changement poussé par le backend sur un dépôt (nudge minimal).
///
/// Le backend n'envoie que l'essentiel : c'est un signal, pas un état. Les
/// écrans rechargent ensuite via HTTP — le backend reste seul maître des
/// données (regroupement de la file, détail complet…).
class AgentDropOffChange {
  const AgentDropOffChange({
    required this.event,
    required this.dropOffId,
    required this.code,
  });

  /// `registered` | `started` | `wash_completed` | `dry_completed` |
  /// `ready` | `collected`
  final String event;
  final String dropOffId;
  final String code;

  static AgentDropOffChange? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['dropOffId'];
    if (id is! String) return null;
    return AgentDropOffChange(
      event: raw['event'] as String? ?? '',
      dropOffId: id,
      code: raw['code'] as String? ?? '',
    );
  }
}

/// Source temps réel des dépôts côté agent, branchée sur la connexion partagée
/// [RealtimeSocket]. Alimente la file d'attente **et** l'écran de détail.
///
/// Protocole (room Socket.IO `agents`, gardée par JWT côté backend) :
///   - `agents:subscribe   { token }`  → rejoint la room (token = access token agent)
///   - `dropoffs:changed`   (reçu)      → un dépôt a changé (nudge → recharger)
///   - `agents:unsubscribe`             → quitte la room
///
/// [watchChanges] gère tout le cycle de vie : acquiert la connexion et souscrit
/// la room au premier `listen`, **re-souscrit après chaque reconnexion** (les
/// rooms sont liées à la connexion), et **émet `null` à la (re)connexion** —
/// signal de resynchronisation pour rattraper les événements manqués pendant la
/// coupure. Relâche tout au `cancel`.
class AgentRealtimeDataSource {
  AgentRealtimeDataSource(this._socket, this._tokenStore);

  final RealtimeSocket _socket;
  final AuthTokenStore _tokenStore;

  static const String _subscribeEvent = 'agents:subscribe';
  static const String _unsubscribeEvent = 'agents:unsubscribe';
  static const String _changedEvent = 'dropoffs:changed';

  /// Flux de changements. `null` = resynchronisation (re)connexion.
  Stream<AgentDropOffChange?> watchChanges() {
    StreamSubscription<dynamic>? changedSub;
    StreamSubscription<WsConnectionStatus>? connSub;
    late final StreamController<AgentDropOffChange?> controller;

    Future<void> subscribeRoom() async {
      final token = await _tokenStore.accessToken();
      if (token != null) _socket.emit(_subscribeEvent, {'token': token});
    }

    controller = StreamController<AgentDropOffChange?>(
      onListen: () {
        _socket.acquire();
        subscribeRoom();

        connSub = _socket.connectionStatus.listen((status) {
          if (status == WsConnectionStatus.connected) {
            subscribeRoom();
            controller.add(null); // resync
          }
        });

        changedSub = _socket
            .on(_changedEvent)
            .listen((raw) => controller.add(AgentDropOffChange.tryParse(raw)));
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
