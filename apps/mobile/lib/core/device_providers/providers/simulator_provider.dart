import 'dart:async';
import 'dart:math' as math;
import '../interfaces/device_provider.dart';
import '../models/normalized_telemetry_models.dart';

class SimulatorProvider implements DeviceProvider {
  @override
  String get providerId => 'simulator_telemetry_provider';

  @override
  String get displayName => 'RideOS Telemetry Simulator';

  @override
  TelemetryDataSource get dataSourceClassification => TelemetryDataSource.simulated;

  @override
  bool get canClearDtcCodes => true;

  DeviceLinkState _linkState = DeviceLinkState.disconnected;
  @override
  DeviceLinkState get linkState => _linkState;

  final _linkStateController = StreamController<DeviceLinkState>.broadcast();
  @override
  Stream<DeviceLinkState> get linkStateStream => _linkStateController.stream;

  final _telemetryController = StreamController<NormalizedTelemetrySnapshot>.broadcast();
  @override
  Stream<NormalizedTelemetrySnapshot> get telemetryStream => _telemetryController.stream;

  final _dtcController = StreamController<List<DiagnosticTroubleCode>>.broadcast();
  @override
  Stream<List<DiagnosticTroubleCode>> get diagnosticCodesStream => _dtcController.stream;

  Timer? _generatorTimer;
  double _timeTicks = 0.0;
  List<DiagnosticTroubleCode> _currentDtcs = [];

  @override
  Future<bool> initialize() async {
    _linkState = DeviceLinkState.disconnected;
    return true;
  }

  @override
  Future<bool> connect(String targetIdentifier) async {
    _linkState = DeviceLinkState.connecting;
    _linkStateController.add(_linkState);

    await Future.delayed(const Duration(milliseconds: 150));
    _linkState = DeviceLinkState.connected;
    _linkStateController.add(_linkState);

    _startTelemetryGenerator();
    return true;
  }

  @override
  Future<void> disconnect() async {
    _generatorTimer?.cancel();
    _linkState = DeviceLinkState.disconnected;
    _linkStateController.add(_linkState);
  }

  @override
  Future<bool> clearDtcCodes() async {
    _currentDtcs.clear();
    _dtcController.add([]);
    return true;
  }

  @override
  Future<void> dispose() async {
    await disconnect();
    await _linkStateController.close();
    await _telemetryController.close();
    await _dtcController.close();
  }

  void _startTelemetryGenerator() {
    _generatorTimer?.cancel();
    _generatorTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _timeTicks += 0.1;
      final now = DateTime.now();

      final speed = 55.0 + 25.0 * math.sin(_timeTicks * 0.4);
      final rpm = (4000 + 3500 * math.sin(_timeTicks * 0.5)).toInt();
      final throttle = (40.0 + 30.0 * math.sin(_timeTicks * 0.5)).clamp(0.0, 100.0);
      final lean = 18.0 * math.sin(_timeTicks * 0.3);
      final gear = ((speed / 20.0).floor() + 1).clamp(1, 6);

      final snapshot = NormalizedTelemetrySnapshot(
        dataSource: TelemetryDataSource.simulated,
        timestamp: now,
        rssi: -45,
        packetLossPercentage: 0.0,
        vehicleSpeedKmh: TelemetryMetric(value: speed, unit: 'km/h', timestamp: now, confidence: MetricConfidence.simulated),
        engineRpm: TelemetryMetric(value: rpm, unit: 'RPM', timestamp: now, confidence: MetricConfidence.simulated),
        gearPosition: TelemetryMetric(value: gear, unit: 'Gear', timestamp: now, confidence: MetricConfidence.simulated),
        throttlePositionPct: TelemetryMetric(value: throttle, unit: '%', timestamp: now, confidence: MetricConfidence.simulated),
        engineLoadPct: TelemetryMetric(value: 48.0, unit: '%', timestamp: now, confidence: MetricConfidence.simulated),
        coolantTempC: TelemetryMetric(value: 86.5, unit: ' degC', timestamp: now, confidence: MetricConfidence.simulated),
        engineTempC: TelemetryMetric(value: 92.0, unit: ' degC', timestamp: now, confidence: MetricConfidence.simulated),
        intakeTempC: TelemetryMetric(value: 28.0, unit: ' degC', timestamp: now, confidence: MetricConfidence.simulated),
        batteryVoltage: TelemetryMetric(value: 13.8, unit: 'V', timestamp: now, confidence: MetricConfidence.simulated),
        batteryCurrentAmps: TelemetryMetric(value: 2.1, unit: 'A', timestamp: now, confidence: MetricConfidence.simulated),
        fuelLevelPct: TelemetryMetric(value: 78.0, unit: '%', timestamp: now, confidence: MetricConfidence.simulated),
        leanAngleDeg: TelemetryMetric(value: lean, unit: ' deg', timestamp: now, confidence: MetricConfidence.simulated),
        vibrationLevelG: TelemetryMetric(value: 0.28, unit: 'G', timestamp: now, confidence: MetricConfidence.simulated),
        accelerationX: TelemetryMetric(value: 0.05, unit: 'G', timestamp: now, confidence: MetricConfidence.simulated),
        accelerationY: TelemetryMetric(value: 0.12, unit: 'G', timestamp: now, confidence: MetricConfidence.simulated),
        accelerationZ: TelemetryMetric(value: 0.98, unit: 'G', timestamp: now, confidence: MetricConfidence.simulated),
        isIgnitionOn: true,
        ridingMode: 'DYNAMIC',
      );

      if (!_telemetryController.isClosed) {
        _telemetryController.add(snapshot);
      }
    });
  }
}
