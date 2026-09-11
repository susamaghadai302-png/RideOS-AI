import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/transport_types.dart';
import '../models/transport_device.dart';
import '../adapters/transport_adapter.dart';
import '../adapters/ble_gatt_adapter.dart';
import '../adapters/bluetooth_spp_adapter.dart';
import '../adapters/usb_serial_adapter.dart';
import '../adapters/wifi_tcp_adapter.dart';
import '../../vehicle_identification/services/smart_scan_orchestrator.dart';

/// Unified Multi-Transport Connectivity Manager.
///
/// Provides a single entry point for transport discovery, connection,
/// and data exchange. The diagnostic layer and UI communicate ONLY
/// through this manager — never directly with individual adapters.
///
/// Transport selection priority (configurable):
///   1. Explicit user selection
///   2. Known/previously paired device
///   3. BLE GATT
///   4. Bluetooth Classic SPP
///   5. USB OTG Serial
///   6. Wi-Fi TCP
///
/// IMPORTANT: The manager does NOT automatically connect to unknown
/// devices without explicit user action (safe-by-default policy).
class TransportManager {
  static final TransportManager instance = TransportManager._internal();
  factory TransportManager() => instance;
  TransportManager._internal() {
    _initializeAdapters();
  }

  /// All registered transport adapters keyed by type.
  final Map<TransportType, TransportAdapter> _adapters = {};

  /// Current execution mode (inherits from SmartScanOrchestrator).
  SmartScanExecutionMode _executionMode = SmartScanExecutionMode.realHardware;
  SmartScanExecutionMode get executionMode => _executionMode;

  /// Active connection, if any.
  TransportConnection? _activeConnection;
  TransportConnection? get activeConnection => _activeConnection;

  /// Active adapter, if connected.
  TransportAdapter? _activeAdapter;
  TransportAdapter? get activeAdapter => _activeAdapter;

  /// Overall manager state.
  TransportState _managerState = TransportState.disconnected;
  TransportState get managerState => _managerState;

  /// Discovered devices across all transports.
  final List<TransportDevice> _discoveredDevices = [];
  List<TransportDevice> get discoveredDevices => List.unmodifiable(_discoveredDevices);

  /// State broadcast.
  final _stateController = StreamController<TransportManagerState>.broadcast();
  Stream<TransportManagerState> get stateStream => _stateController.stream;
  TransportManagerState get currentManagerState => TransportManagerState(
        managerState: _managerState,
        executionMode: _executionMode,
        activeConnection: _activeConnection,
        discoveredDevices: _discoveredDevices,
        transportAvailability: _transportAvailability,
      );

  /// Per-transport availability cache.
  final Map<TransportType, TransportCapabilities> _transportAvailability = {};

  /// Retry policy.
  TransportRetryPolicy _retryPolicy = TransportRetryPolicy.defaultPolicy;
  set retryPolicy(TransportRetryPolicy policy) => _retryPolicy = policy;

  /// Transport selection priority.
  List<TransportType> selectionPriority = const [
    TransportType.bluetoothLowEnergy,
    TransportType.bluetoothClassicSpp,
    TransportType.usbOtgSerial,
    TransportType.wifiTcp,
  ];

  void _initializeAdapters() {
    _adapters[TransportType.bluetoothLowEnergy] = BleGattTransportAdapter();
    _adapters[TransportType.bluetoothClassicSpp] = BluetoothSppTransportAdapter();
    _adapters[TransportType.usbOtgSerial] = UsbSerialTransportAdapter();
    _adapters[TransportType.wifiTcp] = WifiTcpTransportAdapter();
  }

  void _emitState() {
    _stateController.add(currentManagerState);
  }

  /// Set the execution mode (REAL_HARDWARE, SIMULATOR, TEST_BENCH, UNAVAILABLE).
  void setExecutionMode(SmartScanExecutionMode mode) {
    _executionMode = mode;
    _emitState();
  }

  /// Get the adapter for a specific transport type.
  TransportAdapter? getAdapter(TransportType type) {
    return _adapters[type];
  }

  /// Query capabilities for all registered transports.
  Future<Map<TransportType, TransportCapabilities>> queryAllCapabilities() async {
    _transportAvailability.clear();
    for (final entry in _adapters.entries) {
      final caps = await entry.value.getCapabilities();
      _transportAvailability[entry.key] = caps;
    }
    _emitState();
    return Map.unmodifiable(_transportAvailability);
  }

  /// Discover devices across all (or specified) transports.
  Future<List<TransportDevice>> discoverDevices({
    List<TransportType>? transports,
    Duration timeout = const Duration(seconds: 8),
  }) async {
    _managerState = TransportState.scanning;
    _discoveredDevices.clear();
    _emitState();

    final targetTransports = transports ?? selectionPriority;

    for (final type in targetTransports) {
      final adapter = getAdapter(type);
      if (adapter == null) continue;

      final sub = adapter.discoveryStream.listen((device) {
        if (!_discoveredDevices.any((d) => d.deviceId == device.deviceId)) {
          _discoveredDevices.add(device);
          _managerState = TransportState.deviceFound;
          _emitState();
        }
      });

      try {
        await adapter.startDiscovery(timeout: timeout);
      } catch (e) {
        debugPrint('[TransportManager] Discovery error on $type: $e');
      } finally {
        await sub.cancel();
      }
    }

    _managerState = _discoveredDevices.isEmpty
        ? TransportState.disconnected
        : TransportState.deviceFound;
    _emitState();
    return discoveredDevices;
  }

