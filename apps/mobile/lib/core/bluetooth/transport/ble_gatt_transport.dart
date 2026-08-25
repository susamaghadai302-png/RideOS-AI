import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'vehicle_transport.dart';

class BleGattTransport implements VehicleTransport {
  final StreamController<List<int>> _dataController = StreamController.broadcast();
  final StreamController<TransportState> _stateController = StreamController.broadcast();
  
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;

  @override
  TransportType get type => TransportType.bleGatt;

  @override
  Future<bool> isSupported() async {
    return await FlutterBluePlus.isSupported;
  }

  @override
  Future<bool> isEnabled() async {
    final state = await FlutterBluePlus.adapterState.first;
    return state == BluetoothAdapterState.on;
  }

  @override
  Future<void> connect(String deviceIdentifier, {Duration timeout = const Duration(seconds: 15)}) async {
    _stateController.add(TransportState.connecting);
    try {
      final device = BluetoothDevice.fromId(deviceIdentifier);
      _connectedDevice = device;

      _connSub?.cancel();
      _connSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          _stateController.add(TransportState.connected);
        } else if (state == BluetoothConnectionState.disconnected) {
          _stateController.add(TransportState.disconnected);
        }
      });

      await device.connect(autoConnect: false, timeout: timeout, license: License.nonprofit);
      _stateController.add(TransportState.connected);
    } catch (e) {
      _stateController.add(TransportState.error);
      rethrow;
    }
  }

  /// Sets up active characteristic subscription
  Future<void> setupCharacteristics({
    required BluetoothCharacteristic writeCharacteristic,
    required BluetoothCharacteristic notifyCharacteristic,
  }) async {
    _writeChar = writeCharacteristic;
    _notifyChar = notifyCharacteristic;

    await _notifyChar!.setNotifyValue(true);
    _notifyChar!.lastValueStream.listen((bytes) {
      if (bytes.isNotEmpty) {
        _dataController.add(bytes);
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _stateController.add(TransportState.disconnecting);
    if (_connectedDevice != null) {
      try {
        await _connectedDevice!.disconnect();
      } catch (_) {}
      _connectedDevice = null;
    }
    _stateController.add(TransportState.disconnected);
  }

  @override
  Future<void> send(List<int> data) async {
    if (_writeChar == null) {
      throw StateError('Write characteristic is not configured for BleGattTransport');
    }
    await _writeChar!.write(data, withoutResponse: false);
  }

  @override
  Stream<List<int>> get dataStream => _dataController.stream;

  @override
  Stream<TransportState> get stateStream => _stateController.stream;

  @override
  void dispose() {
    _connSub?.cancel();
    _dataController.close();
    _stateController.close();
  }
}
