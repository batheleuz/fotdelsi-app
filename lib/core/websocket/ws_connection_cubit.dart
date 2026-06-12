import 'package:bloc/bloc.dart';

import 'ws_connection_status.dart';

/// Cubit global qui expose l'état de la connexion WebSocket.
///
/// Instancié en singleton dans le service locator et fourni au-dessus du
/// router dans `main.dart` pour être accessible depuis n'importe quelle page.
/// Mis à jour uniquement par [MachinesBloc] qui suit les événements socket.
class WsConnectionCubit extends Cubit<WsConnectionStatus> {
  WsConnectionCubit() : super(WsConnectionStatus.disconnected);

  void setConnected() {
    if (state != WsConnectionStatus.connected) {
      emit(WsConnectionStatus.connected);
    }
  }

  void setReconnecting() {
    if (state != WsConnectionStatus.reconnecting) {
      emit(WsConnectionStatus.reconnecting);
    }
  }

  void setDisconnected() {
    if (state != WsConnectionStatus.disconnected) {
      emit(WsConnectionStatus.disconnected);
    }
  }
}
