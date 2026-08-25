import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/ai_assistant/core/services/ai_copilot_engine.dart';
import 'package:rideos_mobile/features/ai_assistant/domain/entities/ai_vehicle_alert_entity.dart';
import 'package:rideos_mobile/features/obd_tpms/core/services/obd_full_telemetry_service.dart';

void main() {
  group('Phase 5 - AI Co-Pilot & Safety Alert Engine Tests', () {
    late AiCopilotEngine copilot;

    setUp(() {
      copilot = AiCopilotEngine();
      copilot.clearAlerts();
    });

    test('Assembles current riding context accurately in Real BLE vs Simulator mode', () {
      // In simulator mode
      ObdFullTelemetryService().isSimulatorMode = true;
      final simContext = copilot.getCurrentContext();
      expect(simContext.isSimulated, isTrue);
      expect(simContext.dataSource, equals(TelemetryDataSource.simulatorDemo));
      expect(simContext.summaryDescription, contains('[SIMULATED]'));

      // In real BLE mode (disconnected)
      ObdFullTelemetryService().isSimulatorMode = false;
      final realContext = copilot.getCurrentContext(isBleConnected: false);
      expect(realContext.isSimulated, isFalse);
      expect(realContext.isConnected, isFalse);
      expect(realContext.summaryDescription, contains('[OFFLINE]'));
    });

    test('Evaluates and triggers critical alert when coolant temperature exceeds 105°C', () {
      final highTempContext = AiCopilotRidingContext(
        coolantTempC: 112.0,
        currentSpeedKmH: 80.0,
        batteryVoltage: 13.6,
        engineRpm: 6000,
        dataSource: TelemetryDataSource.simulatorDemo,
        isConnected: true,
        activeVehicleName: 'Yamaha YZF-R1M',
        timestamp: DateTime.now(),
      );

      copilot.evaluateTelemetryForAlerts(highTempContext);
      expect(copilot.alertHistory.length, equals(1));
      expect(copilot.alertHistory.first.severity, equals(AlertSeverity.critical));
      expect(copilot.alertHistory.first.title, contains('High Engine Temperature'));
      expect(copilot.alertHistory.first.isAcknowledged, isFalse);

      // Acknowledge alert
      copilot.acknowledgeAlert(copilot.alertHistory.first.id);
      expect(copilot.unacknowledgedAlerts.isEmpty, isTrue);
    });

    test('Evaluates and triggers warning alert when battery voltage is below 11.8V', () {
      final lowBatteryContext = AiCopilotRidingContext(
        batteryVoltage: 11.2,
        currentSpeedKmH: 0.0,
        engineRpm: 0,
        dataSource: TelemetryDataSource.simulatorDemo,
        isConnected: true,
        activeVehicleName: 'Yamaha YZF-R1M',
        timestamp: DateTime.now(),
      );

      copilot.evaluateTelemetryForAlerts(lowBatteryContext);
      expect(copilot.alertHistory.any((a) => a.title == 'Low Battery Voltage'), isTrue);
      expect(copilot.alertHistory.first.severity, equals(AlertSeverity.warning));
    });

    test('Generates sensible telemetry responses without fabricating missing values', () {
      ObdFullTelemetryService().isSimulatorMode = true;
      final speedResp = copilot.generateTelemetryQueryResponse('speed');
      expect(speedResp, contains('km/h'));
      expect(speedResp, contains('(Simulated)'));

      final batteryResp = copilot.generateTelemetryQueryResponse('battery');
      expect(batteryResp, contains('Volts'));

      final alertsResp = copilot.generateTelemetryQueryResponse('alerts');
      expect(alertsResp, isNotEmpty);
    });
  });
}
