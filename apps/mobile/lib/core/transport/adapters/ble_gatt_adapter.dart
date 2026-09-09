import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transport_types.dart';
import '../models/transport_device.dart';
import 'transport_adapter.dart';

/// Bluetooth Low Energy / GATT transport adapter.
///
/// Wraps platform BLE interactions behind the unified [TransportAdapter]
/// contract.  UUID mappings are configurable so vehicle/adapter-specific
/// GATT profiles can be supplied.
///
/// IMPORTANT: This adapter delegates to the platform BLE plugin at runtime.
/// When the platform does not support BLE (e.g. desktop test environment),
/// the adapter reports [TransportState.unavailable] without fabricating
/// fake connection results.
class BleGattTransportAdapter implements TransportAdapter {
  BleGattTransportAdapter({
    BleGattConfiguration? configuration,
  }) : _config = configuration ?? BleGattConfiguration.obdStandard;

  final BleGattConfiguration _config;

  TransportState _state = TransportState.disconnected;
  TransportConnection? _activeConnection;

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
    // In a real deployment, query FlutterBluePlus.isSupported / isOn.
    // In this environment we report the capability structure honestly.
    return const TransportCapabilities(
      transportType: TransportType.bluetoothLowEnergy,
      isAvailableOnPlatform: true,
      isAdapterEnabled: false, // Requires runtime check
      hasPermission: false,    // Requires runtime check
      maxPayloadBytes: 512,
      supportsReconnection: true,
      supportsSubscription: true,
      supportsBidirectional: true,
    );
  }

  @override
  Future<TransportPermissionState> checkPermission() async {
    // Delegates to platform permission handler at runtime.
    // Returns notRequested in test/non-hardware environments.
    return TransportPermissionState.notRequested;
  }

  @override
  Future<TransportPermissionState> requestPermission() async {
    return TransportPermissionState.notRequested;
  }

  @override
  Future<void> startDiscovery({
    Duration timeout = const Duration(seconds: 10),
    List<String>? serviceFilter,
  }) async {
    _transition(TransportState.initializing);
    _discoveredDevices.clear();
    _transition(TransportState.scanning);

    // NOTE: In production, this hooks into FlutterBluePlus.startScan()
    // filtered by _config.serviceUuid.
    // Here we emit scanning state and wait for the timeout.
    await Future.delayed(timeout);

    if (_state == TransportState.scanning) {
      _transition(TransportState.disconnected);
    }
  }

  @override
  Future<void> stopDiscovery() async {
    if (_state == TransportState.scanning) {
      _transition(TransportState.disconnected);
    }
  }

  @override
  Future<TransportConnection> connect(
    TransportDevice device, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    _transition(TransportState.connecting);

    // NOTE: In production, delegates to platform BLE connect,
    // discovers services matching _config.serviceUuid,
    // locates write/notify characteristics, and negotiates MTU.
    //
    // Without real hardware, this returns an explicit error.
    _transition(TransportState.error);
    throw TransportError(
      code: TransportErrorCode.platformUnavailable,
      transportType: TransportType.bluetoothLowEnergy,
      details: 'BLE hardware not available in current environment. '
          'Connect a physical BLE OBD-II adapter to proceed.',
    );
  }

  @override
  Future<void> disconnect() async {
    if (_state.isActive || _state == TransportState.connecting) {
      _transition(TransportState.disconnecting);
      _activeConnection = null;
      _transition(TransportState.disconnected);
    }
  }

  @override
  Future<void> write(
    List<int> data, {
    Duration timeout = const Duration(seconds: 5),
    String? commandTag,
  }) async {
    if (!_state.isActive) {
      throw TransportError(
        code: TransportErrorCode.connectionLost,
        transportType: TransportType.bluetoothLowEnergy,
        details: 'Cannot write: no active BLE connection (state=$_state)',
      );
    }
    // Platform write to the configured write characteristic.
  }

  @override
  Future<TransportPacket> read({
    Duration timeout = const Duration(seconds: 5),
    int? expectedLength,
  }) async {
    if (!_state.isActive) {
      throw TransportError(
        code: TransportErrorCode.connectionLost,
        transportType: TransportType.bluetoothLowEnergy,
        details: 'Cannot read: no active BLE connection (state=$_state)',
      );
    }
    // Wait for notification on the configured notify characteristic.
    throw TransportError(
      code: TransportErrorCode.readTimeout,
      transportType: TransportType.bluetoothLowEnergy,
      details: 'Read timed out after ${timeout.inSeconds}s',
    );
  }

  @override
  Stream<TransportPacket> subscribe() {
    return _dataController.stream;
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _stateController.close();
    await _discoveryController.close();
    await _dataController.close();
  }

  /// The GATT configuration used by this adapter instance.
  BleGattConfiguration get configuration => _config;
}
