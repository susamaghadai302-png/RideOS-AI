import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/digital_twin_model.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/digital_twin_service.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_registry.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_model_registry.dart';
import 'package:rideos_mobile/features/garage/core/services/scan_coverage_evaluator.dart';
import 'package:rideos_mobile/features/garage/core/services/model_quality_validator.dart';

@Timeout(Duration(seconds: 120))

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 23: Production Digital Twin Final Validation & Zero-Demo Enforcement', () {
    late DigitalTwinService digitalTwinService;
    late VehicleRegistry registry;
    late VehicleModelRegistry modelRegistry;
    late ScanCoverageEvaluator scanEvaluator;
    late ModelQualityValidator qualityValidator;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      digitalTwinService = DigitalTwinService();
      registry = VehicleRegistry();
      modelRegistry = VehicleModelRegistry();
      scanEvaluator = ScanCoverageEvaluator();
      qualityValidator = ModelQualityValidator();
      await digitalTwinService.initialize();
    });

    test('1. Verified OEM CAD Asset Existence & Valid GLB Binary Magic Headers', () {
      final models = {
        'Ducati Panigale V4 S': 'assets/models/ducati_panigale.glb',
        'BMW M 1000 RR': 'assets/models/bmw_m1000rr.glb',
      };

      for (final entry in models.entries) {
        final file = File(entry.value);
        expect(file.existsSync(), isTrue, reason: '${entry.key} GLB model file must exist on disk at ${entry.value}');
        
        final bytes = file.readAsBytesSync();
        expect(bytes.length, greaterThan(1024 * 1024), reason: '${entry.key} GLB model file must be authentic high-fidelity CAD asset');

        // Check glTF binary magic header: 0x46546C67 (ASCII: 'glTF')
        final magic = String.fromCharCodes(bytes.sublist(0, 4));
        expect(magic, equals('glTF'), reason: '${entry.key} file must have valid GLB binary header');
      }
    });

    test('2. Duplicate-Model Detection & Invariant Verification', () {
      final configs = modelRegistry.allVerifiedConfigs;
      final usedModels = <String, String>{};

      for (final cfg in configs) {
        if (cfg.model3d.isNotEmpty) {
          expect(
            usedModels.containsKey(cfg.model3d),
            isFalse,
            reason: 'INVARIANT VIOLATION: "${cfg.model3d}" is shared by multiple vehicles: ${usedModels[cfg.model3d]} and ${cfg.model}',
          );
          usedModels[cfg.model3d] = cfg.model;
        }
      }

      expect(usedModels.length, equals(2), reason: 'Only the verified OEM vehicles have pre-bundled 3D GLB models');
    });

    test('3. Strict 1-to-1 Vehicle -> Model Mapping Verification', () {
      // 1. Yamaha MT-09 SP (Pending Validation - No Dummy Geometry)
      final mt09Cfg = modelRegistry.getModelConfig('v_yamaha_mt09_sp');
      expect(mt09Cfg.model3d, isEmpty);
      expect(mt09Cfg.modelAvailable, isFalse);
      expect(mt09Cfg.thumbnail, equals('assets/garage/yamaha_mt09_sp.png'));
      expect(mt09Cfg.model, equals('MT-09 SP'));

      // 2. Yamaha YZF-R1M (Model Validation Pending — Zero Dummy Geometry)
      final r1mCfg = modelRegistry.getModelConfig('v_yamaha_r1m');
      expect(r1mCfg.model3d, isEmpty);
      expect(r1mCfg.modelAvailable, isFalse);
      expect(r1mCfg.thumbnail, equals('assets/garage/yamaha_r1m.png'));
      expect(r1mCfg.model, equals('YZF-R1M'));

      // 3. Ducati Panigale V4 S (Official Validated OEM)
      final ducatiCfg = modelRegistry.getModelConfig('v_ducati_v4s');
      expect(ducatiCfg.model3d, equals('assets/models/ducati_panigale.glb'));
      expect(ducatiCfg.modelAvailable, isTrue);
      expect(ducatiCfg.thumbnail, equals('assets/garage/ducati_panigale.png'));
      expect(ducatiCfg.model, equals('Panigale V4 S'));

      // 4. BMW M 1000 RR (Official Validated OEM)
      final bmwCfg = modelRegistry.getModelConfig('v_bmw_m1000rr');
      expect(bmwCfg.model3d, equals('assets/models/bmw_m1000rr.glb'));
      expect(bmwCfg.modelAvailable, isTrue);
      expect(bmwCfg.thumbnail, equals('assets/garage/bmw_m1000rr.png'));
      expect(bmwCfg.model, equals('M 1000 RR'));

      // 5. Suzuki Burgman Street 125 EX (Pending Validation - No Dummy Geometry)
      final suzukiCfg = modelRegistry.getModelConfig('v_suzuki_burgman125');
      expect(suzukiCfg.model3d, isEmpty);
      expect(suzukiCfg.modelAvailable, isFalse);
      expect(suzukiCfg.thumbnail, equals('assets/garage/suzuki_burgman.png'));
      expect(suzukiCfg.model, equals('Burgman Street 125 EX'));
    });

    test('4. Zero-Demo Enforcement: Generic OBD and Unknown Vehicles never receive fake bikes', () async {
      // Generic OBD-II Gateway
      final obdCfg = modelRegistry.getModelConfig('v_generic_obd2');
      expect(obdCfg.modelAvailable, isFalse);
      expect(obdCfg.model3d, isEmpty);

      final obdProfile = registry.getProfileById('v_generic_obd2');
      expect(obdProfile!.has3DModel, isFalse);
      expect(obdProfile.model3DUrl, isEmpty);

      // Unknown custom vehicle
      final unknownModel = await digitalTwinService.loadExistingModel('v_completely_unknown_999');
      expect(unknownModel, isNull, reason: 'Unknown vehicle must NEVER silently fallback to an arbitrary motorcycle model');

      final scanRequired = await digitalTwinService.determineWhetherScanIsRequired('v_completely_unknown_999');
      expect(scanRequired, isTrue);
    });

    test('5. Digital Twin Isolation: Vehicle A must never show Vehicle B model', () async {
      const bikeA = 'v_royalenfield_interceptor_650';
      const bikeB = 'v_harley_iron883';

      final framesA = ScanSector.values.map((s) => CapturedFrameMetadata(
        frameId: 'a_${s.name}',
        targetSector: s,
        estimatedAngleDeg: s.targetAngleDeg.toDouble(),
        timestamp: DateTime.now(),
      )).toList();

      final twinA = await digitalTwinService.createDigitalTwinRecord(
        vehicleId: bikeA,
        manufacturer: 'Royal Enfield',
        modelName: 'Interceptor 650',
        year: 2024,
        category: 'Roadster',
        capturedFrames: framesA,
        targetQuality: DigitalTwinQuality.high,
      );

      final framesB = ScanSector.values.map((s) => CapturedFrameMetadata(
        frameId: 'b_${s.name}',
        targetSector: s,
        estimatedAngleDeg: s.targetAngleDeg.toDouble(),
        timestamp: DateTime.now(),
      )).toList();

      final twinB = await digitalTwinService.createDigitalTwinRecord(
        vehicleId: bikeB,
        manufacturer: 'Harley-Davidson',
        modelName: 'Iron 883',
        year: 2023,
        category: 'Cruiser',
        capturedFrames: framesB,
        targetQuality: DigitalTwinQuality.high,
      );

      expect(twinA.twinId, isNot(equals(twinB.twinId)));
      expect(twinA.modelGlbPath, isNot(equals(twinB.modelGlbPath)));

      // Vehicle A must load Twin A
      final loadedA = await digitalTwinService.loadExistingModel(bikeA);
      expect(loadedA, equals(twinA.modelGlbPath));
      expect(loadedA, isNot(equals(twinB.modelGlbPath)));

      // Vehicle B must load Twin B
      final loadedB = await digitalTwinService.loadExistingModel(bikeB);
      expect(loadedB, equals(twinB.modelGlbPath));
      expect(loadedB, isNot(equals(twinA.modelGlbPath)));
    });

    test('6. Reconnect Consistency: Same vehicle reconnects -> automatically loads saved twin', () async {
      const vehicleId = 'v_honda_africa_twin_1100';
      final twin = await digitalTwinService.reconstructFromPhotos(
        vehicleId: vehicleId,
        manufacturer: 'Honda',
        modelName: 'CRF1100L Africa Twin',
        category: 'Adventure',
        year: 2024,
      );

      // Verify immediate load
      final loaded1 = await digitalTwinService.loadExistingModel(vehicleId);
      expect(loaded1, equals(twin.modelGlbPath));

      // Simulate app restart / new session
      final newServiceInstance = DigitalTwinService();
      await newServiceInstance.initialize();

      final loaded2 = await newServiceInstance.loadExistingModel(vehicleId);
      expect(loaded2, equals(twin.modelGlbPath));
    });
  });
}
