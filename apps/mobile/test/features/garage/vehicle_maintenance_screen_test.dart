import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideos_mobile/features/garage/presentation/screens/vehicle_maintenance_screen.dart';
import 'package:rideos_mobile/core/vehicle_health/services/maintenance_manager.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createWidgetUnderTest() {
    return const ProviderScope(
      child: MaterialApp(
        home: VehicleMaintenanceScreen(),
      ),
    );
  }

  group('VehicleMaintenanceScreen Widget Tests', () {
    testWidgets('Renders insufficient data state when odometer is 0', (WidgetTester tester) async {
      MaintenanceManager().setUserOdometer(0.0);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Insufficient Data'), findsOneWidget);
      expect(find.text('Waiting for Odometer'), findsWidgets);
    });

    testWidgets('Renders tasks list when odometer is available', (WidgetTester tester) async {
      MaintenanceManager().setUserOdometer(5000.0);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Active Tracking'), findsOneWidget);
      expect(find.text('5000 km'), findsOneWidget);
      expect(find.text('Engine Oil & Filter Change'), findsWidgets); // title mapped from generic
    });

    testWidgets('Selects task and shows explanation and generic advisory', (WidgetTester tester) async {
      MaintenanceManager().setUserOdometer(4500.0);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap the Engine Oil task (index 0 might be first in UI list if it's there)
      await tester.tap(find.text('Engine Oil & Filter Change').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Approaching distance limit'), findsOneWidget);
      expect(find.textContaining('ADVISORY ONLY'), findsOneWidget);
    });

    testWidgets('Opens modal, saves a service record, and UI updates', (WidgetTester tester) async {
      MaintenanceManager().setUserOdometer(5000.0);
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Ensure it starts out overdue or due now
      expect(find.text('Due Now'), findsWidgets);

      // Open modal
      await tester.tap(find.byTooltip('Log Service'));
      await tester.pumpAndSettle();

      expect(find.text('LOG COMPLETED SERVICE'), findsOneWidget);

      // Verify the text field for odometer has the current odometer
      expect(find.text('5000'), findsOneWidget);

      // Tap save
      await tester.tap(find.text('SAVE RECORD'));
      await tester.pumpAndSettle();

      // Modal closed, snackbar appears
      expect(find.text('Service logged and predictions updated.'), findsOneWidget);

      // The status should change from Due Now to Due in ...
      // We expect 'Due Now' to be gone for engine oil
      // Wait, there might be other items that are Due Now
      // But we can check for 'Due in 5000 km'
      expect(find.textContaining('Due in 5000 km'), findsWidgets);
    });
  });
}
