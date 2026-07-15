import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'connectivity_status.dart';

/// Suit la connectivité réseau de l'appareil (interface wifi/mobile présente).
///
/// Deux usages :
///  - afficher un bandeau « hors ligne » global (façon Wave) ;
///  - distinguer une vraie absence de connexion d'une simple reconnexion socket
///    — sinon la pastille WebSocket affiche « Reconnexion… » à l'infini quand il
///    n'y a pas d'internet.
///
/// Note : `connectivity_plus` détecte la présence d'une interface réseau, pas la
/// joignabilité réelle d'Internet (wifi sans accès). Le cas courant (avion,
/// aucun réseau) est couvert ; le cas « wifi sans internet » reste géré par le
/// statut socket (reconnexion).
class ConnectivityCubit extends Cubit<ConnectivityStatus> {
  ConnectivityCubit(this._connectivity) : super(ConnectivityStatus.online) {
    _init();
  }

  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  Future<void> _init() async {
    try {
      _apply(await _connectivity.checkConnectivity());
    } catch (_) {
      // Échec de la vérification initiale → on suppose « en ligne » pour ne pas
      // afficher un faux bandeau au démarrage.
      emit(ConnectivityStatus.online);
    }
    _sub = _connectivity.onConnectivityChanged.listen(_apply);
  }

  void _apply(List<ConnectivityResult> results) {
    final offline =
        results.isEmpty || results.every((r) => r == ConnectivityResult.none);
    emit(offline ? ConnectivityStatus.offline : ConnectivityStatus.online);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
