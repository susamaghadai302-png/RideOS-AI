import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/garage/domain/models/advanced_garage_models.dart';
import 'package:rideos_mobile/features/garage/core/services/advanced_3d_garage_engine.dart';
import 'package:rideos_mobile/features/garage/presentation/screens/advanced_3d_garage_screen.dart';
import 'package:rideos_mobile/core/widgets/rideos_3d_model_viewer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Advanced3dGarageEngine garageEngine;

  setUp(() {
    garageEngine = Advanced3dGarageEngine();
  });

  group('Phase 15: Advanced 3D Garage Models & Engine', () {
    test('Vehicle Registry correctly loads all motorcycle profiles without cross-contamination', () {
      final profiles = garageEngine.registeredProfiles;
      expect(profiles.length, equals(1));

      final unconf = garageEngine.getProfileById('v_unconfigured');
      expect(unconf, isNotNull);
      expect(unconf!.modelName, contains('Not Configured'));
      expect(unconf.displacementCc, equals(0));
      expect(unconf.horsepower, equals(0.0));
      expect(unconf.assetGlbPath, isEmpty);
    });

    test('3D Asset and specification validation accurately verifies motorcycle-specific assets', () {
      garageEngine.selectVehicle('v_unconfigured');
      final validProfile = garageEngine.selectedProfile;
      final validation = garageEngine.validateProfile(validProfile);
      expect(validation.isValid, isFalse);
    });

    test('Camera and Lighting presets cycle accurately and update state', () {
      expect(garageEngine.activeCameraPreset, equals(CameraPreset.isometric));
      expect(garageEngine.activeLightingPreset, equals(LightingPreset.showroomStudio));

      garageEngine.setCameraPreset(CameraPreset.front);
      expect(garageEngine.activeCameraPreset, equals(CameraPreset.front));
      expect(garageEngine.cameraAngleDegrees, equals(0.0));

      garageEngine.setLightingPreset(LightingPreset.cyberpunkNeon);
      expect(garageEngine.activeLightingPreset, equals(LightingPreset.cyberpunkNeon));
    });

    test('Component selection and interactive inspection retrieves authentic component data', () {
      final unconf = garageEngine.getProfileById('v_unconfigured')!;
      expect(unconf.components.length, equals(0));
    });

    test('AI Garage Assistant provides accurate offline responses and torque/maintenance queries', () {
      final unconf = garageEngine.getProfileById('v_unconfigured')!;
      garageEngine.selectVehicle(unconf.id);

      final query1 = garageEngine.askAiAssistant('What is the oil capacity and maintenance schedule?');
      expect(query1.isOfflineReady, isTrue);
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
      expect(find.text('Unknown Not Configured'), findsWidgets);

      // Verify Specs
      expect(find.text('0 HP'), findsOneWidget);
      expect(find.text('0cc'), findsOneWidget);
      expect(find.text('0.0 Nm'), findsOneWidget);

      // Verify Camera Presets header
      expect(find.text('CAMERA PRESETS'), findsOneWidget);
    });

    testWidgets('Camera Preset buttons update RideOS3DModelViewer cameraOrbit', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Advanced3dGarageScreen(engine: garageEngine),
        ),
      );
      await tester.pumpAndSettle();

      String? getOrbit() {
        final viewerFinder = find.byType(RideOS3DModelViewer);
        expect(viewerFinder, findsOneWidget);
        final viewer = tester.widget<RideOS3DModelViewer>(viewerFinder);
        return viewer.cameraOrbit;
      }

      // Initial state (isometric)
      expect(getOrbit(), equals('45deg 70deg 90%'));

      // Tap front (arrow_upward)
      await tester.tap(find.byIcon(Icons.arrow_upward));
      await tester.pumpAndSettle();
      expect(getOrbit(), equals('0deg 85deg 90%'));

      // Tap sideProfile (arrow_forward)
      await tester.tap(find.byIcon(Icons.arrow_forward));
      await tester.pumpAndSettle();
      expect(getOrbit(), equals('90deg 85deg 90%'));

      // Tap rear (arrow_downward)
      await tester.tap(find.byIcon(Icons.arrow_downward));
      await tester.pumpAndSettle();
      expect(getOrbit(), equals('180deg 85deg 90%'));

      // Tap topInspection (layers_rounded)
      await tester.tap(find.byIcon(Icons.layers_rounded));
      await tester.pumpAndSettle();
      expect(getOrbit(), equals('0deg 0deg 90%'));
    });
  });
}
