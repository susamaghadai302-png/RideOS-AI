import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/diagnostic_types.dart';
import '../models/dtc_record.dart';
import '../models/pid_definition.dart';
import '../protocol/obd2_command_builder.dart';
import '../protocol/iso_tp_handler.dart';
import 'diagnostic_database.dart';
import '../../transport/services/transport_manager.dart';
import '../../vehicle_identification/services/smart_scan_orchestrator.dart';
import '../../vehicle_commands/models/vehicle_command.dart';
import '../../vehicle_commands/models/command_result.dart';
import '../../vehicle_commands/services/vehicle_command_pipeline.dart';

/// Active Diagnostic Session Status.
enum DiagnosticSessionState {
  idle,
  initializingBus,
  scanningModules,
  streamingLivePids,
  readingFaults,
  clearingFaults,
  error;
}

/// Result of an ECU Module Scan.
@immutable
class EcuModuleScanResult {
  final EcuModule module;
  final bool isResponding;
  final String? ecuName;
  final String? calibrationId;
  final List<DiagnosticFaultRecord> faults;
  final int activeDtcCount;
  final Duration roundTripLatency;

  const EcuModuleScanResult({
    required this.module,
    required this.isResponding,
    this.ecuName,
    this.calibrationId,
    this.faults = const [],
    required this.activeDtcCount,
    required this.roundTripLatency,
  });
}

/// Comprehensive Multi-ECU Diagnostic Engine.
///
/// Communicates over the unified [TransportManager] physical layer
/// to perform multi-ECU discovery, live PID polling, freeze frame extraction,
/// and safety-gated fault clearing.
class EcuDiagnosticManager {
  static final EcuDiagnosticManager instance = EcuDiagnosticManager._internal();
  factory EcuDiagnosticManager() => instance;
  EcuDiagnosticManager._internal();

  final TransportManager _transportManager = TransportManager.instance;
  final DiagnosticDatabase _database = DiagnosticDatabase.instance;
  final IsoTpHandler _isoTpHandler = IsoTpHandler();
  IsoTpHandler get isoTpHandler => _isoTpHandler;

  DiagnosticProtocol _activeProtocol = DiagnosticProtocol.iso15765_4_Can_11bit_500k;
  DiagnosticProtocol get activeProtocol => _activeProtocol;

  DiagnosticSessionState _sessionState = DiagnosticSessionState.idle;
  DiagnosticSessionState get sessionState => _sessionState;

  final Map<EcuModule, EcuModuleScanResult> _moduleResults = {};
  Map<EcuModule, EcuModuleScanResult> get moduleResults => Map.unmodifiable(_moduleResults);

  final List<DiagnosticFaultRecord> _allActiveFaults = [];
  List<DiagnosticFaultRecord> get allActiveFaults => List.unmodifiable(_allActiveFaults);

  final Map<int, DecodedPidMeasurement> _latestPidValues = {};
  Map<int, DecodedPidMeasurement> get latestPidValues => Map.unmodifiable(_latestPidValues);

  // Streams
  final _stateController = StreamController<DiagnosticSessionState>.broadcast();
  Stream<DiagnosticSessionState> get stateStream => _stateController.stream;

  final _faultsController = StreamController<List<DiagnosticFaultRecord>>.broadcast();
  Stream<List<DiagnosticFaultRecord>> get faultsStream => _faultsController.stream;

  final _pidController = StreamController<Map<int, DecodedPidMeasurement>>.broadcast();
  Stream<Map<int, DecodedPidMeasurement>> get pidStream => _pidController.stream;

  Timer? _liveTelemetryTimer;
  bool _isPollingLiveTelemetry = false;
  bool get isPollingLiveTelemetry => _isPollingLiveTelemetry;

  void _setState(DiagnosticSessionState next) {
    if (_sessionState == next) return;
    _sessionState = next;
    _stateController.add(next);
  }

  /// Sets the active diagnostic protocol.
  void setProtocol(DiagnosticProtocol protocol) {
    _activeProtocol = protocol;
  }

  // =========================================================================
  // Multi-ECU Diagnostic Scan
  // =========================================================================

