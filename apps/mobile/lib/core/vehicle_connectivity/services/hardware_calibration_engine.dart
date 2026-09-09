import 'dart:async';
import '../models/hardware_calibration_models.dart';
import '../transports/vehicle_transport.dart';

class HardwareCalibrationEngine {
  static final HardwareCalibrationEngine _instance = HardwareCalibrationEngine._internal();
  factory HardwareCalibrationEngine() => _instance;

  VehicleTransport? _activeTransport;
  StreamSubscription<List<int>>? _packetSub;

  int _receivedCount = 0;
  int _lostCount = 0;
  int _malformedCount = 0;
  DateTime? _lastPacketTime;

  final _telemetryController = StreamController<CalibratedTelemetrySnapshot>.broadcast();
  Stream<CalibratedTelemetrySnapshot> get telemetryStream => _telemetryController.stream;

  CalibratedTelemetrySnapshot _currentSnapshot = CalibratedTelemetrySnapshot(
    speedKmh: 0,
    rpm: 0,
    batteryVoltage: 12.8,
    coolantTempCelsius: 85,
    fuelPercent: 80,
    validationMode: HardwareValidationMode.simulator,
    verificationStatus: HardwareVerificationStatus.unverified,
    sourceTag: 'SIMULATED',
    timestamp: DateTime.now(),
    metrics: const SignalCalibrationMetrics(),
  );
  CalibratedTelemetrySnapshot get currentSnapshot => _currentSnapshot;

  HardwareCalibrationEngine._internal();

  /// Attaches to a transport and begins real-time signal calibration
  void attachTransport(VehicleTransport transport, {
    HardwareValidationMode validationMode = HardwareValidationMode.simulator,
    HardwareVerificationStatus verificationStatus = HardwareVerificationStatus.unverified,
  }) {
    _packetSub?.cancel();
    _activeTransport = transport;
    _receivedCount = 0;
    _lostCount = 0;
    _malformedCount = 0;
    _lastPacketTime = null;

    _packetSub = _activeTransport!.rawPacketStream.listen((data) {
      _processRawFrame(
        data,
        validationMode: validationMode,
        verificationStatus: verificationStatus,
      );
    });
  }

  void _processRawFrame(List<int> frame, {
    required HardwareValidationMode validationMode,
    required HardwareVerificationStatus verificationStatus,
  }) {
    final now = DateTime.now();
    double freq = 10.0;
    int jitter = 3;

    if (_lastPacketTime != null) {
      final deltaMs = now.difference(_lastPacketTime!).inMilliseconds;
      if (deltaMs > 0) {
        freq = (1000.0 / deltaMs).clamp(0.1, 50.0);
        jitter = (deltaMs - 100).abs().clamp(0, 50);
      }
      if (deltaMs > 300) {
        _lostCount += ((deltaMs - 100) / 100).toInt().clamp(1, 10);
      }
    }
    _lastPacketTime = now;

    // Validate binary format: header 0xAA 0x55, length >= 10, checksum
    if (frame.length < 10 || frame[0] != 0xAA || frame[1] != 0x55) {
      _malformedCount++;
      _updateMetricsOnly(validationMode: validationMode, verificationStatus: verificationStatus, jitter: jitter, freq: freq);
      return;
    }

    int expectedChecksum = 0;
    for (int i = 2; i < 9; i++) {
      expectedChecksum ^= frame[i];
    }
    if (frame[9] != expectedChecksum) {
      _malformedCount++;
      _updateMetricsOnly(validationMode: validationMode, verificationStatus: verificationStatus, jitter: jitter, freq: freq);
      return;
    }

    _receivedCount++;

    final speed = frame[3].toDouble();
    final rpm = ((frame[4] << 8) | frame[5]).toDouble();
    final voltage = frame[6] / 10.0;
    final coolant = frame[7].toDouble();
    final fuel = frame[8].toDouble();

    final metrics = SignalCalibrationMetrics(
      rssi: validationMode == HardwareValidationMode.realDevice ? -68 : -50,
      latencyMs: validationMode == HardwareValidationMode.realDevice ? 28 : 8,
      jitterMs: jitter,
      notificationFrequencyHz: double.parse(freq.toStringAsFixed(1)),
      packetsReceived: _receivedCount,
      packetsLost: _lostCount,
      malformedPacketsCount: _malformedCount,
    );

    _currentSnapshot = CalibratedTelemetrySnapshot(
      speedKmh: speed,
      rpm: rpm,
      batteryVoltage: voltage,
      coolantTempCelsius: coolant,
      fuelPercent: fuel,
      activeDtcCodes: const [],
      validationMode: validationMode,
      verificationStatus: verificationStatus,
      sourceTag: validationMode == HardwareValidationMode.realDevice ? 'LIVE' : 'SIMULATED',
      timestamp: now,
      metrics: metrics,
    );

    if (!_telemetryController.isClosed) {
      _telemetryController.add(_currentSnapshot);
    }
  }

  void _updateMetricsOnly({
    required HardwareValidationMode validationMode,
    required HardwareVerificationStatus verificationStatus,
    required int jitter,
    required double freq,
  }) {
    final metrics = SignalCalibrationMetrics(
      rssi: validationMode == HardwareValidationMode.realDevice ? -68 : -50,
      latencyMs: validationMode == HardwareValidationMode.realDevice ? 28 : 8,
      jitterMs: jitter,
      notificationFrequencyHz: double.parse(freq.toStringAsFixed(1)),
      packetsReceived: _receivedCount,
      packetsLost: _lostCount,
      malformedPacketsCount: _malformedCount,
    );

    _currentSnapshot = CalibratedTelemetrySnapshot(
      speedKmh: _currentSnapshot.speedKmh,
      rpm: _currentSnapshot.rpm,
      batteryVoltage: _currentSnapshot.batteryVoltage,
      coolantTempCelsius: _currentSnapshot.coolantTempCelsius,
      fuelPercent: _currentSnapshot.fuelPercent,
      activeDtcCodes: _currentSnapshot.activeDtcCodes,
      validationMode: validationMode,
      verificationStatus: verificationStatus,
      sourceTag: validationMode == HardwareValidationMode.realDevice ? 'LIVE' : 'SIMULATED',
      timestamp: DateTime.now(),
      metrics: metrics,
    );

    if (!_telemetryController.isClosed) {
      _telemetryController.add(_currentSnapshot);
    }
  }

  void detach() {
    _packetSub?.cancel();
    _packetSub = null;
    _activeTransport = null;
  }
}
