import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class ConnectionManager {
  static final ConnectionManager _instance = ConnectionManager._internal();
  factory ConnectionManager() => _instance;
  ConnectionManager._internal();

  BluetoothDevice? connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  int _retryCount = 0;
  static const int maxRetries = 3;
  bool _isReconnecting = false;

  final StreamController<BluetoothConnectionState> stateStream = StreamController.broadcast();

  Future<void> connect(BluetoothDevice device, {Duration timeout = const Duration(seconds: 15)}) async {
    try {
      _retryCount = 0;
      await device.connect(autoConnect: false, timeout: timeout, license: License.nonprofit);
      connectedDevice = device;
      
      _connectionSub?.cancel();
      _connectionSub = device.connectionState.listen((state) {
        stateStream.add(state);
        if (state == BluetoothConnectionState.disconnected && !_isReconnecting) {
          _handleAutoReconnect(device);
        }
      });
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  Future<void> _handleAutoReconnect(BluetoothDevice device) async {
    if (_retryCount >= maxRetries) {
      _isReconnecting = false;
      return;
    }

    _isReconnecting = true;
    _retryCount++;
    final backoffSeconds = (1 << _retryCount); // 2s, 4s, 8s

    await Future.delayed(Duration(seconds: backoffSeconds));
    try {
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 10), license: License.nonprofit);
      _isReconnecting = false;
      _retryCount = 0;
    } catch (_) {
      _handleAutoReconnect(device);
    }
  }

  Future<void> disconnect() async {
    _isReconnecting = false;
    _connectionSub?.cancel();
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
      } catch (_) {}
      connectedDevice = null;
    }
  }

  void dispose() {
    _connectionSub?.cancel();
    stateStream.close();
  }
}
