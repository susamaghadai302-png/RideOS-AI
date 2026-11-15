import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/maintenance/domain/entities/maintenance_log_entity.dart';

void main() {
  group('MaintenanceLogEntity Tests', () {
    test('MaintenanceLogEntity serialization to/from JSON preserves all fields', () {
      final now = DateTime.utc(2026, 11, 15, 12, 0, 0);
      final nextDue = DateTime.utc(2027, 5, 15, 12, 0, 0);

      final log = MaintenanceLogEntity(
        id: 'log-101',
        bikeId: 'bike-alpha',
        taskType: MaintenanceTaskTypes.oilChange,
        performedAtKm: 12000,
        performedAtDate: now,
        nextDueKm: 17000,
        nextDueDate: nextDue,
        notes: 'Replaced oil filter & Motul 7100 10W-50',
        isCompleted: true,
        cost: 65.5,
        serviceProvider: 'Apex Moto Garage',
      );

      final json = log.toJson();
      expect(json['id'], 'log-101');
      expect(json['bikeId'], 'bike-alpha');
      expect(json['taskType'], MaintenanceTaskTypes.oilChange);
      expect(json['performedAtKm'], 12000);
      expect(json['nextDueKm'], 17000);
      expect(json['cost'], 65.5);
      expect(json['serviceProvider'], 'Apex Moto Garage');

      final deserialized = MaintenanceLogEntity.fromJson(json);
      expect(deserialized, equals(log));
      expect(deserialized.notes, contains('Motul 7100'));
    });

    test('MaintenanceTaskTypes returns proper display names and default intervals', () {
      expect(MaintenanceTaskTypes.getDisplayName(MaintenanceTaskTypes.oilChange),
          'Engine Oil & Filter Change');
      expect(MaintenanceTaskTypes.getDisplayName(MaintenanceTaskTypes.chainLube),
          'Drive Chain Clean & Lube');
      expect(MaintenanceTaskTypes.getDefaultIntervalKm(MaintenanceTaskTypes.chainLube), 500);
      expect(MaintenanceTaskTypes.getDefaultIntervalKm(MaintenanceTaskTypes.oilChange), 5000);
      expect(MaintenanceTaskTypes.getDefaultIntervalKm(MaintenanceTaskTypes.sparkPlugs), 12000);
    });
  });

  group('MaintenanceScheduleEntity Tests', () {
    test('Calculates progress ratio and due distance correctly', () {
      const schedule = MaintenanceScheduleEntity(
        taskType: MaintenanceTaskTypes.oilChange,
        title: 'Engine Oil & Filter Change',
        intervalKm: 5000,
        lastPerformedKm: 10000,
        currentOdometerKm: 13500,
        dueInKm: 1500,
        status: MaintenanceScheduleStatus.optimal,
        statusDetail: 'Optimal (Due in 1500 km)',
        recommendation: 'In good standing.',
      );

      // (13500 - 10000) / 5000 = 3500 / 5000 = 0.70
      expect(schedule.progressRatio, closeTo(0.70, 0.01));
      expect(schedule.status, MaintenanceScheduleStatus.optimal);
    });

    test('Progress ratio clamps to 1.0 when overdue', () {
      const schedule = MaintenanceScheduleEntity(
        taskType: MaintenanceTaskTypes.chainLube,
        title: 'Drive Chain Clean & Lube',
        intervalKm: 500,
        lastPerformedKm: 5000,
        currentOdometerKm: 5600,
        dueInKm: -100,
        status: MaintenanceScheduleStatus.overdue,
        statusDetail: 'Overdue by 100 km',
        recommendation: 'Clean chain promptly.',
      );

      expect(schedule.progressRatio, equals(1.0));
      expect(schedule.status, MaintenanceScheduleStatus.overdue);
    });
  });
}
