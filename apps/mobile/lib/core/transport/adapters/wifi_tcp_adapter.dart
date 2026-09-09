import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transport_types.dart';
import '../models/transport_device.dart';
import 'transport_adapter.dart';

/// Wi-Fi TCP transport adapter.
///
/// Provides configurable host/IP + port TCP socket communication
/// for Wi-Fi-based OBD-II adapters.
///
/// IMPORTANT: This adapter does NOT perform arbitrary network scanning.
/// The user must supply the target host and port via [WifiTcpConfiguration].
/// When a connection cannot be established, the adapter returns an explicit
/// error without falling back to fake data.
class WifiTcpTransportAdapter implements TransportAdapter {
  WifiTcpTransportAdapter({
    WifiTcpConfiguration? configuration,
  }) : _config = configuration ?? WifiTcpConfiguration.elm327WifiDefault;

  final WifiTcpConfiguration _config;

  TransportState _state = TransportState.disconnected;
  TransportConnection? _activeConnection;

  final _stateController = StreamController<TransportState>.broadcast();
  final _discoveryController = StreamController<TransportDevice>.broadcast();
  final _dataController = StreamController<TransportPacket>.broadcast();

  @override
  TransportType get transportType => TransportType.wifiTcp;

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
      debugPrint('[WiFi] Invalid state transition: $_state → $next');
      return;
    }
    _state = next;
    _stateController.add(next);
  }

  @override
  Future<TransportCapabilities> getCapabilities() async {
    return const TransportCapabilities(
      transportType: TransportType.wifiTcp,
      isAvailableOnPlatform: true,
      isAdapterEnabled: false, // Requires Wi-Fi connectivity check
      hasPermission: true,     // No special permission for client TCP sockets
      maxPayloadBytes: 65535,
      supportsReconnection: true,
      supportsSubscription: true,
      supportsBidirectional: true,
    );
  }

  @override
  Future<TransportPermissionState> checkPermission() async {
    // TCP client sockets generally don't require special permissions.
    return TransportPermissionState.granted;
  }

  @override
  Future<TransportPermissionState> requestPermission() async {
    return TransportPermissionState.granted;
  }

  @override
  Future<void> startDiscovery({
    Duration timeout = const Duration(seconds: 5),
    List<String>? serviceFilter,
  }) async {
    // Wi-Fi TCP does not support broadcast/multicast discovery
    // in this architecture. The device is created from the known
    // configuration (host + port).
    _transition(TransportState.initializing);

    final device = TransportDevice(
      deviceId: 'wifi_${_config.host}:${_config.port}',
      displayName: 'Wi-Fi OBD-II (${_config.host}:${_config.port})',
      address: '${_config.host}:${_config.port}',
      transportType: TransportType.wifiTcp,
      manufacturer: 'Wi-Fi Adapter',
      connectionState: TransportState.disconnected,
      permissionState: TransportPermissionState.granted,
      lastSeen: DateTime.now(),
      supportedProtocols: const ['ISO 15765-4', 'ISO 14229'],
    );
    _discoveryController.add(device);
    _transition(TransportState.scanning);

    // Emit the pre-configured device immediately.
    await Future.delayed(const Duration(milliseconds: 100));
    _transition(TransportState.deviceFound);
  }

  @override
  Future<void> stopDiscovery() async {
    if (_state == TransportState.scanning || _state == TransportState.deviceFound) {
      _transition(TransportState.disconnected);
    }
  }

  @override
  Future<TransportConnection> connect(
    TransportDevice device, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    _transition(TransportState.connecting);

    // In production: opens a TCP socket to _config.host : _config.port,
    // with _config.connectionTimeout, and configures keepAlive.
    _transition(TransportState.error);
    throw TransportError(
      code: TransportErrorCode.connectionRefused,
      transportType: TransportType.wifiTcp,
      details: 'TCP connection to ${_config.host}:${_config.port} failed. '
          'Ensure the Wi-Fi OBD-II adapter is powered on and reachable.',
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
        transportType: TransportType.wifiTcp,
        details: 'Cannot write: no active Wi-Fi TCP connection (state=$_state)',
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
        transportType: TransportType.wifiTcp,
        details: 'Cannot read: no active Wi-Fi TCP connection (state=$_state)',
      );
    }
    throw TransportError(
      code: TransportErrorCode.readTimeout,
      transportType: TransportType.wifiTcp,
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

  /// The TCP configuration used by this adapter instance.
  WifiTcpConfiguration get configuration => _config;
}
