import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:fotdelsi/core/network/api_endpoints.dart';
import '../../domain/entities/machine.dart';
import '../models/machine_model.dart';
import 'machine_realtime_data_source.dart';

/// Source temps réel branchée sur le WebSocket socket.io du backend.
///
/// Écoute l'événement `machines:update` et émet la liste mise à jour.
/// La connexion s'ouvre au premier `listen` et se ferme au dernier `cancel`.
/// La reconnexion automatique est gérée nativement par socket.io.
class MachineSocketDataSource implements MachineRealtimeDataSource {
  MachineSocketDataSource();

  static const String _eventMachinesUpdate = 'machine.state';

  io.Socket? _socket;
  StreamController<List<Machine>>? _controller;

  @override
  Stream<List<Machine>> watchMachines() {
    _controller ??= StreamController<List<Machine>>.broadcast(
      onListen: _connect,
      onCancel: _disconnect,
    );
    return _controller!.stream;
  }

  void _connect() {
    _socket = io.io(
      ApiEndpoints.webSocketUrl,
      io.OptionBuilder()
          .setTransports(const ['websocket'])
          .enableReconnection()
          .setReconnectionDelay(1000)
          .build(),
    );

    _socket!
      ..on(_eventMachinesUpdate, _onMachinesUpdate)
      ..onConnectError((error) {
        if (kDebugMode) print("On Socket Error => $error");
        _controller?.addError(StateError('Connexion WebSocket impossible.'));
      })
      ..onError((error) {
        _controller?.addError(StateError('Erreur WebSocket.'));
      })
      ..connect()
      ..onConnect((_) {
        if (kDebugMode) {
          print('✅ Socket connecté');
          print('Socket ID: ${_socket!.id}');
        }
      })
      ..onDisconnect((reason) {
        if (kDebugMode) {
          print('❌ Socket déconnecté: $reason');
        }
      });
  }

  void _onMachinesUpdate(dynamic data) {
    try {
      final list = MachineModel.fromJson(data as Map<String, dynamic>).toEntity();
      _controller?.add([list]);
    } catch (e) {
      _controller?.addError(e);
    }
  }

  void _disconnect() {
    _socket?.dispose();
    _socket = null;
  }

  @override
  void dispose() {
    _disconnect();
    _controller?.close();
    _controller = null;
  }
}
