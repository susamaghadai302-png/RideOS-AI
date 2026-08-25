import 'dart:async';
import 'web_bluetooth_models.dart';

class WebBluetoothManagerPlatform {
  static final WebBluetoothManagerPlatform _instance = WebBluetoothManagerPlatform._internal();
  factory WebBluetoothManagerPlatform() => _instance;
  WebBluetoothManagerPlatform._internal();

  final StreamController<String> _disconnectedController = StreamController<String>.broadcast();
  Stream<String> get onDeviceDisconnected => _disconnectedController.stream;

  Future<WebBleSupportInfo> checkSupport() async {
    return WebBleSupportInfo.unsupported(
      'Web Bluetooth is only active in web environments on macOS/Windows/Android Chromium browsers.',
    );
  }

  Future<bool> isBluetoothAvailable() async {
    return false;
  }

  Future<WebBleRequestResult> requestDevice({String? optionsJson}) async {
    return const WebBleRequestResult(
      success: false,
      error: 'Web Bluetooth API is not applicable in native execution.',
    );
  }

  Future<WebBleGattResult> connectGatt(String deviceId) async {
    return const WebBleGattResult(
      success: false,
      error: 'GATT connection is only available on Web.',
    );
  }

  Future<bool> disconnect(String deviceId) async {
    return true;
  }
}
