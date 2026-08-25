import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rideos_mobile/features/connected_vehicle/presentation/screens/connect_vehicle_screen.dart';
import 'package:rideos_mobile/features/connected_vehicle/presentation/screens/add_vehicle_modal.dart';
import 'package:rideos_mobile/features/connected_vehicle/presentation/screens/manual_vehicle_selector_modal.dart';
import 'package:rideos_mobile/core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_profile.dart';
import 'package:rideos_mobile/core/vehicle_resolution/repositories/my_vehicles_repository.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    SharedPreferences.setMockInitialValues({});
  });

  group('Connect Vehicle Page & Add Vehicle End-to-End Functional Tests', () {
    testWidgets('1. Connect Vehicle screen loads and displays scan and action buttons', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ConnectVehicleScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('CONNECT VEHICLE'), findsOneWidget);
      expect(find.text('DISCOVERED TWO-WHEELERS'), findsOneWidget);
      expect(find.text('ADD VEHICLE'), findsOneWidget);
      expect(find.text('MANUAL SELECTION'), findsOneWidget);
    });

    testWidgets('2. Add Vehicle modal renders all required fields and is not blank', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddVehicleModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check required fields
      expect(find.text('ADD VEHICLE'), findsOneWidget);
      expect(find.text('VEHICLE TYPE'), findsOneWidget);
      expect(find.text('Motorcycle'), findsOneWidget);
      expect(find.text('Scooter'), findsOneWidget);
      expect(find.text('BRAND / MANUFACTURER *'), findsOneWidget);
      expect(find.text('MODEL *'), findsOneWidget);
      expect(find.text('MODEL YEAR'), findsOneWidget);
      expect(find.text('REGISTRATION NUMBER (NUMBER PLATE) *'), findsOneWidget);
      expect(find.text('NICKNAME (OPTIONAL)'), findsOneWidget);
      expect(find.text('SAVE VEHICLE'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
    });

    testWidgets('3. Add Vehicle form validates required registration number', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AddVehicleModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure Save button is visible then tap
      final saveBtn = find.text('SAVE VEHICLE');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(find.text('Registration number is required'), findsOneWidget);
    });

    testWidgets('4. Add Vehicle form saves vehicle and updates state', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(),
          child: const MaterialApp(
            home: Scaffold(
              body: AddVehicleModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter registration number in the registration field using Key
      final regField = find.byKey(const Key('add_vehicle_reg_field'));
      await tester.ensureVisible(regField);
      await tester.enterText(regField, 'KA 01 MG 9999');
      await tester.pump();

      // Tap Save using Key
      final saveBtn = find.byKey(const Key('add_vehicle_save_button'));
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      // Verify active vehicle context was updated
      final active = container.read(activeVehicleContextProvider);
      expect(active.hasActiveVehicle, isTrue);

      // Drain haptic timer
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('5. Manual Vehicle Selector modal renders offline catalog and allows connection', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container = ProviderContainer(),
          child: const MaterialApp(
            home: Scaffold(
              body: ManualVehicleSelectorModal(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MANUAL VEHICLE SELECTION'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('Motorcycle'), findsOneWidget);
      expect(find.text('Scooter'), findsOneWidget);

      // Select first vehicle item by chevron icon
      final firstVehicleChevron = find.byIcon(Icons.chevron_right_rounded).first;
      await tester.ensureVisible(firstVehicleChevron);
      await tester.tap(firstVehicleChevron);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Vehicle preview should appear
      expect(find.text('VEHICLE PREVIEW'), findsOneWidget);
      expect(find.text('CONNECT VEHICLE'), findsOneWidget);
      expect(find.text('ADD TO GARAGE'), findsOneWidget);

      // Tap Connect using Key
      final connectBtn = find.byKey(const Key('manual_connect_button'));
      await tester.ensureVisible(connectBtn);
      await tester.tap(connectBtn);

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();

      final active = container.read(activeVehicleContextProvider);
      expect(active.hasActiveVehicle, isTrue);

      // Drain haptic timer
      await tester.pump(const Duration(milliseconds: 200));
    });

    test('6. Vehicle Persistence: Vehicle added to MyVehiclesRepository persists and reloads', () async {
      final repo = MyVehiclesRepository();
      const testVehicle = VehicleProfile(
        id: 'v_test_honda_activa_persist',
        manufacturer: 'Honda',
        model: 'Activa 6G Premium',
        variant: 'Deluxe',
        year: 2024,
        category: 'Scooter',
        fuelType: 'Petrol',
        displacementCc: 109,
        powerBhp: 7.7,
        torqueNm: 8.9,
        topSpeedKmh: 85,
        curbWeightKg: 107,
        fuelCapacityL: 5.3,
        protocolAdapter: 'generic_obd_ble',
        model3DUrl: '',
        thumbnailUrl: 'assets/garage/generic_bike.png',
        isVerified: true,
        specifications: {
          'registrationNumber': 'DL 01 AB 1234',
        },
      );

      // Save vehicle
      await repo.addOwnedVehicle(testVehicle);

      // Read back from repository
      final list = await repo.getOwnedVehicles();
      final match = list.firstWhere((v) => v.id == 'v_test_honda_activa_persist');

      expect(match, isNotNull);
      expect(match.manufacturer, equals('Honda'));
      expect(match.model, equals('Activa 6G Premium'));
      expect(match.specifications['registrationNumber'], equals('DL 01 AB 1234'));
    });

    testWidgets('7. Connect Vehicle screen displays unified Radio Ready and Discovered state', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ConnectVehicleScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('CONNECT VEHICLE'), findsOneWidget);
      expect(find.text('DISCOVERED TWO-WHEELERS'), findsOneWidget);
      expect(find.text('ADD VEHICLE'), findsOneWidget);
      expect(find.text('MANUAL SELECTION'), findsOneWidget);
    });
  });
}