  /// Scans all primary vehicle ECUs (ECM, ABS, BMS, TCU, IPC, BCM) for faults.
  Future<List<DiagnosticFaultRecord>> performFullEcuScan({
    List<EcuModule>? targetModules,
  }) async {
    _setState(DiagnosticSessionState.scanningModules);
    _moduleResults.clear();
    _allActiveFaults.clear();

    final modules = targetModules ??
        const [
          EcuModule.engineControlModule_ECM,
          EcuModule.antiLockBraking_ABS,
          EcuModule.batteryManagementSystem_BMS,
          EcuModule.transmissionControlUnit_TCU,
          EcuModule.instrumentCluster_IPC,
          EcuModule.bodyControlModule_BCM,
        ];

    final isSimulator = _transportManager.executionMode == SmartScanExecutionMode.simulator ||
        _transportManager.executionMode == SmartScanExecutionMode.testBench;

    for (final module in modules) {
      final stopwatch = Stopwatch()..start();

      if (isSimulator) {
        // Deterministic simulated multi-ECU responses
        final faults = _generateSimulatedFaultsForModule(module);
        _moduleResults[module] = EcuModuleScanResult(
          module: module,
          isResponding: true,
          ecuName: '${module.name}_SIM_V2.1',
          calibrationId: 'CAL_${module.name}_2026',
          faults: faults,
          activeDtcCount: faults.length,
          roundTripLatency: Duration(milliseconds: 15 + (module.index * 5)),
        );
        _allActiveFaults.addAll(faults);
      } else {
        // Real hardware path: query via TransportManager
        try {
          if (!_transportManager.managerState.isActive) {
            _moduleResults[module] = EcuModuleScanResult(
              module: module,
              isResponding: false,
              activeDtcCount: 0,
              roundTripLatency: stopwatch.elapsed,
            );
            continue;
          }

          // Format OBD-II Mode $03 request to target module address
          final cmd = Obd2CommandBuilder.requestConfirmedDtcs();
          await _transportManager.write(utf8.encode(cmd));
          final packet = await _transportManager.read(timeout: const Duration(seconds: 3));
          final rawBytes = Obd2CommandBuilder.parseAsciiHexToBytes(
            utf8.decode(packet.payload, allowMalformed: true),
          );

          final rawFaults = Obd2CommandBuilder.parseDtcResponse(rawBytes, module: module);
          final enrichedFaults = rawFaults.map((f) => _database.lookup(f.code, module: module)).toList();

          _moduleResults[module] = EcuModuleScanResult(
            module: module,
            isResponding: true,
            faults: enrichedFaults,
            activeDtcCount: enrichedFaults.length,
            roundTripLatency: stopwatch.elapsed,
          );
          _allActiveFaults.addAll(enrichedFaults);
        } catch (e) {
          _moduleResults[module] = EcuModuleScanResult(
            module: module,
            isResponding: false,
            activeDtcCount: 0,
            roundTripLatency: stopwatch.elapsed,
          );
        }
      }
    }

    _faultsController.add(_allActiveFaults);
    _setState(DiagnosticSessionState.idle);
    return List.unmodifiable(_allActiveFaults);
  }

  // =========================================================================
  // Live Telemetry Polling (Mode $01)
  // =========================================================================

  /// Starts high-frequency polling of standard Mode $01 PIDs.
  void startLiveTelemetryPolling({
    Duration interval = const Duration(milliseconds: 200),
    List<DiagnosticPid>? pids,
  }) {
    if (_isPollingLiveTelemetry) return;
    _isPollingLiveTelemetry = true;
    _setState(DiagnosticSessionState.streamingLivePids);

    final targetPids = pids ?? DiagnosticPid.standardPids;

    _liveTelemetryTimer = Timer.periodic(interval, (_) async {
      await _pollPidCycle(targetPids);
    });
  }

  /// Stops live telemetry polling.
  void stopLiveTelemetryPolling() {
    _liveTelemetryTimer?.cancel();
    _liveTelemetryTimer = null;
    _isPollingLiveTelemetry = false;
    _setState(DiagnosticSessionState.idle);
  }

  Future<void> _pollPidCycle(List<DiagnosticPid> pids) async {
    final isSimulator = _transportManager.executionMode == SmartScanExecutionMode.simulator ||
        _transportManager.executionMode == SmartScanExecutionMode.testBench;

    for (final pid in pids) {
      if (isSimulator) {
        final mockValue = _generateSimulatedPidValue(pid);
        _latestPidValues[pid.pid] = DecodedPidMeasurement(
          pid: pid,
          value: mockValue,
          unit: pid.unit,
          timestamp: DateTime.now(),
          isValid: true,
        );
      } else {
        if (!_transportManager.managerState.isActive) continue;
        try {
          final cmd = Obd2CommandBuilder.requestLivePid(pid);
          await _transportManager.write(utf8.encode(cmd));
          final packet = await _transportManager.read(timeout: const Duration(milliseconds: 500));
          final bytes = Obd2CommandBuilder.parseAsciiHexToBytes(
            utf8.decode(packet.payload, allowMalformed: true),
          );
          final measurement = Obd2CommandBuilder.parseMode01Response(bytes, pid);
          if (measurement != null) {
            _latestPidValues[pid.pid] = measurement;
          }
        } catch (_) {
          // Keep prior measurement if poll misses single frame
        }
      }
    }
    _pidController.add(Map.unmodifiable(_latestPidValues));
  }

