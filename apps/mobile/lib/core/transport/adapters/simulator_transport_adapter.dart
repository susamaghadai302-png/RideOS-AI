import 'dart:async';
import 'dart:convert';
import '../models/transport_types.dart';
import '../models/transport_device.dart';
import 'transport_adapter.dart';

/// Deterministic simulator transport adapter for test/demo environments.
///
/// Provides a fully functional mock transport that follows the exact
/// same [TransportAdapter] contract and state machine as real adapters,
/// but uses pre-programmed deterministic data instead of hardware.
///
/// Isolated from production transport implementations — never used when
/// [SmartScanExecutionMode] is `realHardware`.
class SimulatorTransportAdapter implements TransportAdapter {
  SimulatorTransportAdapter({
    this.simulatedTransportType = TransportType.bluetoothLowEnergy,
    this.simulatedLatencyMs = 50,
    this.shouldFailConnect = false,
    Map<String, List<int>>? commandResponses,
  }) : _commandResponses = commandResponses ?? _defaultObd2Responses;

  final TransportType simulatedTransportType;
  final int simulatedLatencyMs;
  final bool shouldFailConnect;
  final Map<String, List<int>> _commandResponses;

  TransportState _state = TransportState.disconnected;
  TransportConnection? _activeConnection;

  final _stateController = StreamController<TransportState>.broadcast();
  final _discoveryController = StreamController<TransportDevice>.broadcast();
  final _dataController = StreamController<TransportPacket>.broadcast();

  /// Default OBD-II Mode $09 responses for the Yamaha YZF-R1M simulator.
  static final Map<String, List<int>> _defaultObd2Responses = {
    // Mode $09 PID $02 → VIN
    '0902': utf8.encode('49 02 01 4A 59 41 52 4E 33 39 45 35 46 41 30 30 30 31 30 31\r>'),
    // Mode $09 PID $0A → ECU Calibration ID
    '090A': utf8.encode('49 0A 01 43 41 4C 5F 59 41 4D 41 48 41 5F 44 45 4E 53 4F\r>'),
    // ATZ → Reset
    'ATZ': utf8.encode('ELM327 v2.1 (SIM)\r\r>'),
    // ATSP0 → Auto protocol
    'ATSP0': utf8.encode('OK\r\r>'),
    // ATE0 → Echo off
    'ATE0': utf8.encode('OK\r\r>'),
  };

  @override
  TransportType get transportType => simulatedTransportType;

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
    if (!_state.canTransitionTo(next)) return;
    _state = next;
    _stateController.add(next);
  }

  @override
  Future<TransportCapabilities> getCapabilities() async {
    return TransportCapabilities(
      transportType: simulatedTransportType,
      isAvailableOnPlatform: true,
      isAdapterEnabled: true,
      hasPermission: true,
      maxPayloadBytes: 512,
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
    Duration timeout = const Duration(seconds: 3),
    List<String>? serviceFilter,
  }) async {
    // Reset state for re-entrant discovery
    if (_state.isTerminal || _state == TransportState.deviceFound) {
      _state = TransportState.disconnected;
      _stateController.add(_state);
    }
    _transition(TransportState.initializing);
    _transition(TransportState.scanning);

    // Emit a deterministic simulated device immediately so subscribers
    // always receive it regardless of async scheduling.
    final device = TransportDevice(
      deviceId: 'sim_obd2_${simulatedTransportType.name}',
      displayName: 'SIM OBD-II Adapter (${simulatedTransportType.displayName})',
      address: 'SIM:00:11:22:33:44:55',
      transportType: simulatedTransportType,
      manufacturer: 'RideOS Simulator',
      model: 'Virtual ELM327 v2.1',
      signalStrengthDbm: -42,
      connectionState: TransportState.disconnected,
      permissionState: TransportPermissionState.granted,
      lastSeen: DateTime.now(),
      supportedProtocols: const ['ISO 15765-4 CAN', 'ISO 14229 UDS'],
      metadata: const {'firmware': 'SIM-2.1.0', 'mode': 'SIMULATOR'},
    );

    _discoveryController.add(device);

    // Simulate discovery latency
    if (simulatedLatencyMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: simulatedLatencyMs));
    }

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
    Duration timeout = const Duration(seconds: 5),
  }) async {
    _transition(TransportState.connecting);
    await Future.delayed(Duration(milliseconds: simulatedLatencyMs));

    if (shouldFailConnect) {
      _transition(TransportState.error);
      throw TransportError(
        code: TransportErrorCode.connectionRefused,
        transportType: simulatedTransportType,
        details: 'Simulated connection failure (test mode)',
      );
    }

    _transition(TransportState.connected);
    _activeConnection = TransportConnection(
      connectionId: 'sim_conn_${DateTime.now().millisecondsSinceEpoch}',
      device: device,
      state: TransportState.connected,
      connectedAt: DateTime.now(),
      capabilities: TransportCapabilities(
        transportType: simulatedTransportType,
        isAvailableOnPlatform: true,
        isAdapterEnabled: true,
        hasPermission: true,
      ),
    );
    _transition(TransportState.ready);
    _activeConnection = _activeConnection!.copyWith(state: TransportState.ready);
    return _activeConnection!;
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
        transportType: simulatedTransportType,
        details: 'Cannot write: no active simulator connection (state=$_state)',
      );
    }

    await Future.delayed(Duration(milliseconds: simulatedLatencyMs ~/ 2));

    // Parse the command and look up the deterministic response.
    final cmd = String.fromCharCodes(data).trim().toUpperCase();
    final responseData = _commandResponses[cmd];

    if (responseData != null) {
      final packet = TransportPacket(
        payload: responseData,
        sourceTransport: simulatedTransportType,
        isResponse: true,
        commandTag: commandTag ?? cmd,
      );
      _dataController.add(packet);
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
        transportType: simulatedTransportType,
        details: 'Cannot read: no active simulator connection (state=$_state)',
      );
    }

    // In simulator mode, reads are provided via the dataStream after write().
    final completer = Completer<TransportPacket>();
    late final StreamSubscription<TransportPacket> sub;
    sub = _dataController.stream.listen((packet) {
      if (!completer.isCompleted) {
        completer.complete(packet);
        sub.cancel();
      }
    });

    return completer.future.timeout(
      timeout,
      onTimeout: () {
        sub.cancel();
        throw TransportError(
          code: TransportErrorCode.readTimeout,
          transportType: simulatedTransportType,
          details: 'Simulator read timed out after ${timeout.inSeconds}s',
        );
      },
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
