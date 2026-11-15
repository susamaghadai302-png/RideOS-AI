import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/maintenance/domain/entities/maintenance_log_entity.dart';
import 'package:rideos_mobile/features/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:rideos_mobile/features/maintenance/presentation/providers/maintenance_notifier.dart';

class MockMaintenanceRepository implements MaintenanceRepository {
  List<MaintenanceLogEntity> inMemoryLogs = [];

  @override
  Future<List<MaintenanceLogEntity>> getLogsForBike(String bikeId) async {
    return inMemoryLogs.where((l) => l.bikeId == bikeId).toList();
  }

  @override
  Future<MaintenanceLogEntity> logTask(
    MaintenanceLogEntity task, {
    int? intervalKm,
  }) async {
    inMemoryLogs.add(task);
    return task;
  }

  @override
  Future<void> deleteLog(String logId, String bikeId) async {
    inMemoryLogs.removeWhere((l) => l.id == logId && l.bikeId == bikeId);
  }
}

void main() {
  group('MaintenanceNotifier Tests', () {
    late MockMaintenanceRepository mockRepo;
    late MaintenanceNotifier notifier;

    setUp(() {
      mockRepo = MockMaintenanceRepository();
      notifier = MaintenanceNotifier(repository: mockRepo);
    });

    test('Initial state is empty and not loading', () {
      expect(notifier.state.tasks, isEmpty);
      expect(notifier.state.schedules, isEmpty);
      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.errorMessage, isNull);
    });

    test('loadTasksForBike fetches logs and calculates schedule urgency', () async {
      final now = DateTime.now();
      mockRepo.inMemoryLogs = [
        MaintenanceLogEntity(
          id: 'log-1',
          bikeId: 'bike-123',
          taskType: MaintenanceTaskTypes.chainLube,
          performedAtKm: 4500,
          performedAtDate: now.subtract(const Duration(days: 10)),
          nextDueKm: 5000,
          notes: 'Lube applied',
        ),
        MaintenanceLogEntity(
          id: 'log-2',
          bikeId: 'bike-123',
          taskType: MaintenanceTaskTypes.oilChange,
          performedAtKm: 0,
          performedAtDate: now.subtract(const Duration(days: 60)),
          nextDueKm: 5000,
          notes: 'Break-in service',
        ),
      ];

      // Current odometer is 5100 km -> chainLube (4500 + 500 = 5000) is OVERDUE by 100 km!
      await notifier.loadTasksForBike('bike-123', currentOdometerKm: 5100);

      expect(notifier.state.isLoading, isFalse);
      expect(notifier.state.tasks.length, 2);
      expect(notifier.state.schedules, isNotEmpty);
      expect(notifier.state.currentOdometerKm, 5100);

      // Verify chain lube is overdue
      final chainSchedule = notifier.state.schedules
          .firstWhere((s) => s.taskType == MaintenanceTaskTypes.chainLube);
      expect(chainSchedule.status, MaintenanceScheduleStatus.overdue);
      expect(chainSchedule.dueInKm, -100);

      // Verify oil change (0 + 5000 = 5000) is also overdue at 5100 km
      final oilSchedule = notifier.state.schedules
          .firstWhere((s) => s.taskType == MaintenanceTaskTypes.oilChange);
      expect(oilSchedule.status, MaintenanceScheduleStatus.overdue);

      expect(notifier.state.hasUrgentMaintenance, isTrue);
    });

    test('addMaintenanceTask rejects invalid negative odometer', () async {
      final invalidLog = MaintenanceLogEntity(
        id: 'log-err',
        bikeId: 'bike-123',
        taskType: MaintenanceTaskTypes.oilChange,
        performedAtKm: -50,
        performedAtDate: DateTime.now(),
        nextDueKm: 4950,
        notes: 'Negative odometer',
      );

      final result = await notifier.addMaintenanceTask(invalidLog);
      expect(result, isFalse);
      expect(notifier.state.errorMessage, contains('negative'));
      expect(notifier.state.tasks, isEmpty);
    });

    test('addMaintenanceTask successfully logs task and recalculates schedule', () async {
      notifier.updateCurrentOdometer(5000);

      final newLog = MaintenanceLogEntity(
        id: 'log-fresh',
        bikeId: 'bike-123',
        taskType: MaintenanceTaskTypes.chainLube,
        performedAtKm: 5000,
        performedAtDate: DateTime.now(),
        nextDueKm: 5500,
        cost: 20.0,
        serviceProvider: 'Self-serviced',
        notes: 'Motul C2 lube',
      );

      final result = await notifier.addMaintenanceTask(newLog, intervalKm: 500);
      expect(result, isTrue);
      expect(notifier.state.tasks.length, 1);
      expect(notifier.state.totalMaintenanceCost, 20.0);
      expect(notifier.state.successMessage, isNotNull);

      // Now chain lube is performed at 5000, odometer is 5000 -> optimal, due in 500 km!
      final chainSchedule = notifier.state.schedules
          .firstWhere((s) => s.taskType == MaintenanceTaskTypes.chainLube);
      expect(chainSchedule.status, MaintenanceScheduleStatus.optimal);
      expect(chainSchedule.dueInKm, 500);
    });

    test('deleteMaintenanceTask removes log and updates schedule', () async {
      final log = MaintenanceLogEntity(
        id: 'log-del',
        bikeId: 'bike-123',
        taskType: MaintenanceTaskTypes.oilChange,
        performedAtKm: 4000,
        performedAtDate: DateTime.now(),
        nextDueKm: 9000,
      );

      await notifier.addMaintenanceTask(log);
      expect(notifier.state.tasks.length, 1);

      await notifier.deleteMaintenanceTask('log-del');
      expect(notifier.state.tasks, isEmpty);
    });

    test('Filtered tasks returns proper subsets', () async {
      final now = DateTime.now();
      mockRepo.inMemoryLogs = [
        MaintenanceLogEntity(
          id: '1',
          bikeId: 'b1',
          taskType: MaintenanceTaskTypes.oilChange,
          performedAtKm: 1000,
          performedAtDate: now,
          nextDueKm: 6000,
        ),
        MaintenanceLogEntity(
          id: '2',
          bikeId: 'b1',
          taskType: MaintenanceTaskTypes.chainLube,
          performedAtKm: 1000,
          performedAtDate: now,
          nextDueKm: 1500,
        ),
        MaintenanceLogEntity(
          id: '3',
          bikeId: 'b1',
          taskType: MaintenanceTaskTypes.brakePads,
          performedAtKm: 1000,
          performedAtDate: now,
          nextDueKm: 16000,
        ),
      ];

      await notifier.loadTasksForBike('b1', currentOdometerKm: 1000);

      expect(notifier.state.filteredTasks.length, 3);

      notifier.setFilter('OIL');
      expect(notifier.state.filteredTasks.length, 1);
      expect(notifier.state.filteredTasks.first.taskType, MaintenanceTaskTypes.oilChange);

      notifier.setFilter('CHAIN');
      expect(notifier.state.filteredTasks.length, 1);
      expect(notifier.state.filteredTasks.first.taskType, MaintenanceTaskTypes.chainLube);

      notifier.setFilter('BRAKES');
      expect(notifier.state.filteredTasks.length, 1);
      expect(notifier.state.filteredTasks.first.taskType, MaintenanceTaskTypes.brakePads);
    });
  });
}
