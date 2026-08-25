import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_health/models/vehicle_health_state.dart';
import 'package:rideos_mobile/core/vehicle_health/models/diagnostic_item.dart';
import 'package:rideos_mobile/core/vehicle_health/models/vehicle_alert_model.dart';
import 'package:rideos_mobile/core/vehicle_health/services/diagnostic_manager.dart';
import 'package:rideos_mobile/core/vehicle_health/services/maintenance_manager.dart';
import 'package:rideos_mobile/core/vehicle_health/services/vehicle_alert_engine.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Diagnostic Manager & DTC Engine Tests', () {
    test('Correctly identifies known SAE DTC codes and severities', () {
      final manager = DiagnosticManager();

      final p0300 = manager.recordFaultCode('P0300');
      expect(p0300.code, 'P0300');
      expect(p0300.description, 'Random/Multiple Cylinder Misfire Detected');
      expect(p0300.severity, DiagnosticSeverity.critical);
      expect(p0300.active, isTrue);

      final p0117 = manager.recordFaultCode('P0117');
      expect(p0117.code, 'P0117');
      expect(p0117.description, 'Engine Coolant Temperature Circuit Low Input');
      expect(p0117.severity, DiagnosticSeverity.warning);
    });

    test('Never invents descriptions for unknown DTC codes', () {
      final manager = DiagnosticManager();

      final unknown = manager.recordFaultCode('P9999');
      expect(unknown.code, 'P9999');
      expect(unknown.description, 'Unknown diagnostic code — manufacturer documentation required.');
      expect(unknown.severity, DiagnosticSeverity.notice);
    });
  });

  group('Maintenance Manager & Scheduling Tests', () {
    test('Calculates due and overdue service items based on odometer', () {
      final manager = MaintenanceManager();
      manager.setUserOdometer(5200); // 5,200 km
      expect(manager.isVehicleOdometer, isFalse);

      const profile = VehicleProfile(
        id: 'test_bike',
        manufacturer: 'Yamaha',
        model: 'R1',
        variant: 'M',
        year: 2024,
        category: 'Superbike',
        engineType: '998cc CP4',
        fuelType: 'Petrol',
        protocolAdapter: 'yamaha_y_connect',
        model3DUrl: '',
        thumbnailUrl: 'assets/garage/yamaha_r1m.png',
        maintenanceIntervals: {
          'engine_oil': {'km': 5000, 'months': 6, 'description': 'Engine Oil & Filter'},
        },
      );

      final schedule = manager.getSchedule(profile);
      expect(schedule.length, 1);
      expect(schedule.first.serviceType, 'engine_oil');
      expect(schedule.first.status, ServiceStatus.overdue); // 5200 > 5000
    });
  });

  group('Vehicle Alert Engine Tests', () {
    test('Enforces cooldown on non-critical duplicate alerts', () {
      final engine = VehicleAlertEngine();

      final alert1 = engine.triggerAlert(
        alertKey: 'TEST_LOW_BATT',
        title: 'Low Battery',
        message: 'Voltage is 11.5V',
        severity: AlertSeverity.warning,
      );
      expect(alert1, isNotNull);

      // Triggering immediately again within 60s cooldown returns null (deduplicated)
      final alert2 = engine.triggerAlert(
        alertKey: 'TEST_LOW_BATT',
        title: 'Low Battery',
        message: 'Voltage is 11.5V',
        severity: AlertSeverity.warning,
      );
      expect(alert2, isNull);

      // Critical alerts bypass cooldown
      final crit = engine.triggerAlert(
        alertKey: 'TEST_OVERHEAT',
        title: 'Overheat',
        message: 'Temp 120°C',
        severity: AlertSeverity.critical,
      );
      expect(crit, isNotNull);
    });
  });

  group('Vehicle Health State Logic Tests', () {
    test('CategoryHealthState marks missing telemetry as insufficientData instead of fake health score', () {
      final empty = VehicleHealthState.empty();
      final engineState = empty.getCategory(HealthCategory.engine);

      expect(engineState.severity, HealthSeverity.insufficientData);
      expect(engineState.statusText, 'Insufficient Data');
      expect(engineState.hasLiveTelemetry, isFalse);
    });
  });
}
