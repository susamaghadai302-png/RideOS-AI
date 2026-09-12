import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/transport_types.dart';
import '../models/transport_device.dart';
import 'transport_adapter.dart';

class WifiTcpTransportAdapter implements TransportAdapter {
  WifiTcpTransportAdapter({
    WifiTcpConfiguration? configuration,
  }) : _config = configuration ?? WifiTcpConfiguration.elm327WifiDefault;

  final WifiTcpConfiguration _config;

  TransportState _state = TransportState.disconnected;
  TransportConnection? _activeConnection;
  Socket? _socket;
  
  StreamSubscription<List<int>>? _socketSub;

  final _stateController = StreamController<TransportState>.broadcast();
  final _discoveryController = StreamController<TransportDevice>.broadcast();
  final _dataController = StreamController<TransportPacket>.broadcast();

  final List<TransportDevice> _discoveredDevices = [];

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
      isAdapterEnabled: true,
      hasPermission: true,
      maxPayloadBytes: 4096,
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
    Duration timeout = const Duration(seconds: 5),
    List<String>? serviceFilter,
  }) async {
    if (_state.isActive) return;
    _transition(TransportState.initializing);
    _discoveredDevices.clear();
    
    // In TCP we usually don't "scan" local network without a specific mDNS target.
    // We just yield the configured host as a discovered device so the UI can connect to it.
    _transition(TransportState.scanning);
    
    final device = TransportDevice(
      deviceId: '${_config.host}:${_config.port}',
      displayName: 'Network TCP Device',
      address: '${_config.host}:${_config.port}',
      lastSeen: DateTime.now(),
      transportType: TransportType.wifiTcp,
    );
    
    _discoveredDevices.add(device);
    _discoveryController.add(device);
    
    await Future.delayed(const Duration(milliseconds: 100));
    _transition(TransportState.deviceFound);
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
    if (_state.isActive) await disconnect();
    _transition(TransportState.connecting);

    try {
      _socket = await Socket.connect(_config.host, _config.port, timeout: timeout);
      
      _socketSub = _socket!.listen(
        (data) {
          _dataController.add(TransportPacket(
            timestamp: DateTime.now(),
            payload: data,
            sourceTransport: TransportType.wifiTcp,
          ));
        },
        onError: (e) {
          _cleanupConnection();
          _transition(TransportState.error);
        },
        onDone: () {
          _cleanupConnection();
          _transition(TransportState.disconnected);
        },
      );

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
        transportType: TransportType.wifiTcp,
        details: e.toString(),
      );
    }
  }

  void _cleanupConnection() {
    _socketSub?.cancel();
    _socket?.destroy();
    _socket = null;
    _activeConnection = null;
  }

  @override
  Future<void> disconnect() async {
    _transition(TransportState.disconnecting);
    _cleanupConnection();
    _transition(TransportState.disconnected);
  }

  @override
  Future<void> write(
    List<int> data, {
    Duration timeout = const Duration(seconds: 5),
    String? commandTag,
  }) async {
    if (!_state.isActive || _socket == null) {
      throw TransportError(
        code: TransportErrorCode.connectionLost,
        transportType: TransportType.wifiTcp,
        details: 'Cannot write: no active Wi-Fi TCP connection',
      );
    }
    _socket!.add(data);
    await _socket!.flush();
  }

  @override
  Future<TransportPacket> read({
    Duration timeout = const Duration(seconds: 5),
    int? expectedLength,
  }) async {
    throw TransportError(
      code: TransportErrorCode.readTimeout,
      transportType: TransportType.wifiTcp,
      details: 'Read not implemented for Socket. Use stream subscription.',
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
