import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/garage/domain/models/advanced_garage_models.dart';
import 'package:rideos_mobile/features/garage/core/services/advanced_3d_garage_engine.dart';
import 'package:rideos_mobile/features/garage/presentation/screens/advanced_3d_garage_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Advanced3dGarageEngine garageEngine;

  setUp(() {
    garageEngine = Advanced3dGarageEngine();
  });

  group('Phase 15: Advanced 3D Garage Models & Engine', () {
    test('Vehicle Registry correctly loads all motorcycle profiles without cross-contamination', () {
      final profiles = garageEngine.registeredProfiles;
      expect(profiles.length, equals(5));

      final r1m = garageEngine.getProfileById('v_yamaha_r1m');
      expect(r1m, isNotNull);
      expect(r1m!.modelName, contains('YZF-R1M'));
      expect(r1m.displacementCc, equals(998));
      expect(r1m.horsepower, equals(200.0));
      expect(r1m.torqueNm, equals(113.8));
      expect(r1m.curbWeightKg, equals(201.0));
      expect(r1m.assetGlbPath, isEmpty);

      final ducati = garageEngine.getProfileById('v_ducati_v4s');
      expect(ducati, isNotNull);
      expect(ducati!.modelName, contains('Panigale V4 S'));
      expect(ducati.displacementCc, equals(1103));
      expect(ducati.horsepower, equals(214.0));
      expect(ducati.assetGlbPath, equals('assets/models/ducati_panigale.glb'));

      final mt09 = garageEngine.getProfileById('v_yamaha_mt09_sp');
      expect(mt09, isNotNull);
      expect(mt09!.displacementCc, equals(890));
      expect(mt09.horsepower, equals(119.0));
      expect(mt09.assetGlbPath, isEmpty);

      final m1000rr = garageEngine.getProfileById('v_bmw_m1000rr');
      expect(m1000rr, isNotNull);
      expect(m1000rr!.displacementCc, equals(999));
      expect(m1000rr.horsepower, equals(212.0));
      expect(m1000rr.assetGlbPath, equals('assets/models/bmw_m1000rr.glb'));

      final burgman = garageEngine.getProfileById('v_suzuki_burgman125');
      expect(burgman, isNotNull);
      expect(burgman!.displacementCc, equals(124));
      expect(burgman.assetGlbPath, isEmpty);
    });

    test('3D Asset and specification validation accurately verifies motorcycle-specific assets', () {
      garageEngine.selectVehicle('v_ducati_v4s');
      final validProfile = garageEngine.selectedProfile;
      final validation = garageEngine.validateProfile(validProfile);
      expect(validation.isValid, isTrue);
      expect(validation.warnings.isEmpty, isTrue);

      const invalidProfile = MotorcycleGarageProfile(
        id: 'v_corrupt',
        manufacturer: 'Unknown',
        modelName: 'Ghost',
        variant: 'Corrupt',
        year: 2026,
        displacementCc: 0, // Invalid
        horsepower: 0, // Invalid
        torqueNm: 0,
        curbWeightKg: 0,
        assetGlbPath: '', // Missing
        colorOptions: [],
        components: [],
      );

      final invalidValidation = garageEngine.validateProfile(invalidProfile);
      expect(invalidValidation.isValid, isFalse);
      expect(invalidValidation.missingAssets, contains('Primary 3D asset path is empty'));
      expect(invalidValidation.warnings, contains('Displacement CC or Horsepower cannot be zero or negative'));
    });

    test('Camera and Lighting presets cycle accurately and update state', () {
      expect(garageEngine.activeCameraPreset, equals(CameraPreset.isometric));
      expect(garageEngine.activeLightingPreset, equals(LightingPreset.showroomStudio));

      garageEngine.setCameraPreset(CameraPreset.front);
      expect(garageEngine.activeCameraPreset, equals(CameraPreset.front));
      expect(garageEngine.cameraAngleDegrees, equals(0.0));

      garageEngine.setCameraPreset(CameraPreset.sideProfile);
      expect(garageEngine.activeCameraPreset, equals(CameraPreset.sideProfile));
      expect(garageEngine.cameraAngleDegrees, equals(90.0));

      garageEngine.setLightingPreset(LightingPreset.cyberpunkNeon);
      expect(garageEngine.activeLightingPreset, equals(LightingPreset.cyberpunkNeon));

      garageEngine.setLightingPreset(LightingPreset.trackdayPaddock);
      expect(garageEngine.activeLightingPreset, equals(LightingPreset.trackdayPaddock));
    });

    test('Component selection and interactive inspection retrieves authentic component data', () {
      final r1m = garageEngine.getProfileById('v_yamaha_r1m')!;
      expect(r1m.components.length, greaterThanOrEqualTo(4));

      final exhaust = r1m.components.firstWhere((c) => c.id == 'r1m_exhaust');
      expect(exhaust.name, contains('Akrapovič'));

      garageEngine.selectComponent(exhaust);
      expect(garageEngine.selectedComponent?.id, equals('r1m_exhaust'));
      expect(garageEngine.selectedComponent?.specs['Material'], equals('Titanium'));

      garageEngine.selectComponent(null);
      expect(garageEngine.selectedComponent, isNull);
    });

    test('AI Garage Assistant provides accurate offline responses and torque/maintenance queries', () {
      final ducati = garageEngine.getProfileById('v_ducati_v4s')!;
      garageEngine.selectVehicle(ducati.id);

      final query1 = garageEngine.askAiAssistant('What is the oil capacity and maintenance schedule?');
      expect(query1.reply, contains('Oil Capacity'));
      expect(query1.reply, contains('3.8 Liters'));
      expect(query1.isOfflineReady, isTrue);

      final query2 = garageEngine.askAiAssistant('Show me torque specs for the calipers');
      expect(query2.reply, contains('Torque Specs'));
      expect(query2.reply, contains('45 Nm'));

      final query3 = garageEngine.askAiAssistant('What are the engine specs?');
      expect(query3.reply, contains('Panigale V4 S'));
      expect(query3.reply, contains('214 HP'));
    });
  });

  group('Phase 15: Advanced 3D Garage UI Screen Widget Tests', () {
    testWidgets('Renders 3D Garage screen, tabs, vehicle specs, and toggles', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Advanced3dGarageScreen(engine: garageEngine),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('SMART GARAGE 3D & VEHICLE SYSTEM'), findsOneWidget);

      // Verify Vehicle selector tabs
      expect(find.text('Yamaha YZF-R1M'), findsWidgets);
      expect(find.text('Ducati Panigale V4 S'), findsWidgets);

      // Verify Specs
      expect(find.text('200 HP'), findsOneWidget);
      expect(find.text('998cc'), findsOneWidget);
      expect(find.text('113.8 Nm'), findsOneWidget);

      // Verify Camera Presets header
      expect(find.text('CAMERA PRESETS'), findsOneWidget);

      // Tap Ducati tab to switch vehicle
      await tester.tap(find.text('Ducati Panigale V4 S').first);
      await tester.pumpAndSettle();

      // Verify Ducati Specs updated
      expect(find.text('214 HP'), findsOneWidget);
      expect(find.text('1103cc'), findsOneWidget);
      expect(find.text('124.0 Nm'), findsOneWidget);

      // Verify Component Inspection Tile is present
      expect(find.text('INTERACTIVE COMPONENT INSPECTION'), findsOneWidget);
      expect(find.text('Brembo Stylema R Monobloc Calipers'), findsOneWidget);

      // Verify AI Query Input
      final aiFinder = find.text('GARAGE AI DIAGNOSTIC ASSISTANT');
      await tester.scrollUntilVisible(
        aiFinder,
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(aiFinder, findsOneWidget);

      await tester.enterText(find.byType(TextField), 'What is the oil capacity?');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(find.textContaining('3.8 Liters'), findsOneWidget);
    });
  });
}