  /// Connect to a specific device.
  ///
  /// IMPORTANT: Does NOT automatically connect to unknown devices.
  /// The caller must explicitly specify the target device.
  Future<TransportConnection> connectToDevice(
    TransportDevice device, {
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final adapter = getAdapter(device.transportType);
    if (adapter == null) {
      throw TransportError(
        code: TransportErrorCode.platformUnavailable,
        transportType: device.transportType,
        details: 'No adapter registered for ${device.transportType.displayName}',
      );
    }

    _managerState = TransportState.connecting;
    _emitState();

    // Retry loop with exponential backoff.
    TransportError? lastError;
    for (int attempt = 0; attempt <= _retryPolicy.maxRetries; attempt++) {
      if (attempt > 0) {
        final delay = _retryPolicy.delayForAttempt(attempt);
        debugPrint('[TransportManager] Retry $attempt/${_retryPolicy.maxRetries} '
            'after ${delay.inMilliseconds}ms');
        await Future.delayed(delay);
      }

      try {
        final connection = await adapter.connect(device, timeout: timeout);
        _activeConnection = connection;
        _activeAdapter = adapter;
        _managerState = TransportState.ready;
        _emitState();
        return connection;
      } on TransportError catch (e) {
        lastError = e;
        debugPrint('[TransportManager] Connection attempt ${attempt + 1} failed: $e');
      }
    }

    _managerState = TransportState.error;
    _emitState();
    throw lastError ??
        TransportError(
          code: TransportErrorCode.unknown,
          transportType: device.transportType,
          details: 'All connection attempts failed',
        );
  }

  /// Auto-select the best available transport and connect.
  ///
  /// Uses the configured priority order, attempting each transport
  /// in sequence until one succeeds. Returns null if all fail.
  Future<TransportConnection?> autoConnect({
    Duration discoveryTimeout = const Duration(seconds: 5),
    Duration connectionTimeout = const Duration(seconds: 10),
  }) async {
    final devices = await discoverDevices(timeout: discoveryTimeout);
    if (devices.isEmpty) return null;

    // Sort discovered devices by priority order.
    final sorted = List<TransportDevice>.from(devices)
      ..sort((a, b) {
        final aIdx = selectionPriority.indexOf(a.transportType);
        final bIdx = selectionPriority.indexOf(b.transportType);
        return aIdx.compareTo(bIdx);
      });

    for (final device in sorted) {
      try {
        return await connectToDevice(device, timeout: connectionTimeout);
      } on TransportError catch (e) {
        debugPrint('[TransportManager] Auto-connect failed for ${device.displayName}: $e');
      }
    }

    return null;
  }

  /// Disconnect the active connection.
  Future<void> disconnect() async {
    if (_activeAdapter != null) {
      await _activeAdapter!.disconnect();
    }
    _activeConnection = null;
    _activeAdapter = null;
    _managerState = TransportState.disconnected;
    _emitState();
  }

  /// Write data through the active connection.
  Future<void> write(
    List<int> data, {
    Duration timeout = const Duration(seconds: 5),
    String? commandTag,
  }) async {
    if (_activeAdapter == null || !_managerState.isActive) {
      throw TransportError(
        code: TransportErrorCode.connectionLost,
        details: 'No active transport connection for write',
      );
    }
    await _activeAdapter!.write(data, timeout: timeout, commandTag: commandTag);
  }

  /// Read data from the active connection.
  Future<TransportPacket> read({
    Duration timeout = const Duration(seconds: 5),
    int? expectedLength,
  }) async {
    if (_activeAdapter == null || !_managerState.isActive) {
      throw TransportError(
        code: TransportErrorCode.connectionLost,
        details: 'No active transport connection for read',
      );
    }
    return _activeAdapter!.read(timeout: timeout, expectedLength: expectedLength);
  }

  /// Subscribe to incoming data from the active connection.
  Stream<TransportPacket> subscribe() {
    if (_activeAdapter == null) {
      return const Stream.empty();
    }
    return _activeAdapter!.subscribe();
  }

  /// Clean up all adapter resources.
  Future<void> dispose() async {
    await disconnect();
    for (final adapter in _adapters.values) {
      await adapter.dispose();
    }
    await _stateController.close();
  }
}

/// Snapshot of the transport manager state, emitted through [TransportManager.stateStream].
@immutable
class TransportManagerState {
  final TransportState managerState;
  final SmartScanExecutionMode executionMode;
  final TransportConnection? activeConnection;
  final List<TransportDevice> discoveredDevices;
  final Map<TransportType, TransportCapabilities> transportAvailability;

  const TransportManagerState({
    required this.managerState,
    required this.executionMode,
    this.activeConnection,
    this.discoveredDevices = const [],
    this.transportAvailability = const {},
  });

  bool get isConnected => managerState.isActive;
  bool get hasDevices => discoveredDevices.isNotEmpty;
  int get deviceCount => discoveredDevices.length;

  TransportCapabilities? capabilitiesFor(TransportType type) =>
      transportAvailability[type];

  List<TransportDevice> devicesFor(TransportType type) =>
      discoveredDevices.where((d) => d.transportType == type).toList();
}
