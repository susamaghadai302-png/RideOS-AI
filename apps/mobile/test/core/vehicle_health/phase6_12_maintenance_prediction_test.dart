import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideos_mobile/core/vehicle_health/services/maintenance_manager.dart';
import 'package:rideos_mobile/core/vehicle_health/models/maintenance_record_model.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 6.12 - Advanced Vehicle Maintenance Prediction Tests', () {
    test('1. Predicts insufficient data explicitly when odometer is 0 or unavailable', () {
      final manager = MaintenanceManager();
      // Use reflection or just test behavior via getSchedule since userOdometer is initially 0
      manager.setUserOdometer(0.0);

      final schedule = manager.getSchedule(null); // use generic intervals
      
      final engineOil = schedule.firstWhere((s) => s.serviceType == 'engine_oil');
      expect(engineOil.status, ServiceStatus.insufficientData);
      expect(engineOil.statusDetail, 'Waiting for Odometer');
      expect(engineOil.explanation, contains('Cannot predict service'));
    });

    test('2. Predicts generic intervals accurately using elapsed time and distance', () {
      final manager = MaintenanceManager();
      manager.setUserOdometer(4500.0); // Close to 5000km

      final schedule = manager.getSchedule(null); 
      
      final engineOil = schedule.firstWhere((s) => s.serviceType == 'engine_oil');
      expect(engineOil.status, ServiceStatus.dueSoon);
      expect(engineOil.statusDetail, 'Due in 500 km');
      expect(engineOil.isGenericEstimate, isTrue);
      expect(engineOil.explanation, contains('generic estimates'));
      expect(engineOil.explanation, contains('Approaching distance limit of 5000 km'));

      final brakeFluid = schedule.firstWhere((s) => s.serviceType == 'brake_fluid');
      expect(brakeFluid.status, ServiceStatus.ok); // 20000km interval
    });

    test('3. Evaluates custom vehicle profile intervals correctly', () {
      final manager = MaintenanceManager();
      manager.setUserOdometer(11500.0);

      const profile = VehicleProfile(
        id: 'v1',
        manufacturer: 'Ducati',
        model: 'Panigale V4',
        year: 2024,
        category: 'Motorcycle',
        protocolAdapter: 'ble',
        model3DUrl: '',
        thumbnailUrl: '',
        maintenanceIntervals: {
          'desmo_service': {'km': 12000, 'months': 36, 'description': 'Desmo Valve Clearance Check'},
        }
      );

      final schedule = manager.getSchedule(profile); 
      
      final desmo = schedule.firstWhere((s) => s.serviceType == 'desmo_service');
      expect(desmo.status, ServiceStatus.dueSoon);
      expect(desmo.isGenericEstimate, isFalse);
      expect(desmo.explanation, isNot(contains('generic estimates')));
    });

    test('4. Overdue states accurately calculate exceeded distance', () {
      final manager = MaintenanceManager();
      manager.setUserOdometer(5500.0); // 500km over the 5000km limit

      final schedule = manager.getSchedule(null); 
      final engineOil = schedule.firstWhere((s) => s.serviceType == 'engine_oil');
      expect(engineOil.status, ServiceStatus.overdue);
      expect(engineOil.statusDetail, 'Overdue by 500 km');
    });

    test('5. Confirmed service reset extends prediction interval securely', () async {
      final manager = MaintenanceManager();
      // No ref for test, initialize bypasses it since we catch errors gracefully in manager
      manager.setUserOdometer(6000.0); 
      
      final record = MaintenanceRecordModel(
        id: 'rec1',
        vehicleId: 'v1',
        serviceType: 'engine_oil',
        date: DateTime.now(),
        odometerKm: 5800.0,
      );

      await manager.addServiceRecord(record);

      final schedule = manager.getSchedule(null); 
      final engineOil = schedule.firstWhere((s) => s.serviceType == 'engine_oil');
      
      // Since it was changed at 5800, next due is 10800. Current is 6000, so kmSinceService = 200. kmUntilDue = 4800.
      expect(engineOil.status, ServiceStatus.ok);
      expect(engineOil.statusDetail, contains('Due in 4800 km'));
    });

    test('6. Duplicate records resolve gracefully to most recent', () async {
      final manager = MaintenanceManager();
      manager.setUserOdometer(8000.0); 
      
      final oldRecord = MaintenanceRecordModel(
        id: 'rec_old',
        vehicleId: 'v1',
        serviceType: 'tyre_inspection',
        date: DateTime.now().subtract(const Duration(days: 30)),
        odometerKm: 3000.0,
      );

      final newRecord = MaintenanceRecordModel(
        id: 'rec_new',
        vehicleId: 'v1',
        serviceType: 'tyre_inspection',
        date: DateTime.now(),
        odometerKm: 7500.0,
      );

      // Add old then new. Manager inserts at 0, so newest is first.
      await manager.addServiceRecord(oldRecord);
      await manager.addServiceRecord(newRecord);

      final schedule = manager.getSchedule(null); 
      final tyre = schedule.firstWhere((s) => s.serviceType == 'tyre_inspection');
      
      // Tyre inspection interval is 1000km. Last done at 7500. Current 8000. kmSince = 500. kmUntilDue = 500. -> Due soon.
      expect(tyre.status, ServiceStatus.dueSoon);
      expect(tyre.lastPerformedKm, 7500.0);
    });
  });
}
