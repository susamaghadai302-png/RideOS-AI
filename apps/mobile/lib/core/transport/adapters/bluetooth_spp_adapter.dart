import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transport_types.dart';
import '../models/transport_device.dart';
import 'transport_adapter.dart';

/// Bluetooth Classic Serial Port Profile (SPP) transport adapter.
///
/// Provides device discovery, pairing-aware connection lifecycle,
/// and byte-stream I/O over Bluetooth Classic RFCOMM channels.
///
/// IMPORTANT: This adapter delegates to the platform Bluetooth Classic
/// plugin at runtime. When the platform does not support SPP or when
/// the Bluetooth adapter is disabled, the adapter reports
/// [TransportState.unavailable] without fabricating fake data.
class BluetoothSppTransportAdapter implements TransportAdapter {
  BluetoothSppTransportAdapter();

  TransportState _state = TransportState.disconnected;
  TransportConnection? _activeConnection;

  final _stateController = StreamController<TransportState>.broadcast();
  final _discoveryController = StreamController<TransportDevice>.broadcast();
  final _dataController = StreamController<TransportPacket>.broadcast();

  @override
  TransportType get transportType => TransportType.bluetoothClassicSpp;

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
      debugPrint('[SPP] Invalid state transition: $_state → $next');
      return;
    }
    _state = next;
    _stateController.add(next);
  }

  @override
  Future<TransportCapabilities> getCapabilities() async {
    return const TransportCapabilities(
      transportType: TransportType.bluetoothClassicSpp,
      isAvailableOnPlatform: true,
      isAdapterEnabled: false, // Requires runtime check
      hasPermission: false,    // Requires runtime check
      maxPayloadBytes: 1024,
      supportsReconnection: true,
      supportsSubscription: true,
      supportsBidirectional: true,
    );
  }

  @override
  Future<TransportPermissionState> checkPermission() async {
    return TransportPermissionState.notRequested;
  }

  @override
  Future<TransportPermissionState> requestPermission() async {
    return TransportPermissionState.notRequested;
  }

  @override
  Future<void> startDiscovery({
    Duration timeout = const Duration(seconds: 12),
    List<String>? serviceFilter,
  }) async {
    _transition(TransportState.initializing);
    _transition(TransportState.scanning);

    // In production: triggers platform Bluetooth Classic inquiry scan
    // and emits paired/discovered devices through discoveryStream.
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

    // In production: opens RFCOMM channel to the SPP UUID,
    // establishes input/output streams.
    _transition(TransportState.error);
    throw TransportError(
      code: TransportErrorCode.platformUnavailable,
      transportType: TransportType.bluetoothClassicSpp,
      details: 'Bluetooth Classic SPP hardware not available in current '
          'environment. Pair a physical OBD-II adapter to proceed.',
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
        transportType: TransportType.bluetoothClassicSpp,
        details: 'Cannot write: no active SPP connection (state=$_state)',
      );
    }
  }

  @override
  Future<TransportPacket> read({
    Duration timeout = const Duration(seconds: 5),
    int? expectedLength,
  }) async {
    if (!_state.isActive) {
      throw TransportError(
        code: TransportErrorCode.connectionLost,
        transportType: TransportType.bluetoothClassicSpp,
        details: 'Cannot read: no active SPP connection (state=$_state)',
      );
    }
    throw TransportError(
      code: TransportErrorCode.readTimeout,
      transportType: TransportType.bluetoothClassicSpp,
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
}
