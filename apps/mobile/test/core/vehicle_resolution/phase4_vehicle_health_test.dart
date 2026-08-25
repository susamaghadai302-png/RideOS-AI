import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/normalized_telemetry.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/telemetry_value.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/telemetry_health_monitor.dart';

void main() {
  group('Phase 4 - Vehicle Health & Bounds Validation Tests', () {
    late TelemetryHealthMonitor monitor;

    setUp(() {
      monitor = TelemetryHealthMonitor();
    });

    test('Valid physical telemetry passes validation with no anomalies', () {
      final telemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue<double>(value: 85.0, available: true),
        rpm: TelemetryValue<int>(value: 6200, available: true),
        batteryVoltage: TelemetryValue<double>(value: 13.6, available: true),
        engineTemperature: TelemetryValue<int>(value: 88, available: true),
      );

      final result = monitor.validate(telemetry);
      expect(result.isValid, isTrue);
      expect(result.anomalies, isEmpty);
    });

    test('Out-of-range physical telemetry triggers anomaly detection', () {
      final telemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue<double>(value: 450.0, available: true), // Out of 0-400 range
        rpm: TelemetryValue<int>(value: 28000, available: true), // Out of 0-22000 range
        batteryVoltage: TelemetryValue<double>(value: 24.0, available: true), // Out of 5-18V range
      );

      final result = monitor.validate(telemetry);
      expect(result.isValid, isFalse);
      expect(result.anomalies.length, 3);
      expect(result.anomalies.first, contains('Physical speed anomaly'));
    });
  });
}
