// ignore_for_file: avoid_web_libraries_in_flutter, uri_does_not_exist, undefined_identifier, undefined_function
import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'web_bluetooth_models.dart';

class WebBluetoothManagerPlatform {
  static final WebBluetoothManagerPlatform _instance = WebBluetoothManagerPlatform._internal();
  factory WebBluetoothManagerPlatform() => _instance;

  final StreamController<String> _disconnectedController = StreamController<String>.broadcast();
  Stream<String> get onDeviceDisconnected => _disconnectedController.stream;

  WebBluetoothManagerPlatform._internal() {
    html.window.addEventListener('rideos_ble_disconnected', (event) {
      if (event is html.CustomEvent && event.detail != null) {
        try {
          final detail = event.detail;
          final devId = js_util.getProperty(detail, 'deviceId')?.toString() ?? '';
          if (devId.isNotEmpty) {
            _disconnectedController.add(devId);
          }
        } catch (_) {}
      }
    });
  }

  dynamic _getBridge() {
    try {
      if (js_util.hasProperty(html.window, 'RideOSWebBluetooth')) {
        return js_util.getProperty(html.window, 'RideOSWebBluetooth');
      }
    } catch (_) {}
    return null;
  }

  Future<WebBleSupportInfo> checkSupport() async {
    try {
      final bridge = _getBridge();
      if (bridge == null) {
        return WebBleSupportInfo.unsupported(
          'RideOS Web Bluetooth bridge script not loaded. Check index.html.',
        );
      }
      final rawStr = js_util.callMethod(bridge, 'checkSupport', [])?.toString() ?? '{}';
      final map = jsonDecode(rawStr) as Map<String, dynamic>;
      return WebBleSupportInfo.fromJson(map);
    } catch (e) {
      return WebBleSupportInfo.unsupported(e.toString());
    }
  }

  Future<bool> isBluetoothAvailable() async {
    try {
      final bridge = _getBridge();
      if (bridge == null) return false;
      final promise = js_util.callMethod(bridge, 'getAvailability', []);
      if (promise == null) return false;
      final rawStr = await js_util.promiseToFuture<dynamic>(promise);
      final map = jsonDecode(rawStr.toString()) as Map<String, dynamic>;
      return map['available'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<WebBleRequestResult> requestDevice({String? optionsJson}) async {
    try {
      final bridge = _getBridge();
      if (bridge == null) {
        return const WebBleRequestResult(
          success: false,
          error: 'Web Bluetooth bridge not initialized in browser window.',
        );
      }
      final args = optionsJson != null ? [optionsJson] : <dynamic>[];
      final promise = js_util.callMethod(bridge, 'requestDevice', args);
      if (promise == null) {
        return const WebBleRequestResult(
          success: false,
          error: 'requestDevice returned null instead of a Promise.',
        );
      }
      final rawStr = await js_util.promiseToFuture<dynamic>(promise);
      final map = jsonDecode(rawStr.toString()) as Map<String, dynamic>;
      return WebBleRequestResult.fromJson(map);
    } catch (e) {
      final str = e.toString();
      final isCancel = str.contains('cancelled') || str.contains('User cancelled') || str.contains('NotFoundError');
      return WebBleRequestResult(
        success: false,
        cancelled: isCancel,
        error: isCancel ? 'Bluetooth selection cancelled.' : str,
      );
    }
  }

  Future<WebBleGattResult> connectGatt(String deviceId) async {
    try {
      final bridge = _getBridge();
      if (bridge == null) {
        return const WebBleGattResult(
          success: false,
          error: 'Web Bluetooth bridge not initialized.',
        );
      }
      final promise = js_util.callMethod(bridge, 'connectGatt', [deviceId]);
      if (promise == null) {
        return const WebBleGattResult(
          success: false,
          error: 'connectGatt returned null instead of a Promise.',
        );
      }
      final rawStr = await js_util.promiseToFuture<dynamic>(promise);
      final map = jsonDecode(rawStr.toString()) as Map<String, dynamic>;
      return WebBleGattResult.fromJson(map);
    } catch (e) {
      return WebBleGattResult(success: false, error: e.toString());
    }
  }

  Future<bool> disconnect(String deviceId) async {
    try {
      final bridge = _getBridge();
      if (bridge == null) return true;
      final promise = js_util.callMethod(bridge, 'disconnect', [deviceId]);
      if (promise == null) return true;
      final rawStr = await js_util.promiseToFuture<dynamic>(promise);
      final map = jsonDecode(rawStr.toString()) as Map<String, dynamic>;
      return map['success'] == true;
    } catch (_) {
      return false;
    }
  }
}
