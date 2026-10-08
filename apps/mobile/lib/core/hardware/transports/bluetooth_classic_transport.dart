import 'dart:async';
import 'package:flutter/services.dart';
import 'hardware_transport.dart';

class BluetoothClassicTransport extends HardwareTransport {
  // Using MethodChannel/EventChannel pattern as typical for BT Classic RFCOMM
  static const MethodChannel _channel = MethodChannel('bluetooth_classic/methods');
  static const EventChannel _stateChannel = EventChannel('bluetooth_classic/state');
  
  StreamSubscription? _stateSubscription;

  int _connectionGeneration = 0;

  @override
  Future<void> connect(String deviceId) async {
    final int currentGen = ++_connectionGeneration;
    updateState(HardwareTransportState.connecting);

    try {
      _stateSubscription?.cancel();
      _stateSubscription = _stateChannel.receiveBroadcastStream().listen((dynamic state) {
        if (_connectionGeneration != currentGen) return;
        if (state == 'CONNECTED') {
          updateState(HardwareTransportState.connected);
          updateState(HardwareTransportState.ready);
        } else if (state == 'DISCONNECTED') {
          updateState(HardwareTransportState.disconnected);
        } else if (state == 'ERROR') {
          updateState(HardwareTransportState.error);
        }
      });

      final bool success = await _channel.invokeMethod('connect', {'address': deviceId});
      
      if (_connectionGeneration != currentGen) {
        await _channel.invokeMethod('disconnect');
        return;
      }
      
      if (!success) {
        throw StateError('RFCOMM connection failed');
      }
    } catch (e) {
      if (_connectionGeneration == currentGen) {
        updateState(HardwareTransportState.error);
      }
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _connectionGeneration++;
    updateState(HardwareTransportState.disconnecting);
    try {
      await _channel.invokeMethod('disconnect');
      updateState(HardwareTransportState.disconnected);
    } catch (e) {
      updateState(HardwareTransportState.error);
    } finally {
      _stateSubscription?.cancel();
    }
  }

  @override
  Future<void> write(List<int> bytes) async {
    if (currentState != HardwareTransportState.connected && currentState != HardwareTransportState.ready) {
      throw StateError('Cannot write bytes: Bluetooth Classic device not connected.');
    }
    // Physical hardware implementation
    final bool success = await _channel.invokeMethod('write', {'bytes': bytes}) ?? false;
    if (!success) {
      throw StateError('Bluetooth Classic RFCOMM write failed.');
    }
  }
}
