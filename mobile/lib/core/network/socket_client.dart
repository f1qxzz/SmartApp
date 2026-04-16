import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'package:smartlife_app/core/config/env_config.dart';

class SocketClient {
  io.Socket? _socket;

  io.Socket? get socket => _socket;

  void connect({required String token}) {
    if (_socket?.connected == true) {
      return;
    }

    _socket = io.io(
      EnvConfig.socketUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(2000)
          .setAuth({'token': token})
          .build(),
    );

    _socket?.onConnect((_) {
      debugPrint('[SOCKET] Connected to real-time server');
    });

    _socket?.onConnectError((err) {
      debugPrint('[SOCKET] Connection error: $err');
    });
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  Stream<dynamic> on(String event) {
    final controller = StreamController<dynamic>.broadcast();
    void listener(dynamic data) => controller.add(data);
    _socket?.on(event, listener);

    controller.onCancel = () {
      _socket?.off(event, listener);
    };

    return controller.stream;
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }
}
