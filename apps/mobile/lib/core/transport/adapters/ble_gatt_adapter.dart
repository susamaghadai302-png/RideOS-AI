import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/transport_types.dart';
import '../models/transport_device.dart';
import 'transport_adapter.dart';

class BleGattTransportAdapter implements TransportAdapter {
  BleGattTransportAdapter({
    BleGattConfiguration? configuration,
  }) : _config = configuration ?? BleGattConfiguration.obdStandard;

  final BleGattConfiguration _config;

  TransportState _state = TransportState.disconnected;
  TransportConnection? _activeConnection;
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeChar;
  BluetoothCharacteristic? _notifyChar;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothConnectionState>? _connSub;
  StreamSubscription<List<int>>? _charSub;

  final _stateController = StreamController<TransportState>.broadcast();
  final _discoveryController = StreamController<TransportDevice>.broadcast();
  final _dataController = StreamController<TransportPacket>.broadcast();

  final List<TransportDevice> _discoveredDevices = [];

  @override
  TransportType get transportType => TransportType.bluetoothLowEnergy;

  @override
  TransportState get currentState => _state;

  @override
  Stream<TransportState> get stateStream => _stateController.stream;

  @override
  Stream<TransportDevice> get discoveryStream => _discoveryController.stream;

  @override
  Stream<TransportPacket> get dataStream => _dataController.stream;

  @override
  TransportConnection? get activeConnection => _activeConnection;

  void _transition(TransportState next) {
    if (_state == next) return;
    if (!_state.canTransitionTo(next)) {
      debugPrint('[BLE] Invalid state transition: $_state → $next');
      return;
    }
    _state = next;
    _stateController.add(next);
  }

  @override
  Future<TransportCapabilities> getCapabilities() async {
    final isSupported = await FlutterBluePlus.isSupported;
    return TransportCapabilities(
      transportType: TransportType.bluetoothLowEnergy,
      isAvailableOnPlatform: isSupported,
      isAdapterEnabled: FlutterBluePlus.adapterStateNow == BluetoothAdapterState.on,
      hasPermission: true, // Will check via permission_handler
      maxPayloadBytes: _config.mtuSize,
      supportsReconnection: true,
      supportsSubscription: true,
      supportsBidirectional: true,
    );
  }

  @override
  Future<TransportPermissionState> checkPermission() async {
    return TransportPermissionState.granted;
  }

  @override
  Future<TransportPermissionState> requestPermission() async {
    return TransportPermissionState.granted;
  }

  @override
  Future<void> startDiscovery({
    Duration timeout = const Duration(seconds: 10),
    List<String>? serviceFilter,
  }) async {
    if (_state.isActive) return;
    _transition(TransportState.initializing);
    _discoveredDevices.clear();
    
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();

    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        if (r.device.advName.isEmpty) continue;
        final d = TransportDevice(
          deviceId: r.device.remoteId.str,
          displayName: r.device.advName,
          address: r.device.remoteId.str,
          lastSeen: DateTime.now(),
          transportType: TransportType.bluetoothLowEnergy,
        );
        if (!_discoveredDevices.any((x) => x.deviceId == d.deviceId)) {
          _discoveredDevices.add(d);
          _discoveryController.add(d);
        }
      }
    });

    _transition(TransportState.scanning);
    
    final uuids = serviceFilter?.map((e) => Guid(e)).toList() ?? 
        (_config.serviceUuid != null ? [Guid(_config.serviceUuid!)] : []);

    try {
      await FlutterBluePlus.startScan(
        withServices: uuids,
        timeout: timeout,
      );
    } catch (e) {
      _transition(TransportState.error);
    }
    
    Future.delayed(timeout, () {
      if (_state == TransportState.scanning) {
        _transition(TransportState.disconnected);
      }
    });
  }

  @override
  Future<void> stopDiscovery() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    if (_state == TransportState.scanning) {
      _transition(TransportState.disconnected);
    }
  }

  @override
  Future<TransportConnection> connect(
    TransportDevice device, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_state.isActive) await disconnect();
    _transition(TransportState.connecting);

    try {
      await FlutterBluePlus.stopScan();
      _connectedDevice = BluetoothDevice.fromId(device.deviceId);
      
      await _connectedDevice!.connect(
        timeout: timeout,
        autoConnect: false,
        license: License.nonprofit,
      );

      _connSub = _connectedDevice!.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _cleanupConnection();
          _transition(TransportState.disconnected);
        }
      });

      final services = await _connectedDevice!.discoverServices();
      for (final s in services) {
        if (_config.serviceUuid == null || s.uuid.str.toUpperCase() == _config.serviceUuid!.toUpperCase()) {
          for (final c in s.characteristics) {
            if (c.properties.write || c.properties.writeWithoutResponse) {
              _writeChar = c;
            }
            if (c.properties.notify || c.properties.indicate) {
              _notifyChar = c;
            }
          }
        }
      }

      if (_notifyChar != null) {
        await _notifyChar!.setNotifyValue(true);
        _charSub = _notifyChar!.onValueReceived.listen((value) {
          _dataController.add(TransportPacket(
            timestamp: DateTime.now(),
            payload: value,
            sourceTransport: TransportType.bluetoothLowEnergy,
          ));
        });
      }
      
      try {
        await _connectedDevice!.requestMtu(_config.mtuSize);
      } catch (_) {}

      _activeConnection = TransportConnection(
        connectionId: device.deviceId,
        device: device,
        state: TransportState.ready,
        capabilities: await getCapabilities(),
        connectedAt: DateTime.now(),
      );
      
      _transition(TransportState.ready);
      return _activeConnection!;
    } catch (e) {
      _cleanupConnection();
      _transition(TransportState.error);
      throw TransportError(
        code: TransportErrorCode.unknown,
        transportType: TransportType.bluetoothLowEnergy,
        details: e.toString(),
      );
    }
  }

  void _cleanupConnection() {
    _charSub?.cancel();
    _connSub?.cancel();
    _writeChar = null;
    _notifyChar = null;
    _activeConnection = null;
    _connectedDevice = null;
  }

  @override
  Future<void> disconnect() async {
    _transition(TransportState.disconnecting);
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } catch (_) {}
    _cleanupConnection();
    _transition(TransportState.disconnected);
  }

  @override
  Future<void> write(
    List<int> data, {
    Duration timeout = const Duration(seconds: 5),
    String? commandTag,
  }) async {
    if (!_state.isActive || _writeChar == null) {
      throw TransportError(
        code: TransportErrorCode.connectionLost,
        transportType: TransportType.bluetoothLowEnergy,
        details: 'Cannot write: no active BLE connection',
      );
    }
    await _writeChar!.write(data, withoutResponse: _writeChar!.properties.writeWithoutResponse);
  }

  @override
  Future<TransportPacket> read({
    Duration timeout = const Duration(seconds: 5),
    int? expectedLength,
  }) async {
    if (!_state.isActive || _notifyChar == null) {
      throw TransportError(
        code: TransportErrorCode.connectionLost,
        transportType: TransportType.bluetoothLowEnergy,
        details: 'Cannot read: no active BLE connection',
      );
    }
    final data = await _notifyChar!.read();
    return TransportPacket(timestamp: DateTime.now(), payload: data, sourceTransport: TransportType.bluetoothLowEnergy);
  }

  @override
  Stream<TransportPacket> subscribe() {
    return _dataController.stream;
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    _scanSub?.cancel();
    await _stateController.close();
    await _discoveryController.close();
    await _dataController.close();
  }

  BleGattConfiguration get configuration => _config;
}
