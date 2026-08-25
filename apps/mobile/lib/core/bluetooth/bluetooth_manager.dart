import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothManager {
  static final BluetoothManager _instance = BluetoothManager._internal();
  factory BluetoothManager() => _instance;
  BluetoothManager._internal();

  BluetoothDevice? connectedDevice;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  /// Ensures adapter is ON and starts scanning
  Future<void> startScan({List<Guid> withServices = const [], Duration timeout = const Duration(seconds: 15)}) async {
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception('Bluetooth not supported on this device');
    }

    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      throw Exception('Bluetooth adapter is off');
    }

    await FlutterBluePlus.startScan(
      withServices: withServices,
      timeout: timeout,
    );
  }

  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    await stopScan();
    try {
      await device.connect(autoConnect: false, timeout: const Duration(seconds: 15), license: License.nonprofit);
      connectedDevice = device;
    } catch (e) {
      throw Exception('Failed to connect to device: $e');
    }
  }

  Future<List<BluetoothService>> discoverServices() async {
    if (connectedDevice == null) throw Exception('No device connected');
    return await connectedDevice!.discoverServices();
  }

  Future<void> disconnect() async {
    if (connectedDevice != null) {
      try {
        await connectedDevice!.disconnect();
      } catch (_) {}
      connectedDevice = null;
    }
  }
}
