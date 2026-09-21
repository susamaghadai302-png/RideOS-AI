import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_identity_confidence.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/digital_twin_service.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_model_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 25: Final Production Hardening & Real-Device Validation', () {
    late DigitalTwinService digitalTwinService;
    late VehicleModelRegistry modelRegistry;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      digitalTwinService = DigitalTwinService();
      modelRegistry = VehicleModelRegistry();
      await digitalTwinService.initialize();
    });

    test('1. Production 3D Assets: Physical GLB Existence & glTF Binary Magic', () {
      final requiredModels = [
        'assets/models/ducati_panigale.glb',
        'assets/models/bmw_m1000rr.glb',
      ];

      for (final path in requiredModels) {
        final file = File(path);
        expect(file.existsSync(), isTrue, reason: 'File $path must physically exist');
        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(1000), reason: 'File $path must not be a stub');
        final magic = String.fromCharCodes(bytes.sublist(0, 4));
        expect(magic, equals('glTF'), reason: 'File $path must have valid binary glTF header');
      }
    });

    test('2. Strict Uniqueness: Zero Shared 3D Models Across Different Vehicles', () {
      final configs = modelRegistry.allVerifiedConfigs;
      final assignedPaths = <String, String>{};

      for (final cfg in configs) {
        if (cfg.model3d.isNotEmpty) {
          expect(
            assignedPaths.containsKey(cfg.model3d),
            isFalse,
            reason: 'Model ${cfg.model3d} is improperly shared by ${assignedPaths[cfg.model3d]} and ${cfg.model}',
          );
          assignedPaths[cfg.model3d] = cfg.model;
        }
      }
      expect(assignedPaths.length, equals(2));
    });

    test('3. Vehicle Identity Resolution & Accurate Model Association', () async {
      // Yamaha MT-09 SP (Pending Validation)
      final mt09Identity = await digitalTwinService.identifyVehicle(bluetoothName: 'YAMAHA_MT09');
      expect(mt09Identity.confidenceLevel, equals(IdentityConfidenceLevel.scanRequired));
      expect(mt09Identity.hasExact3DModel, isFalse);
      final mt09Model = await digitalTwinService.loadExistingModel(mt09Identity.matchedProfile!.id);
      expect(mt09Model, isNull);

      // Yamaha YZF-R1M (Pending Authentic Scan — Zero Dummy Substitution)
      final r1mIdentity = await digitalTwinService.identifyVehicle(bluetoothName: 'YAMAHA_R1M');
      expect(r1mIdentity.confidenceLevel, equals(IdentityConfidenceLevel.scanRequired));
      expect(r1mIdentity.hasExact3DModel, isFalse);
      final r1mModel = await digitalTwinService.loadExistingModel(r1mIdentity.matchedProfile!.id);
      expect(r1mModel, isNull);

      // Ducati Panigale V4 S (Official Validated OEM)
      final ducatiIdentity = await digitalTwinService.identifyVehicle(bluetoothName: 'DUCATI-DMS');
      expect(ducatiIdentity.confidenceLevel, equals(IdentityConfidenceLevel.exactMatch));
      final ducatiModel = await digitalTwinService.loadExistingModel(ducatiIdentity.matchedProfile!.id);
      expect(ducatiModel, equals('assets/models/ducati_panigale.glb'));

      // BMW M 1000 RR (Official Validated OEM)
      final bmwIdentity = await digitalTwinService.identifyVehicle(bluetoothName: 'BMW_M1000RR');
      expect(bmwIdentity.confidenceLevel, equals(IdentityConfidenceLevel.exactMatch));
      final bmwModel = await digitalTwinService.loadExistingModel(bmwIdentity.matchedProfile!.id);
      expect(bmwModel, equals('assets/models/bmw_m1000rr.glb'));

      // Suzuki Burgman Street 125 EX (Pending Validation)
      final suzukiIdentity = await digitalTwinService.identifyVehicle(bluetoothName: 'SUZUKI_RIDE_CONNECT');
      expect(suzukiIdentity.confidenceLevel, equals(IdentityConfidenceLevel.scanRequired));
      expect(suzukiIdentity.hasExact3DModel, isFalse);
      final suzukiModel = await digitalTwinService.loadExistingModel(suzukiIdentity.matchedProfile!.id);
      expect(suzukiModel, isNull);
    });

    test('4. Zero Silent Substitution: Generic Gateway & Unknown Models', () async {
      final obdIdentity = await digitalTwinService.identifyVehicle(bluetoothName: 'ELM327_OBD_ADAPTER');
      expect(obdIdentity.hasExact3DModel, isFalse);
      final obdModel = await digitalTwinService.loadExistingModel('v_generic_obd2');
      expect(obdModel, isNull);

      final customIdentity = await digitalTwinService.identifyVehicle(bluetoothName: 'CUSTOM_HARLEY_UNKNOWN');
      expect(customIdentity.requiresScan, isTrue);
      final customModel = await digitalTwinService.loadExistingModel('v_custom_harley_unknown');
      expect(customModel, isNull);
    });

    test('5. Reconnect Continuity & Strict Isolation', () async {
      // Vehicle 1 creates Digital Twin
      const bike1 = 'v_benelli_tnt600';
      final twin1 = await digitalTwinService.reconstructFromPhotos(
        vehicleId: bike1,
        manufacturer: 'Benelli',
        modelName: 'TNT 600',
        category: 'Naked',
        year: 2023,
      );

      final loaded1 = await digitalTwinService.loadExistingModel(bike1);
      expect(loaded1, equals(twin1.modelGlbPath));

      // Vehicle 2 must NOT inherit Vehicle 1 model
      const bike2 = 'v_yamaha_aerox155';
      final loaded2 = await digitalTwinService.loadExistingModel(bike2);
      expect(loaded2, isNull);
    });

    test('6. Digital Twin Versioning & Privacy Source Purge', () async {
      const bike = 'v_mv_agusta_f3_800';
      final twin = await digitalTwinService.reconstructFromPhotos(
        vehicleId: bike,
        manufacturer: 'MV Agusta',
        modelName: 'F3 800',
        category: 'Supersport',
        year: 2024,
      );

      final success = await digitalTwinService.purgeSourcePhotos(twin.twinId);
      expect(success, isTrue);

      final purgedTwin = await digitalTwinService.loadSavedDigitalTwin(bike);
      expect(purgedTwin, isNotNull);
      expect(purgedTwin!.version, equals(1));
      expect(purgedTwin.sourcePhotosPurged, isTrue);
    });
  });
}