  // =========================================================================
  // Safety-Gated DTC Clear (Mode $04 / UDS $14)
  // =========================================================================

  /// Clears active DTCs with strict safety constraints.
  ///
  /// CRITICAL SAFETY RULE: Clearing DTCs is only permitted when vehicle speed is 0.0 km/h.
  /// Clearing while in motion will throw a [StateError].
  Future<bool> clearAllDiagnosticFaults({
    bool forceConfirmation = false,
  }) async {
    if (!forceConfirmation) {
      throw ArgumentError('User confirmation required to clear DTC memory.');
    }

    // Safety constraint: Verify vehicle is stationary (Fail-Closed)
    final speedMeasurement = _latestPidValues[DiagnosticPid.vehicleSpeed.pid];
    if (speedMeasurement == null || !speedMeasurement.isValid) {
      throw StateError(
        'SAFETY INTERLOCK: Cannot clear DTCs. Missing or invalid vehicle speed telemetry. '
        'A valid speed of 0.0 km/h is required to ensure safety.',
      );
    }
    final currentSpeed = speedMeasurement.value;
    if (currentSpeed > 0.0) {
      throw StateError(
        'SAFETY INTERLOCK: Cannot clear DTCs while vehicle is in motion (Speed: ${currentSpeed.toStringAsFixed(1)} km/h). '
        'Park vehicle and bring speed to 0.0 km/h before resetting fault memory.',
      );
    }

    _setState(DiagnosticSessionState.clearingFaults);

    final isSimulator = _transportManager.executionMode == SmartScanExecutionMode.simulator ||
        _transportManager.executionMode == SmartScanExecutionMode.testBench;

    if (isSimulator) {
      await Future.delayed(const Duration(milliseconds: 150));
      _allActiveFaults.clear();
      _moduleResults.clear();
      _faultsController.add(const []);
      _setState(DiagnosticSessionState.idle);
      return true;
    }

    try {
      if (!_transportManager.managerState.isActive) {
        throw StateError('Cannot clear DTCs: Transport adapter is not connected.');
      }

      final result = await VehicleCommandPipeline().execute(
        VehicleCommand(type: VehicleCommandType.clearFaultCodes),
      );

      final success = result.status == CommandResultStatus.success;
      if (success) {
        _allActiveFaults.clear();
        _faultsController.add(const []);
      }
      _setState(DiagnosticSessionState.idle);
      return success;
    } catch (e) {
      _setState(DiagnosticSessionState.error);
      rethrow;
    }
  }

  // =========================================================================
  // Simulator Data Generators
  // =========================================================================

  List<DiagnosticFaultRecord> _generateSimulatedFaultsForModule(EcuModule module) {
    switch (module) {
      case EcuModule.engineControlModule_ECM:
        return [
          _database.lookup('P0115', module: module), // Engine Coolant Temp
          _database.lookup('P0300', module: module), // Random Misfire (Critical)
        ];
      case EcuModule.antiLockBraking_ABS:
        return [
          _database.lookup('C0035', module: module), // Front Wheel Speed
        ];
      case EcuModule.batteryManagementSystem_BMS:
        return [
          _database.lookup('P0562', module: module), // Low System Voltage
        ];
      case EcuModule.transmissionControlUnit_TCU:
        return [];
      case EcuModule.instrumentCluster_IPC:
        return [];
      case EcuModule.bodyControlModule_BCM:
        return [];
      case EcuModule.electronicSuspension_DES:
      case EcuModule.tractionControl_IMU:
      case EcuModule.telematicsBox_TCU:
        return [];
    }
  }

  double _generateSimulatedPidValue(DiagnosticPid pid) {
    final now = DateTime.now().millisecondsSinceEpoch;
    switch (pid.code) {
      case '0C': // RPM
        return 2800.0 + (500.0 * ((now ~/ 500) % 6));
      case '0D': // Speed
        return 65.0 + (5.0 * ((now ~/ 1000) % 4));
      case '05': // Coolant Temp
        return 88.0;
      case '11': // Throttle
        return 24.5;
      case '42': // Voltage
        return 14.3;
      case '2F': // Fuel Level
        return 78.0;
      case '10': // MAF
        return 18.2;
      case '0F': // IAT
        return 26.0;
      default:
        return 50.0;
    }
  }

  Future<void> dispose() async {
    stopLiveTelemetryPolling();
    await _stateController.close();
    await _faultsController.close();
    await _pidController.close();
  }
}
