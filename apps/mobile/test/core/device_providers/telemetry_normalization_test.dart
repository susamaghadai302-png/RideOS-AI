import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/device_providers/models/normalized_telemetry_models.dart';
import 'package:rideos_mobile/core/device_providers/providers/obd2_provider.dart';

void main() {
  group('Phase 3 — Telemetry Normalization & OBD-II Parsing Tests', () {
    test('TelemetryMetric formats value and handles unavailable metrics', () {
      final validMetric = TelemetryMetric<double>(
        value: 13.8,
        unit: 'V',
        timestamp: DateTime.now(),
        confidence: MetricConfidence.validLive,
      );

      expect(validMetric.isLive, isTrue);
      expect(validMetric.formattedValue, equals('13.8'));
      expect(validMetric.formattedWithUnit, equals('13.8 V'));

      final unsuppMetric = TelemetryMetric<double>(
        value: null,
        unit: 'A',
        timestamp: DateTime.now(),
        confidence: MetricConfidence.unsupported,
      );

      expect(unsuppMetric.isAvailable, isFalse);
      expect(unsuppMetric.formattedValue, equals('--'));
    });

    test('Obd2Provider correctly parses Mode 01 PID 0C RPM and PID 0D Speed', () {
      // Hex: 41 0C 1A F8 -> ( (0x1A * 256) + 0xF8 ) / 4 = (6656 + 248) / 4 = 1726 RPM
      const rpmHex = '41 0C 1A F8';
      final parsedRpm = Obd2Provider.parseMode01Response(rpmHex);
      expect(parsedRpm['rpm'], equals(1726));

      // Hex: 41 0D 3E -> 0x3E = 62 km/h
      const speedHex = '41 0D 3E';
      final parsedSpeed = Obd2Provider.parseMode01Response(speedHex);
      expect(parsedSpeed['speedKmh'], equals(62.0));

      // Hex: 41 05 80 -> 0x80 (128) - 40 = 88°C
      const tempHex = '41 05 80';
      final parsedTemp = Obd2Provider.parseMode01Response(tempHex);
      expect(parsedTemp['coolantTempC'], equals(88.0));
    });

    test('DiagnosticTroubleCode model structures active vs cleared fault codes', () {
      final dtc = DiagnosticTroubleCode(
        code: 'P0300',
        subsystem: 'Powertrain / Ignition',
        description: 'Random / Multiple Cylinder Misfire Detected',
        severity: DtcSeverity.warning,
        firstDetectedAt: DateTime.now().subtract(const Duration(minutes: 10)),
        lastDetectedAt: DateTime.now(),
        isActive: true,
      );

      expect(dtc.code, equals('P0300'));
      expect(dtc.isActive, isTrue);
      expect(dtc.toJson()['severity'], equals('warning'));
    });
  });
}
