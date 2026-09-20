import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/hardware_calibration_models.dart';
import '../services/structured_hardware_diagnostic_logger.dart';

enum BleStreamScenario {
  stableConnection,
  weakSignal,
  packetLoss,
  reconnect,
  malformedPacket,
  unsupportedCharacteristic,
  unknownVehicle,
  knownVehicleProfile,
}

@immutable
class BleTuningSessionState {
  final BleStreamScenario activeScenario;
  final bool isStreaming;
  final int mtu;
  final int rssi;
  final double notificationFrequencyHz;
  final int packetsReceived;
  final int packetsDropped;
  final int malformedPackets;
  final bool isSubscribedToCharacteristics;
  final String activeServiceUuid;
  final String activeCharacteristicUuid;
  final String vehicleProfileLabel;
  final String protocolVerificationLabel;
  final CalibratedTelemetrySnapshot telemetry;

  const BleTuningSessionState({
    required this.activeScenario,
    this.isStreaming = false,
    this.mtu = 185,
    this.rssi = -60,
    this.notificationFrequencyHz = 10.0,
    this.packetsReceived = 0,
    this.packetsDropped = 0,
    this.malformedPackets = 0,
    this.isSubscribedToCharacteristics = true,
    this.activeServiceUuid = '0000fee0-0000-1000-8000-00805f9b34fb',
    this.activeCharacteristicUuid = '0000fee1-0000-1000-8000-00805f9b34fb',
    this.vehicleProfileLabel = 'Yamaha YZF-R15M (Top Premium TFT)',
    this.protocolVerificationLabel = 'Verified Y-Connect CCU Protocol',
    required this.telemetry,
  });

  double get packetLossPercent {
    final total = packetsReceived + packetsDropped;
    if (total == 0) return 0.0;
    return (packetsDropped / total) * 100.0;
  }
}

class BleCharacteristicTuningEngine {
  static final BleCharacteristicTuningEngine _instance = BleCharacteristicTuningEngine._internal();
  factory BleCharacteristicTuningEngine() => _instance;

  Timer? _scenarioTimer;
  int _counter = 0;
  final _logger = StructuredHardwareDiagnosticLogger();

  final _sessionController = StreamController<BleTuningSessionState>.broadcast();
  Stream<BleTuningSessionState> get sessionStream => _sessionController.stream;

  BleTuningSessionState _currentState = BleTuningSessionState(
    activeScenario: BleStreamScenario.stableConnection,
    telemetry: CalibratedTelemetrySnapshot(
      speedKmh: 0,
      rpm: 0,
      batteryVoltage: 0.0,
      coolantTempCelsius: 0,
      fuelPercent: 0,
      validationMode: HardwareValidationMode.production,
      verificationStatus: HardwareVerificationStatus.unverified,
      sourceTag: 'UNAVAILABLE',
      timestamp: DateTime.now(),
      metrics: const SignalCalibrationMetrics(),
    ),
  );
  BleTuningSessionState get currentState => _currentState;

  BleCharacteristicTuningEngine._internal();

