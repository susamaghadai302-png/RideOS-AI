import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/hardware_calibration_models.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/hardware_calibration_engine.dart';
import 'mocks/mock_vehicle_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Hardware Calibration Engine & Field Diagnostics Tests', () {
    late HardwareCalibrationEngine engine;
    late MockVehicleTransport transport;

    setUp(() async {
      engine = HardwareCalibrationEngine();
      transport = MockVehicleTransport();
      await transport.initialize();
      await transport.connect('MOCK_TEST_BENCH');
      engine.attachTransport(
        transport,
        validationMode: HardwareValidationMode.simulator,
        verificationStatus: HardwareVerificationStatus.partiallyVerified,
      );
    });

    tearDown(() async {
      engine.detach();
      await transport.dispose();
    });

    test('Decodes valid binary telemetry frame with correct XOR checksum', () async {
      transport.injectValidFrame(
        speedKmh: 65,
        rpm: 6200,
        batteryVoltage: 13.8,
        coolantTemp: 90,
        fuelPct: 82,
      );

      await Future.delayed(const Duration(milliseconds: 50));
      final snap = engine.currentSnapshot;

      expect(snap.speedKmh, equals(65.0));
      expect(snap.rpm, equals(6200.0));
      expect(snap.batteryVoltage, equals(13.8));
      expect(snap.coolantTempCelsius, equals(90.0));
      expect(snap.fuelPercent, equals(82.0));
      expect(snap.sourceTag, equals('SIMULATED'));
      expect(snap.metrics.packetsReceived, equals(1));
      expect(snap.metrics.malformedPacketsCount, equals(0));
    });

    test('Rejects malformed frames and increments corruption count', () async {
      transport.injectMalformedFrame();

      await Future.delayed(const Duration(milliseconds: 50));
      final snap = engine.currentSnapshot;

      expect(snap.metrics.malformedPacketsCount, equals(1));
      expect(snap.metrics.packetsReceived, equals(0));
    });

    test('Source Classification: Marks LIVE when attached in realDevice mode', () async {
      engine.attachTransport(
        transport,
        validationMode: HardwareValidationMode.realDevice,
        verificationStatus: HardwareVerificationStatus.verified,
      );

      transport.injectValidFrame(
        speedKmh: 80,
        rpm: 7000,
        batteryVoltage: 14.1,
        coolantTemp: 85,
        fuelPct: 95,
      );

      await Future.delayed(const Duration(milliseconds: 50));
      final snap = engine.currentSnapshot;

      expect(snap.sourceTag, equals('LIVE'));
      expect(snap.validationMode, equals(HardwareValidationMode.realDevice));
      expect(snap.verificationStatus, equals(HardwareVerificationStatus.verified));
    });

    test('Signal Calibration: Calculates packet loss and link quality labels', () {
      const metrics = SignalCalibrationMetrics(
        rssi: -58,
        latencyMs: 18,
        jitterMs: 2,
        packetsReceived: 98,
        packetsLost: 2,
        malformedPacketsCount: 0,
      );

      expect(metrics.packetLossPercentage, equals(2.0));
      expect(metrics.signalQualityLabel, equals('EXCELLENT'));
    });
  });
}
