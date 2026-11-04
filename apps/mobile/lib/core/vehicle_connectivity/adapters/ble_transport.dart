import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import 'dart:io';
import 'uart_transport.dart';

class BleTransport implements UartTransport {
  BluetoothDevice? _device;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription? _notifySubscription;
  final StreamController<String> _dataController = StreamController<String>.broadcast();
  @override
  Stream<String> get dataStream => _dataController.stream;

  @override
  Future<bool> connect(String macAddress) async {
    if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
      return false; // Skip real BLE in unit tests to avoid unhandled unsupported platform errors from flutter_blue_plus
    }
    try {
      _device = BluetoothDevice.fromId(macAddress);
      await _device!.connect(license: License.nonprofit);
      final services = await _device!.discoverServices();
      for (final service in services) {
        for (final c in service.characteristics) {
          if (c.properties.write || c.properties.writeWithoutResponse) {
            _writeCharacteristic = c;
          }
          if (c.properties.notify || c.properties.indicate) {
            _notifyCharacteristic = c;
          }
        }
      }
      if (_writeCharacteristic == null || _notifyCharacteristic == null) {
        await disconnect();
        return false;
      }
      await _notifyCharacteristic!.setNotifyValue(true);
      _notifySubscription = _notifyCharacteristic!.onValueReceived.listen((value) {
        _dataController.add(utf8.decode(value));
      });
      return true;
    } catch (e) {
      await disconnect();
      return false;
    }
  }

  @override
  Future<bool> write(String data) async {
    if (_writeCharacteristic != null) {
      try {
        await _writeCharacteristic!.write(utf8.encode(data));
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  @override
  Future<void> disconnect() async {
    try {
      await _notifySubscription?.cancel();
      _notifySubscription = null;
      await _device?.disconnect();
    } catch (e) {
      // Ignore unsupported platform errors during disconnect
    } finally {
      _device = null;
    }
  }
}
