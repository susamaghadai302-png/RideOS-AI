import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_identity_confidence.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/digital_twin_model.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/digital_twin_service.dart';
import 'package:rideos_mobile/features/garage/core/services/scan_coverage_evaluator.dart';

@Timeout(Duration(seconds: 120))

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 22: Dynamic Vehicle 3D Digital Twin Scenarios (Tests A to J)', () {
    late DigitalTwinService digitalTwinService;
    late ScanCoverageEvaluator scanEvaluator;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      digitalTwinService = DigitalTwinService();
      scanEvaluator = ScanCoverageEvaluator();
      await digitalTwinService.initialize();
    });

    test('TEST A: Known Yamaha MT-09 SP -> profile identified, 3D model pending validation (zero fake model)', () async {
      final identity = await digitalTwinService.identifyVehicle(bluetoothName: 'YAMAHA_MT09');
      expect(identity.confidenceLevel, equals(IdentityConfidenceLevel.scanRequired));
      expect(identity.manufacturer, equals('Yamaha'));
      expect(identity.model, equals('MT-09 SP'));
      expect(identity.hasExact3DModel, isFalse);

      final modelPath = await digitalTwinService.loadExistingModel(identity.matchedProfile!.id);
      expect(modelPath, isNull);
    });

    test('TEST B: Known Yamaha YZF-R1M -> Pending authentic scan, zero fake bike loaded', () async {
      final identity = await digitalTwinService.identifyVehicle(bluetoothName: 'YAMAHA_R1M');
      expect(identity.confidenceLevel, equals(IdentityConfidenceLevel.scanRequired));
      expect(identity.manufacturer, equals('Yamaha'));
      expect(identity.model, equals('YZF-R1M'));
      expect(identity.hasExact3DModel, isFalse);

      final modelPath = await digitalTwinService.loadExistingModel(identity.matchedProfile!.id);
      expect(modelPath, isNull);
    });

    test('TEST C: Known Ducati Panigale V4 S -> exact Panigale superbike model loads', () async {
      final identity = await digitalTwinService.identifyVehicle(bluetoothName: 'DUCATI-DMS');
      expect(identity.confidenceLevel, equals(IdentityConfidenceLevel.exactMatch));
      expect(identity.manufacturer, equals('Ducati'));
      expect(identity.model, equals('Panigale V4 S'));
      expect(identity.hasExact3DModel, isTrue);

      final modelPath = await digitalTwinService.loadExistingModel(identity.matchedProfile!.id);
      expect(modelPath, equals('assets/models/ducati_panigale.glb'));
    });

    test('TEST D: Known BMW M 1000 RR -> exact BMW homologation superbike model loads', () async {
      final identity = await digitalTwinService.identifyVehicle(bluetoothName: 'BMW_M1000RR');
      expect(identity.confidenceLevel, equals(IdentityConfidenceLevel.exactMatch));
      expect(identity.manufacturer, equals('BMW'));
      expect(identity.model, equals('M 1000 RR'));
      expect(identity.hasExact3DModel, isTrue);

      final modelPath = await digitalTwinService.loadExistingModel(identity.matchedProfile!.id);
      expect(modelPath, equals('assets/models/bmw_m1000rr.glb'));
    });

    test('TEST E: Known Suzuki Burgman Street 125 EX -> profile identified, 3D model pending validation (zero fake model)', () async {
      final identity = await digitalTwinService.identifyVehicle(bluetoothName: 'SUZUKI_RIDE_CONNECT');
      expect(identity.confidenceLevel, equals(IdentityConfidenceLevel.scanRequired));
      expect(identity.manufacturer, equals('Suzuki'));
      expect(identity.model, equals('Burgman Street 125 EX'));
      expect(identity.hasExact3DModel, isFalse);

      final modelPath = await digitalTwinService.loadExistingModel(identity.matchedProfile!.id);
      expect(modelPath, isNull);
    });

    test('TEST F: Unknown vehicle -> Scan workflow required (Zero silent fallback)', () async {
      final identity = await digitalTwinService.identifyVehicle(bluetoothName: 'UNKNOWN_CUSTOM_CHOPPER');
      expect(identity.confidenceLevel, equals(IdentityConfidenceLevel.unknown));
      expect(identity.hasExact3DModel, isFalse);
      expect(identity.requiresScan, isTrue);
    });

    test('TEST G & H: Completed scan -> Digital Twin record created and loads in Smart Garage', () async {
      final reconstruction = await digitalTwinService.reconstructFromPhotos(
        vehicleId: 'v_honda_cbr650r_custom',
        manufacturer: 'Honda',
        modelName: 'CBR650R',
        category: 'Sport',
        year: 2024,
        targetQuality: DigitalTwinQuality.ultra,
      );

      expect(reconstruction.twinId, isNotEmpty);
      expect(reconstruction.modelGlbPath, isNotEmpty);

      // Verify it loads for the vehicle
      final loadedModel = await digitalTwinService.loadExistingModel('v_honda_cbr650r_custom');
      expect(loadedModel, equals(reconstruction.modelGlbPath));
    });

    test('TEST I: Same vehicle reconnects -> saved Digital Twin automatically loads', () async {
      await digitalTwinService.reconstructFromPhotos(
        vehicleId: 'v_kawasaki_ninja_400',
        manufacturer: 'Kawasaki',
        modelName: 'Ninja 400',
        category: 'Sport',
        year: 2023,
      );

      final reconnectedIdentity = await digitalTwinService.identifyVehicle(bluetoothName: 'KAWASAKI_NINJA_400');
      expect(reconnectedIdentity.hasSavedDigitalTwin, isTrue);
    });

    test('TEST J: Different vehicle connects -> previous vehicle model is NOT displayed', () async {
      final reconAprilia = await digitalTwinService.reconstructFromPhotos(
        vehicleId: 'v_aprilia_rs660',
        manufacturer: 'Aprilia',
        modelName: 'RS 660',
        category: 'Sport',
        year: 2024,
      );

      final loadedAprilia = await digitalTwinService.loadExistingModel('v_aprilia_rs660');
      expect(loadedAprilia, equals(reconAprilia.modelGlbPath));

      // Connect KTM -> must NOT show Aprilia model
      final ktmLoaded = await digitalTwinService.loadExistingModel('v_ktm_duke_390');
      expect(ktmLoaded, isNull);
    });
  });
}