  /// Starts streaming telemetry for the given scenario
  void startScenario(BleStreamScenario scenario) {
    _scenarioTimer?.cancel();
    _counter = 0;

    int targetMtu = 185;
    int targetRssi = -58;
    String profile = 'Yamaha YZF-R15M (Top Premium TFT)';
    String verification = 'Verified Y-Connect CCU Protocol';
    bool subscribed = true;

    switch (scenario) {
      case BleStreamScenario.weakSignal:
        targetRssi = -88;
        break;
      case BleStreamScenario.unsupportedCharacteristic:
        subscribed = false;
        profile = 'Unsupported GATT Device';
        verification = 'Detected — Protocol Not Verified';
        break;
      case BleStreamScenario.unknownVehicle:
        targetMtu = 23;
        profile = 'Unknown Two-Wheeler';
        verification = 'Detected — Protocol Not Verified';
        break;
      case BleStreamScenario.knownVehicleProfile:
        profile = 'Royal Enfield Himalayan 450 (Tripper TFT)';
        verification = 'Verified Tripper GATT Protocol';
        break;
      default:
        break;
    }

    _logger.log(
      eventType: DiagnosticEventType.connectionStateChange,
      severity: DiagnosticSeverity.info,
      deviceId: 'BLE_SIM_DEV_01',
      message: 'Started BLE characteristic tuning scenario: ${scenario.name}',
      metadata: {'mtu': targetMtu, 'rssi': targetRssi},
    );

    _currentState = BleTuningSessionState(
      activeScenario: scenario,
      isStreaming: true,
      mtu: targetMtu,
      rssi: targetRssi,
      isSubscribedToCharacteristics: subscribed,
      vehicleProfileLabel: profile,
      protocolVerificationLabel: verification,
      telemetry: _currentState.telemetry,
    );
    _emitState();

    _scenarioTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      _tickScenario();
    });
  }

  void _tickScenario() {
    _counter++;
    final scenario = _currentState.activeScenario;

    int dropped = _currentState.packetsDropped;
    int malformed = _currentState.malformedPackets;
    int received = _currentState.packetsReceived;
    int rssi = _currentState.rssi;

    if (scenario == BleStreamScenario.packetLoss && _counter % 5 == 0) {
      dropped++;
      _logger.log(
        eventType: DiagnosticEventType.packetLossDetected,
        severity: DiagnosticSeverity.warning,
        deviceId: 'BLE_SIM_DEV_01',
        message: 'Packet dropped during tuning simulation',
      );
    } else if (scenario == BleStreamScenario.malformedPacket && _counter % 4 == 0) {
      malformed++;
    } else {
      received++;
    }

    if (scenario == BleStreamScenario.weakSignal) {
      rssi = -85 - (_counter % 5);
    }

    final double speed = 0.0;
    final double rpm = 0.0;

    final metrics = SignalCalibrationMetrics(
      rssi: rssi,
      latencyMs: scenario == BleStreamScenario.weakSignal ? 65 : 18,
      jitterMs: scenario == BleStreamScenario.weakSignal ? 12 : 2,
      notificationFrequencyHz: 10.0,
      packetsReceived: received,
      packetsLost: dropped,
      malformedPacketsCount: malformed,
    );

    final telemetry = CalibratedTelemetrySnapshot(
      speedKmh: speed,
      rpm: rpm,
      batteryVoltage: 0.0,
      coolantTempCelsius: 0,
      fuelPercent: 0,
      validationMode: HardwareValidationMode.production,
      verificationStatus: HardwareVerificationStatus.unverified,
      sourceTag: 'UNAVAILABLE',
      timestamp: DateTime.now(),
      metrics: metrics,
    );

    _currentState = BleTuningSessionState(
      activeScenario: scenario,
      isStreaming: true,
      mtu: _currentState.mtu,
      rssi: rssi,
      notificationFrequencyHz: 10.0,
      packetsReceived: received,
      packetsDropped: dropped,
      malformedPackets: malformed,
      isSubscribedToCharacteristics: _currentState.isSubscribedToCharacteristics,
      activeServiceUuid: _currentState.activeServiceUuid,
      activeCharacteristicUuid: _currentState.activeCharacteristicUuid,
      vehicleProfileLabel: _currentState.vehicleProfileLabel,
      protocolVerificationLabel: _currentState.protocolVerificationLabel,
      telemetry: telemetry,
    );
    _emitState();
  }

  void stopScenario() {
    _scenarioTimer?.cancel();
    _scenarioTimer = null;
    _currentState = BleTuningSessionState(
      activeScenario: _currentState.activeScenario,
      isStreaming: false,
      mtu: _currentState.mtu,
      rssi: _currentState.rssi,
      packetsReceived: _currentState.packetsReceived,
      packetsDropped: _currentState.packetsDropped,
      malformedPackets: _currentState.malformedPackets,
      isSubscribedToCharacteristics: _currentState.isSubscribedToCharacteristics,
      activeServiceUuid: _currentState.activeServiceUuid,
      activeCharacteristicUuid: _currentState.activeCharacteristicUuid,
      vehicleProfileLabel: _currentState.vehicleProfileLabel,
      protocolVerificationLabel: _currentState.protocolVerificationLabel,
      telemetry: _currentState.telemetry,
    );
    _emitState();
  }

  void _emitState() {
    if (!_sessionController.isClosed) {
      _sessionController.add(_currentState);
    }
  }
}
