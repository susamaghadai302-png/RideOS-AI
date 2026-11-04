import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  /// Requests all necessary Bluetooth and Location permissions for Android/iOS
  Future<bool> requestBluetoothPermissions() async {
    if (kIsWeb) return true;
    if (Platform.isAndroid) {
      // For Android 12+ (API 31+)
      Map<Permission, PermissionStatus> statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
        Permission.location, // Often required for BLE scanning even on newer versions depending on manufacturer
      ].request();

      bool allGranted = true;
      statuses.forEach((permission, status) {
        if (!status.isGranted) {
          allGranted = false;
        }
      });
      return allGranted;
    } else if (Platform.isIOS) {
      final status = await Permission.bluetooth.request();
      return status.isGranted;
    }
    
    // Other platforms assume true
    return true;
  }

  Future<bool> hasPermissions() async {
    if (kIsWeb) return true;
    if (Platform.isAndroid) {
      final scan = await Permission.bluetoothScan.isGranted;
      final connect = await Permission.bluetoothConnect.isGranted;
      final loc = await Permission.location.isGranted;
      return scan && connect && loc;
    } else if (Platform.isIOS) {
      return await Permission.bluetooth.isGranted;
    }
    return true;
  }
}
