import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_identity_confidence.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/digital_twin_model.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_profile.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_identity_confidence_engine.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/digital_twin_storage_service.dart';
import 'package:rideos_mobile/features/garage/core/services/scan_coverage_evaluator.dart';
import 'package:rideos_mobile/features/garage/core/services/model_quality_validator.dart';
import 'package:rideos_mobile/features/garage/core/services/vehicle_3d_reconstruction_service.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Dynamic Vehicle 3D Digital Twin & Identification Tests', () {
    late VehicleIdentityConfidenceEngine identityEngine;
    late DigitalTwinStorageService twinStorage;
    late ScanCoverageEvaluator scanEvaluator;
    late ModelQualityValidator qualityValidator;
    late Vehicle3DReconstructionService reconstructionService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      identityEngine = VehicleIdentityConfidenceEngine();
      twinStorage = DigitalTwinStorageService();
      scanEvaluator = ScanCoverageEvaluator();
      qualityValidator = ModelQualityValidator();
      reconstructionService = Vehicle3DReconstructionService();
      await twinStorage.initialize();
    });

    test('services initialize correctly', () {
      expect(scanEvaluator, isNotNull);
      expect(qualityValidator, isNotNull);
      expect(scanEvaluator.evaluateCoverage([]), isNotNull);
    });

    test('1. Vehicle Identity Confidence Engine classifies exact OEM vs unknown vehicle', () async {
      // A. Exact OEM match with validated 3D CAD model (Ducati Panigale V4 S)
      final oemResult = await identityEngine.evaluateIdentity(bluetoothName: 'DUCATI-DMS');
      expect(oemResult.confidenceLevel, equals(IdentityConfidenceLevel.exactMatch));
      expect(oemResult.confidenceScore, greaterThanOrEqualTo(0.95));
      expect(oemResult.manufacturer, equals('Ducati'));
      expect(oemResult.model, equals('Panigale V4 S'));
      expect(oemResult.hasExact3DModel, isTrue);
      expect(oemResult.requiresScan, isFalse);

      // B. Unknown vehicle signature
      final unknownResult = await identityEngine.evaluateIdentity(bluetoothName: 'CUSTOM_CAFE_RACER_99');
      expect(unknownResult.confidenceLevel, equals(IdentityConfidenceLevel.unknown));
      expect(unknownResult.confidenceScore, lessThan(0.30));
      expect(unknownResult.hasExact3DModel, isFalse);
      expect(unknownResult.requiresScan, isTrue);

      // C. Generic OBD-II Gateway
      final obdResult = await identityEngine.evaluateIdentity(bluetoothName: 'ELM327-DIAGNOSTIC-BLE');
      expect(obdResult.confidenceLevel, equals(IdentityConfidenceLevel.knownModel));
      expect(obdResult.hasExact3DModel, isFalse);
    });

    test('2. Scan Coverage Evaluator tracks 12 sectors and computes 0% - 100% coverage', () {
      final evaluator = ScanCoverageEvaluator();

      // Empty frames
      final emptyReport = evaluator.evaluateCoverage([]);
      expect(emptyReport.coveragePercent, equals(0.0));
      expect(emptyReport.isReadyForReconstruction, isFalse);
      expect(emptyReport.missingSectors.length, equals(12));

      // Partial sweep (Front + Left + Right)
      final partialFrames = [
        CapturedFrameMetadata(
          frameId: 'f1',
          targetSector: ScanSector.front,
          estimatedAngleDeg: 0,
          timestamp: DateTime.now(),
        ),
        CapturedFrameMetadata(
          frameId: 'f2',
          targetSector: ScanSector.left,
          estimatedAngleDeg: 270,
          timestamp: DateTime.now(),
        ),
        CapturedFrameMetadata(
          frameId: 'f3',
          targetSector: ScanSector.right,
          estimatedAngleDeg: 90,
          timestamp: DateTime.now(),
        ),
      ];
      final partialReport = evaluator.evaluateCoverage(partialFrames);
      expect(partialReport.coveragePercent, greaterThan(20.0));
      expect(partialReport.isReadyForReconstruction, isFalse);

      // Complete 360 sweep with components
      final fullFrames = ScanSector.values.map((s) => CapturedFrameMetadata(
        frameId: 'f_${s.name}',
        targetSector: s,
        estimatedAngleDeg: s.targetAngleDeg.toDouble(),
        brightnessScore: 0.75,
        sharpnessScore: 0.90,
        timestamp: DateTime.now(),
      )).toList();

      final fullReport = evaluator.evaluateCoverage(fullFrames);
      expect(fullReport.coveragePercent, equals(100.0));
      expect(fullReport.isReadyForReconstruction, isTrue);
      expect(fullReport.missingSectors, isEmpty);
      expect(fullReport.lightingAssessment, equals('Optimal Lighting'));
    });

    test('3. Model Quality Validator rejects corrupted/degenerate geometry and passes valid meshes', () {
      // Valid motorcycle mesh stats
      const validStats = DigitalTwinMeshStats(
        polygonCount: 85000,
        vertexCount: 52000,
        lengthMeters: 2.05,
        widthMeters: 0.82,
        heightMeters: 1.15,
        isGroundAligned: true,
        isManifold: true,
      );

      final validRes = qualityValidator.validateDigitalTwin(
        modelPath: 'assets/models/yamaha_mt09_sp.glb',
        stats: validStats,
      );
      expect(validRes.isValid, isTrue);
      expect(validRes.errorMessages, isEmpty);
      expect(validRes.qualityScore, greaterThan(0.85));

      // Degenerate mesh (< 1000 polygons)
      const degenerateStats = DigitalTwinMeshStats(
        polygonCount: 420,
        vertexCount: 200,
        lengthMeters: 2.05,
        widthMeters: 0.82,
        heightMeters: 1.15,
      );
      final degenerateRes = qualityValidator.validateDigitalTwin(
        modelPath: 'assets/models/corrupted.glb',
        stats: degenerateStats,
      );
      expect(degenerateRes.isValid, isFalse);
      expect(degenerateRes.errorMessages.first, contains('insufficient polygons'));

      // Out of bounds dimensions
      const giantStats = DigitalTwinMeshStats(
        polygonCount: 50000,
        vertexCount: 30000,
        lengthMeters: 12.5, // Anomaly
        widthMeters: 0.82,
        heightMeters: 1.15,
      );
      final giantRes = qualityValidator.validateDigitalTwin(
        modelPath: 'assets/models/giant.glb',
        stats: giantStats,
      );
      expect(giantRes.isValid, isFalse);
      expect(giantRes.errorMessages.first, contains('Dimensional anomaly'));
    });

    test('4. Full Digital Twin Life Cycle: Scan → Reconstruct → Save → Automatic Reconnect Recall', () async {
      final vehicleId = 'v_tvs_apache_rtr310_${DateTime.now().millisecondsSinceEpoch}';

      final frames = ScanSector.values.map((s) => CapturedFrameMetadata(
        frameId: 'frame_${s.name}',
        targetSector: s,
        estimatedAngleDeg: s.targetAngleDeg.toDouble(),
        timestamp: DateTime.now(),
      )).toList();

      // Step A: Reconstruct
      final twin = await reconstructionService.reconstructDigitalTwin(
        vehicleId: vehicleId,
        manufacturer: 'TVS',
        modelName: 'Apache RTR 310',
        year: 2024,
        category: 'Motorcycle',
        capturedFrames: frames,
        targetQuality: DigitalTwinQuality.high,
      );

      expect(twin.twinId, startsWith('vt_'));
      expect(twin.vehicleId, equals(vehicleId));
      expect(twin.manufacturer, equals('TVS'));
      expect(twin.model, equals('Apache RTR 310'));
      expect(twin.modelGlbPath, isNotEmpty);
      expect(twin.thumbnailUrl, isNotEmpty);

      // Step B: Verify storage persistence
      final savedTwin = await twinStorage.getDigitalTwinForVehicle(vehicleId);
      expect(savedTwin, isNotNull);
      expect(savedTwin!.twinId, equals(twin.twinId));
      expect(savedTwin.quality, equals(DigitalTwinQuality.high));

      // Step C: Reconnect same vehicle -> automatic identification recall
      final reconnectEval = await identityEngine.evaluateIdentity(bluetoothName: vehicleId);
      expect(reconnectEval.hasSavedDigitalTwin, isTrue);
      expect(reconnectEval.existingDigitalTwinId, equals(twin.twinId));
      expect(reconnectEval.requiresScan, isFalse);

      // Step D: Privacy photo purge
      await twinStorage.purgeSourcePhotos(twin.twinId);
      final purgedTwin = await twinStorage.getDigitalTwinById(twin.twinId);
      expect(purgedTwin!.sourcePhotosPurged, isTrue);
      expect(purgedTwin.sourceImageCount, equals(0));

      // Step E: Clean deletion
      final deleted = await twinStorage.deleteDigitalTwin(twin.twinId);
      expect(deleted, isTrue);
      final afterDelete = await twinStorage.getDigitalTwinForVehicle(vehicleId);
      expect(afterDelete, isNull);
    });

    test('5. Strict Zero-Substitution Rule: Unknown vehicle without scan has no fake 3D bike', () {
      const unverifiedVehicle = VehicleProfile(
        id: 'v_custom_scooter_unknown',
        manufacturer: 'Hero',
        model: 'Pleasure Plus',
        year: 2024,
        category: 'Scooter',
        protocolAdapter: 'generic_ble',
        model3DUrl: '', // No fake GLB
        thumbnailUrl: '',
        isVerified: false,
      );

      expect(unverifiedVehicle.has3DModel, isFalse);
      expect(unverifiedVehicle.hasDigitalTwin, isFalse);
      expect(unverifiedVehicle.model3DUrl, isEmpty);
    });
  });
}
