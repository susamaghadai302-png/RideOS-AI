import 'dart:async';
import 'web_bluetooth_models.dart';

import 'web_bluetooth_manager_stub.dart'
    if (dart.library.html) 'web_bluetooth_manager_web.dart';

/// Central Web Bluetooth Controller for RideOS-AI.
/// Exposes navigator.bluetooth capabilities on macOS Chrome / Edge / Android browsers.
class WebBluetoothManager {
  static final WebBluetoothManager _instance = WebBluetoothManager._internal();
  factory WebBluetoothManager() => _instance;
  WebBluetoothManager._internal();

  final WebBluetoothManagerPlatform _platform = WebBluetoothManagerPlatform();

  Stream<String> get onDeviceDisconnected => _platform.onDeviceDisconnected;

  /// Check whether browser supports Web Bluetooth in the current secure context
  Future<WebBleSupportInfo> checkSupport() => _platform.checkSupport();

  /// Check whether Bluetooth radio is available and enabled
  Future<bool> isBluetoothAvailable() => _platform.isBluetoothAvailable();

  /// Trigger native browser Bluetooth device chooser modal
  Future<WebBleRequestResult> requestDevice({String? optionsJson}) =>
      _platform.requestDevice(optionsJson: optionsJson);

  /// Establish GATT connection and query primary services & characteristics
  Future<WebBleGattResult> connectGatt(String deviceId) =>
      _platform.connectGatt(deviceId);

  /// Disconnect GATT connection
  Future<bool> disconnect(String deviceId) => _platform.disconnect(deviceId);
}
