import 'dart:async';
import '../device_providers/interfaces/device_provider.dart';
import '../device_providers/models/normalized_telemetry_models.dart';
import '../device_providers/providers/simulator_provider.dart';
import '../vehicle_commands/models/vehicle_command.dart';
import '../vehicle_commands/models/command_result.dart';
import '../vehicle_commands/services/vehicle_command_pipeline.dart';

/// Canonical Platform-Independent Vehicle Data Gateway Contract (ADR-09).
///
/// Decouples the application and domain layers from physical transport technologies
/// (BLE, Bluetooth Classic, USB OTG, CAN, VHAL, or Simulator).
///
/// Guarantees:
/// - Exposes strictly normalized, type-safe telemetry streams ([NormalizedTelemetrySnapshot]).
/// - Retains provenance metadata: source ([TelemetryDataSource]), quality, confidence, and timestamps.
/// - Never leaks low-level BLE GATT UUIDs, AT commands, or platform SDK objects.
abstract class VehicleDataGateway {
  /// Reactive stream of normalized real-time telemetry snapshots.
  Stream<NormalizedTelemetrySnapshot> get telemetryStream;

  /// Latest cached telemetry snapshot.
  NormalizedTelemetrySnapshot get currentTelemetry;

  /// Reactive stream of physical device connection states.
  Stream<DeviceLinkState> get linkStateStream;

  /// Current physical link state.
  DeviceLinkState get currentLinkState;

  /// Reactive stream of detected Diagnostic Trouble Codes (DTC).
  Stream<List<DiagnosticTroubleCode>> get diagnosticFaultsStream;

  /// Current active DTC fault records.
  List<DiagnosticTroubleCode> get activeFaults;

  /// Asynchronously connects to a targeted physical or virtual vehicle identifier.
  Future<bool> connect(String targetIdentifier);

  /// Gracefully terminates the physical vehicle connection.
  Future<void> disconnect();

  /// Requests clearing of emission and diagnostic trouble codes (OBD Mode 04).
  /// Note: The hardware motion safety interlock (ADR-16) will reject this if speed > 0.
  Future<bool> clearDtcFaults();

  /// Releases gateway resources and closes active streams.
  Future<void> dispose();
}

/// Production Adapter Bridge wrapping a [DeviceProvider] into the canonical [VehicleDataGateway].
class DeviceProviderVehicleDataGateway implements VehicleDataGateway {
  final DeviceProvider _deviceProvider;
  NormalizedTelemetrySnapshot _cachedTelemetry;
  List<DiagnosticTroubleCode> _cachedFaults = const [];
  StreamSubscription<NormalizedTelemetrySnapshot>? _telemetrySub;
  StreamSubscription<List<DiagnosticTroubleCode>>? _faultsSub;

  DeviceProviderVehicleDataGateway({DeviceProvider? provider})
      : _deviceProvider = provider ?? SimulatorProvider(),
        _cachedTelemetry = _createInitialSnapshot() {
    _initSubscriptions();
  }

  static NormalizedTelemetrySnapshot _createInitialSnapshot() {
    final now = DateTime.now();
    return NormalizedTelemetrySnapshot(
      dataSource: TelemetryDataSource.simulated,
      timestamp: now,
      vehicleSpeedKmh: TelemetryMetric(value: 0.0, unit: 'km/h', timestamp: now),
      engineRpm: TelemetryMetric(value: 0, unit: 'RPM', timestamp: now),
      gearPosition: TelemetryMetric(value: 0, unit: 'N', timestamp: now),
      throttlePositionPct: TelemetryMetric(value: 0.0, unit: '%', timestamp: now),
      engineLoadPct: TelemetryMetric(value: 0.0, unit: '%', timestamp: now),
      coolantTempC: TelemetryMetric(value: 85.0, unit: ' degC', timestamp: now),
      engineTempC: TelemetryMetric(value: 90.0, unit: ' degC', timestamp: now),
      intakeTempC: TelemetryMetric(value: 25.0, unit: ' degC', timestamp: now),
      batteryVoltage: TelemetryMetric(value: 12.8, unit: 'V', timestamp: now),
      batteryCurrentAmps: TelemetryMetric(value: 0.0, unit: 'A', timestamp: now),
      fuelLevelPct: TelemetryMetric(value: 100.0, unit: '%', timestamp: now),
      leanAngleDeg: TelemetryMetric(value: 0.0, unit: ' deg', timestamp: now),
      vibrationLevelG: TelemetryMetric(value: 0.0, unit: 'G', timestamp: now),
      accelerationX: TelemetryMetric(value: 0.0, unit: 'G', timestamp: now),
      accelerationY: TelemetryMetric(value: 0.0, unit: 'G', timestamp: now),
      accelerationZ: TelemetryMetric(value: 1.0, unit: 'G', timestamp: now),
    );
  }

  void _initSubscriptions() {
    _telemetrySub = _deviceProvider.telemetryStream.listen((snapshot) {
      _cachedTelemetry = snapshot;
    });
    _faultsSub = _deviceProvider.diagnosticCodesStream.listen((faults) {
      _cachedFaults = faults;
    });
  }

  @override
  Stream<NormalizedTelemetrySnapshot> get telemetryStream => _deviceProvider.telemetryStream;

  @override
  NormalizedTelemetrySnapshot get currentTelemetry => _cachedTelemetry;

  @override
  Stream<DeviceLinkState> get linkStateStream => _deviceProvider.linkStateStream;

  @override
  DeviceLinkState get currentLinkState => _deviceProvider.linkState;

  @override
  Stream<List<DiagnosticTroubleCode>> get diagnosticFaultsStream => _deviceProvider.diagnosticCodesStream;

  @override
  List<DiagnosticTroubleCode> get activeFaults => _cachedFaults;

  @override
  Future<bool> connect(String targetIdentifier) => _deviceProvider.connect(targetIdentifier);

  @override
  Future<void> disconnect() => _deviceProvider.disconnect();

  @override
  Future<bool> clearDtcFaults() async {
    final result = await VehicleCommandPipeline().execute(
      VehicleCommand(type: VehicleCommandType.clearFaultCodes),
    );
    return result.status == CommandResultStatus.success;
  }

  @override
  Future<void> dispose() async {
    await _telemetrySub?.cancel();
    await _faultsSub?.cancel();
    await _deviceProvider.dispose();
  }
}
