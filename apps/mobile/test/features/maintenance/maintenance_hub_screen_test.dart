import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_profile.dart';
import 'package:rideos_mobile/features/maintenance/domain/entities/maintenance_log_entity.dart';
import 'package:rideos_mobile/features/maintenance/domain/repositories/maintenance_repository.dart';
import 'package:rideos_mobile/features/maintenance/presentation/providers/maintenance_notifier.dart';
import 'package:rideos_mobile/features/maintenance/presentation/screens/maintenance_hub_screen.dart';

class FakeMaintenanceRepository implements MaintenanceRepository {
  final List<MaintenanceLogEntity> logs = [
    MaintenanceLogEntity(
      id: 'test-1',
      bikeId: 'bike-test',
      taskType: MaintenanceTaskTypes.oilChange,
      performedAtKm: 5000,
      performedAtDate: DateTime(2026, 10, 1),
      nextDueKm: 10000,
      notes: 'Initial dealer service',
      cost: 120.0,
      serviceProvider: 'Ducati Service Center',
    ),
  ];

  @override
  Future<List<MaintenanceLogEntity>> getLogsForBike(String bikeId) async {
    return logs;
  }

  @override
  Future<MaintenanceLogEntity> logTask(
    MaintenanceLogEntity task, {
    int? intervalKm,
  }) async {
    logs.add(task);
    return task;
  }

  @override
  Future<void> deleteLog(String logId, String bikeId) async {
    logs.removeWhere((l) => l.id == logId);
  }
}

void main() {
  testWidgets('MaintenanceHubScreen renders schedules and navigates tabs', (tester) async {
    final fakeRepo = FakeMaintenanceRepository();

    const testVehicle = VehicleProfile(
      id: 'bike-test',
      manufacturer: 'Ducati',
      model: 'Panigale V4',
      variant: 'S',
      year: 2024,
      category: 'SUPERBIKE',
      protocolAdapter: 'obd2_standard',
      model3DUrl: '',
      thumbnailUrl: '',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          maintenanceRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          home: MaintenanceHubScreen(vehicle: testVehicle),
        ),
      ),
    );

    // Initial load pump
    await tester.pumpAndSettle();

    // Verify Title & Vehicle name
    expect(find.text('DUCATI PANIGALE V4 S'), findsOneWidget);

    // Verify Odometer banner
    expect(find.textContaining('ODOMETER:'), findsOneWidget);
    expect(find.text('LOGGED SERVICES'), findsOneWidget);
    expect(find.text('UPCOMING ITEMS'), findsOneWidget);

    // Verify Tab headers
    expect(find.textContaining('SCHEDULES'), findsOneWidget);
    expect(find.textContaining('HISTORY'), findsOneWidget);

    // Tap History tab
    await tester.tap(find.textContaining('HISTORY'));
    await tester.pumpAndSettle();

    // Verify history item rendered
    expect(find.text('Engine Oil & Filter Change'), findsWidgets);
    expect(find.text('\$120'), findsNWidgets(2)); // Stats summary card + history tile
    expect(find.textContaining('Ducati Service Center'), findsOneWidget);

    // Verify Log Service button opens modal
    final logButton = find.byTooltip('Log Service');
    expect(logButton, findsOneWidget);
    await tester.tap(logButton);
    await tester.pumpAndSettle();

    // Verify modal is open
    expect(find.text('LOG COMPLETED SERVICE'), findsOneWidget);
    expect(find.text('SAVE SERVICE RECORD'), findsOneWidget);
  });
}
