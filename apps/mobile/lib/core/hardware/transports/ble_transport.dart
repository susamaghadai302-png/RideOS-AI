import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'hardware_transport.dart';

class BleTransport extends HardwareTransport {
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  int _connectionGeneration = 0;

  @override
  Future<void> connect(String deviceId) async {
    final int currentGen = ++_connectionGeneration;
    updateState(HardwareTransportState.connecting);

    try {
      final device = BluetoothDevice.fromId(deviceId);
      
      _connectionStateSubscription?.cancel();
      _connectionStateSubscription = device.connectionState.listen((state) {
        if (_connectionGeneration != currentGen) return;
        if (state == BluetoothConnectionState.connected) {
          updateState(HardwareTransportState.connected);
        } else if (state == BluetoothConnectionState.disconnected) {
          updateState(HardwareTransportState.disconnected);
        }
      });

      await device.connect(timeout: const Duration(seconds: 15), license: License.nonprofit);
      
      if (_connectionGeneration != currentGen) {
        // Disconnect was called while we were awaiting connection
        await device.disconnect();
        return;
      }
      
      updateState(HardwareTransportState.connected);
      updateState(HardwareTransportState.discoveringServices);
      
      final services = await device.discoverServices();
      
      if (_connectionGeneration != currentGen) return;
      
      if (services.isNotEmpty) {
        updateState(HardwareTransportState.ready);
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
      updateState(HardwareTransportState.disconnected);
    } catch (e) {
      updateState(HardwareTransportState.error);
    } finally {
      _connectionStateSubscription?.cancel();
    }
  }

  @override
  Future<void> write(List<int> bytes) async {
    // In a real application, this writes to a specific characteristic.
    // For architecture validation, we throw if no device is connected.
    if (currentState != HardwareTransportState.connected && currentState != HardwareTransportState.ready) {
      throw StateError('Cannot write bytes: BLE device not connected.');
    }
  }
}
