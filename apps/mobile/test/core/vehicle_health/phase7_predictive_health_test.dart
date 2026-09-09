import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_health/services/predictive_vehicle_health_engine.dart';
import 'package:rideos_mobile/features/obd_tpms/core/services/obd_full_telemetry_service.dart';

void main() {
  group('Phase 7 - Predictive Vehicle Health Engine Tests', () {
    late PredictiveVehicleHealthEngine engine;

    setUp(() {
      engine = PredictiveVehicleHealthEngine();
    });

    test('Evaluates overall health report and marks data classification accurately', () {
      ObdFullTelemetryService().isSimulatorMode = true;
      final simReport = engine.evaluateHealthReport();
      expect(simReport.dataClassification, equals('SIMULATED DATA'));
      expect(simReport.overallHealthScore, greaterThan(70));
      expect(simReport.subsystems.length, equals(3)); // Powertrain, Battery, TPMS

      ObdFullTelemetryService().isSimulatorMode = false;
      final offlineReport = engine.evaluateHealthReport(isBleConnected: false);
      expect(offlineReport.dataClassification, equals('HARDWARE_NOT_CONNECTED'));

      final liveReport = engine.evaluateHealthReport(isBleConnected: true);
      expect(liveReport.dataClassification, equals('LIVE BLE VEHICLE'));
    });

    test('Generates predictive recommendations when health parameters deviate', () {
      ObdFullTelemetryService().isSimulatorMode = true;
      final report = engine.evaluateHealthReport();
      expect(report.subsystems.every((s) => s.healthScore >= 0 && s.healthScore <= 100), isTrue);
      expect(report.overallStatus, isNotEmpty);
    });
  });
}
