import 'dart:async';

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
          .setAuth({'token': token})
          .build(),
    );
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  Stream<dynamic> on(String event) {
    final controller = StreamController<dynamic>.broadcast();
    _socket?.on(event, controller.add);

    controller.onCancel = () {
      _socket?.off(event, controller.add);
    };

    return controller.stream;
  }

  void emit(String event, dynamic data) {
    _socket?.emit(event, data);
  }
}
