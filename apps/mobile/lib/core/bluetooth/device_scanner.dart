import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'permission_manager.dart';

class DeviceScanner {
  static final DeviceScanner _instance = DeviceScanner._internal();
  factory DeviceScanner() => _instance;
  DeviceScanner._internal();

  /// Starts a BLE scan for 15 seconds. Returns stream of sorted results.
  Future<Stream<List<ScanResult>>> startScan() async {
    final hasPerms = await PermissionManager().requestBluetoothPermissions();
    if (!hasPerms) {
      throw Exception('Bluetooth or Location permissions denied.');
    }

    if (await FlutterBluePlus.isSupported == false) {
      throw Exception('Bluetooth not supported on this device');
    }

    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      throw Exception('Bluetooth adapter is off');
    }

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    // Map the stream to sort by RSSI (closest devices first)
    return FlutterBluePlus.scanResults.map((results) {
      final sorted = List<ScanResult>.from(results);
      sorted.sort((a, b) => b.rssi.compareTo(a.rssi));
      return sorted;
    });
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }
}
