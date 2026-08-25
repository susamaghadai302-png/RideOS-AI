import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideos_mobile/features/auth/domain/entities/rider_entity.dart';
import 'package:rideos_mobile/features/vehicle_manager/presentation/providers/vehicle_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1 - Motorcycle Data Foundation & CRUD Tests', () {
    late VehicleNotifier notifier;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      notifier = VehicleNotifier();
    });

    test('Initial state has empty garage and null active motorcycle', () {
      expect(notifier.state.garage, isEmpty);
      expect(notifier.state.activeMotorcycle, isNull);
    });

    test('Add motorcycle adds bike and sets it as active if first', () {
      const bike = MotorcycleEntity(
        bikeId: 'bike_001',
        make: 'Yamaha',
        model: 'YZF-R1M',
        year: 2024,
        engineCC: 998,
        maxLeanAngleLimit: 58.0,
        isPrimary: true,
      );

      notifier.addMotorcycle(bike);

      expect(notifier.state.garage.length, 1);
      expect(notifier.state.activeMotorcycle?.bikeId, 'bike_001');
      expect(notifier.state.activeMotorcycle?.make, 'Yamaha');
    });

    test('Add second motorcycle preserves first active motorcycle', () {
      const bike1 = MotorcycleEntity(
        bikeId: 'bike_001',
        make: 'Yamaha',
        model: 'YZF-R1M',
        year: 2024,
        engineCC: 998,
        maxLeanAngleLimit: 58.0,
        isPrimary: true,
      );
      const bike2 = MotorcycleEntity(
        bikeId: 'bike_002',
        make: 'Ducati',
        model: 'Panigale V4 S',
        year: 2024,
        engineCC: 1103,
        maxLeanAngleLimit: 60.0,
        isPrimary: false,
      );

      notifier.addMotorcycle(bike1);
      notifier.addMotorcycle(bike2);

      expect(notifier.state.garage.length, 2);
      expect(notifier.state.activeMotorcycle?.bikeId, 'bike_001');
    });

    test('Select active motorcycle switches active bike atomically', () {
      const bike1 = MotorcycleEntity(
        bikeId: 'bike_001',
        make: 'Yamaha',
        model: 'YZF-R1M',
        year: 2024,
        engineCC: 998,
        maxLeanAngleLimit: 58.0,
        isPrimary: true,
      );
      const bike2 = MotorcycleEntity(
        bikeId: 'bike_002',
        make: 'Ducati',
        model: 'Panigale V4 S',
        year: 2024,
        engineCC: 1103,
        maxLeanAngleLimit: 60.0,
        isPrimary: false,
      );

      notifier.addMotorcycle(bike1);
      notifier.addMotorcycle(bike2);

      notifier.selectActiveMotorcycle('bike_002');
      expect(notifier.state.activeMotorcycle?.bikeId, 'bike_002');
      expect(notifier.state.activeMotorcycle?.model, 'Panigale V4 S');
    });

    test('Update motorcycle updates bike details correctly', () {
      const bike1 = MotorcycleEntity(
        bikeId: 'bike_001',
        make: 'Yamaha',
        model: 'YZF-R1M',
        year: 2024,
        engineCC: 998,
        maxLeanAngleLimit: 58.0,
        isPrimary: true,
      );

      notifier.addMotorcycle(bike1);

      final updated = bike1.copyWith(frontPsi: 34.0, rearPsi: 40.0);
      notifier.updateMotorcycle(updated);

      expect(notifier.state.activeMotorcycle?.frontPsi, 34.0);
      expect(notifier.state.activeMotorcycle?.rearPsi, 40.0);
    });

    test('Delete motorcycle removes bike and reassigns active motorcycle', () {
      const bike1 = MotorcycleEntity(
        bikeId: 'bike_001',
        make: 'Yamaha',
        model: 'YZF-R1M',
        year: 2024,
        engineCC: 998,
        maxLeanAngleLimit: 58.0,
        isPrimary: true,
      );
      const bike2 = MotorcycleEntity(
        bikeId: 'bike_002',
        make: 'Ducati',
        model: 'Panigale V4 S',
        year: 2024,
        engineCC: 1103,
        maxLeanAngleLimit: 60.0,
        isPrimary: false,
      );

      notifier.addMotorcycle(bike1);
      notifier.addMotorcycle(bike2);

      notifier.deleteMotorcycle('bike_001');

      expect(notifier.state.garage.length, 1);
      expect(notifier.state.activeMotorcycle?.bikeId, 'bike_002');
    });
  });
}
