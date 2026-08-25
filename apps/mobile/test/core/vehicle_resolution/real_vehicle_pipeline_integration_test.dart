import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_identity.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/active_vehicle_context.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/unified_vehicle_identity_engine.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/persistent_exact_model_storage.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_model_generation_engine.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_model_resolver.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/model_generation_pipeline.dart';
import 'package:rideos_mobile/core/vehicle_resolution/providers/active_vehicle_context_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RideOS-AI Complete Real Vehicle -> Exact 3D Model Pipeline Tests', () {
    late UnifiedVehicleIdentityEngine identityEngine;
    late PersistentExactModelStorage persistentStorage;
    late VehicleModelGenerationEngine generationEngine;
    late VehicleModelResolver resolver;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      identityEngine = UnifiedVehicleIdentityEngine();
      persistentStorage = PersistentExactModelStorage();
      generationEngine = VehicleModelGenerationEngine();
      resolver = VehicleModelResolver();
      await persistentStorage.clearAll();
    });

    test('1. Multi-Vehicle Matrix: Verified OEM CAD Models vs Pending Validation Models', () {
      final oemVehicles = [
        {
          'make': 'Ducati',
          'model': 'Panigale V4 S',
          'expectedGlb': 'assets/models/ducati_panigale.glb',
        },
        {
          'make': 'BMW',
          'model': 'M 1000 RR',
          'expectedGlb': 'assets/models/bmw_m1000rr.glb',
        },
      ];

      for (final v in oemVehicles) {
        final identity = VehicleIdentity(
          connectionType: ConnectionTransportType.ble,
          deviceIdentifier: 'BLE-TEST-${v['model']}',
          manufacturer: v['make']!,
          make: v['make']!,
          model: v['model']!,
          confidence: IdentityConfidence.exactMatch,
          protocolAdapterId: 'oem_test_protocol',
        );

        final res = resolver.resolveIdentity(identity);
        expect(res.isExact, isTrue);
        expect(res.status, VehicleModelStatus.ready);
        expect(res.resolutionStatus, ModelResolutionStatus.modelReady);
        expect(res.modelPath, v['expectedGlb'],
            reason: '${v['model']} must resolve to its exact authentic OEM asset');
      }

      final pendingVehicles = [
        {'make': 'Yamaha', 'model': 'YZF-R1M'},
        {'make': 'Yamaha', 'model': 'MT-09 SP'},
        {'make': 'Suzuki', 'model': 'Burgman Street 125'},
        {'make': 'Universal', 'model': 'OBD-II Gateway'},
      ];

      for (final v in pendingVehicles) {
        final identity = VehicleIdentity(
          connectionType: ConnectionTransportType.ble,
          deviceIdentifier: 'BLE-TEST-${v['model']}',
          manufacturer: v['make']!,
          make: v['make']!,
          model: v['model']!,
          confidence: IdentityConfidence.exactMatch,
          protocolAdapterId: 'oem_test_protocol',
        );

        final res = resolver.resolveIdentity(identity);
        expect(res.isExact, isFalse);
        expect(res.status, VehicleModelStatus.unavailable);
        expect(res.resolutionStatus, ModelResolutionStatus.modelPendingValidation);
        expect(res.modelPath, isEmpty, reason: 'Pending validation model must not load dummy geometry');
      }
    });

    test('2. Real USB/OBD Extraction: Mode 09 VIN & ECU Calibration Decoding', () {
      // Test 2a: Yamaha R1M VIN & ECU Cal ID (Truthful Pending Validation)
      final r1mObdIdentity = identityEngine.extractFromObd(
        deviceIdentifier: 'USB-OBD-STN2120',
        rawVin: 'JY4RN32E0RA001234', // WMI: JY4 -> Yamaha, Year: R -> 2024
        rawEcuCalibrationId: '2CR-8591A-00-R1M',
        rawEcuName: 'DENSO_YAMAHA_ECU_CP4',
      );

      expect(r1mObdIdentity.make, 'Yamaha');
      expect(r1mObdIdentity.model, 'YZF-R1M');
      expect(r1mObdIdentity.modelYear, 2024);
      expect(r1mObdIdentity.confidence, IdentityConfidence.exactMatch);
      expect(r1mObdIdentity.fieldProvenance['vin'], IdentityFieldProvenance.vinDecode);

      final r1mRes = resolver.resolveIdentity(r1mObdIdentity);
      expect(r1mRes.modelPath, isEmpty);
      expect(r1mRes.status, VehicleModelStatus.unavailable);

      // Test 2b: Ducati Panigale V4 S VIN & ECU Cal ID
      final ducatiObdIdentity = identityEngine.extractFromObd(
        deviceIdentifier: 'CAN-DMS-DEVICE-01',
        rawVin: 'ZDM123456NA009876', // WMI: ZDM -> Ducati, Year: N -> 2022
        rawEcuCalibrationId: 'V4S-DMS-CAL-991',
      );
      expect(ducatiObdIdentity.make, 'Ducati');
      expect(ducatiObdIdentity.model, 'Panigale V4 S');
      expect(ducatiObdIdentity.confidence, IdentityConfidence.exactMatch);

      final ducatiRes = resolver.resolveIdentity(ducatiObdIdentity);
      expect(ducatiRes.modelPath, 'assets/models/ducati_panigale.glb');
    });

    test('3. Real Model Generation Lifecycle, Geometry Validation & Checksum Verification', () async {
      // Known vehicle without pre-bundled OEM GLB (Triumph Street Triple 765 RS)
      final triumphIdentity = VehicleIdentity(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'TRIUMPH-BLE-765',
        manufacturer: 'Triumph',
        make: 'Triumph',
        model: 'Street Triple 765 RS',
        modelYear: 2024,
        protocolAdapterId: 'my_triumph_connectivity',
        confidence: IdentityConfidence.exactMatch,
      );

      final progressEvents = <ModelGenerationProgressEvent>[];
      final sub = generationEngine.progressStream.listen(progressEvents.add);

      // Execute full generation & validation pipeline
      final result = await generationEngine.processAndGenerate(triumphIdentity);
      await Future.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      expect(result.status, ModelResolutionStatus.modelReady);
      expect(result.assetRecord, isNotNull);
      expect(result.assetRecord!.glbAssetPath, startsWith('assets/3d/scans/'));
      expect(result.assetRecord!.assetChecksum, startsWith('sha256:'));
      expect(progressEvents.isNotEmpty, isTrue);

      // Verify stages occurred in correct sequence
      final statuses = progressEvents.map((e) => e.status).toList();
      expect(statuses, contains(ModelResolutionStatus.identifyingVehicle));
      expect(statuses, contains(ModelResolutionStatus.identityVerified));
      expect(statuses, contains(ModelResolutionStatus.modelGenerationPending));
      expect(statuses, contains(ModelResolutionStatus.modelGenerationInProgress));
      expect(statuses, contains(ModelResolutionStatus.modelValidationPending));
      expect(statuses, contains(ModelResolutionStatus.modelReady));
    });

    test('4. Persistence & Reconnect: Reconnecting Same Vehicle Immediately Reloads Validated Model', () async {
      final aeroxIdentity = VehicleIdentity(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'YM-AEROX-PERSIST-1',
        manufacturer: 'Yamaha',
        make: 'Yamaha',
        model: 'Aerox 155',
        modelYear: 2024,
        vin: 'JY1AEROX123456789',
        protocolAdapterId: 'yamaha_ccu',
        confidence: IdentityConfidence.exactMatch,
      );

      // Step 1: Initial generation & validation
      final initialResult = await generationEngine.processAndGenerate(aeroxIdentity);
      expect(initialResult.status, ModelResolutionStatus.modelReady);
      final originalPath = initialResult.assetRecord!.glbAssetPath;
      final originalChecksum = initialResult.assetRecord!.assetChecksum;

      // Step 2: Disconnect -> Purge active context
      final notifier = ActiveVehicleContextNotifier();
      notifier.switchIdentity(aeroxIdentity);
      expect(notifier.state.model3DPath, originalPath);

      notifier.disconnectAndPurge();
      expect(notifier.state.model3DPath, isEmpty);
      expect(notifier.state.vehicleId, isEmpty);

      // Step 3: Reconnect Aerox 155 -> Must immediately resolve persisted model without re-generating
      final reconnectResult = await generationEngine.processAndGenerate(aeroxIdentity);
      expect(reconnectResult.status, ModelResolutionStatus.modelReady);
      expect(reconnectResult.assetRecord!.glbAssetPath, originalPath);
      expect(reconnectResult.assetRecord!.assetChecksum, originalChecksum);

      // Resolver also resolves it directly from persistent storage
      final directResolution = resolver.resolveIdentity(aeroxIdentity);
      expect(directResolution.status, VehicleModelStatus.ready);
      expect(directResolution.modelPath, originalPath);
    });

    test('5. Multi-Vehicle Sequential Isolation & Zero Cross-Vehicle State Leakage', () {
      final notifier = ActiveVehicleContextNotifier();

      // Sequence A: Connect Ducati Panigale V4 S (Verified OEM)
      final ducati = VehicleIdentity(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'MAC-DUCATI',
        manufacturer: 'Ducati',
        make: 'Ducati',
        model: 'Panigale V4 S',
        confidence: IdentityConfidence.exactMatch,
        protocolAdapterId: 'ducati_dms',
      );
      notifier.switchIdentity(ducati);
      expect(notifier.state.model3DPath, 'assets/models/ducati_panigale.glb');

      // Sequence B: Disconnect -> Must be empty
      notifier.disconnectAndPurge();
      expect(notifier.state.model3DPath, isEmpty);

      // Sequence C: Connect BMW M 1000 RR -> Must have M1000RR and ZERO Ducati
      final bmw = VehicleIdentity(
        connectionType: ConnectionTransportType.canGateway,
        deviceIdentifier: 'MAC-BMW',
        manufacturer: 'BMW',
        make: 'BMW',
        model: 'M 1000 RR',
        confidence: IdentityConfidence.exactMatch,
        protocolAdapterId: 'bmw_can',
      );
      notifier.switchIdentity(bmw);
      expect(notifier.state.model3DPath, 'assets/models/bmw_m1000rr.glb');

      // Sequence D: Disconnect -> Must be empty
      notifier.disconnectAndPurge();
      expect(notifier.state.model3DPath, isEmpty);

      // Sequence E: Connect Unknown Vehicle -> Must receive MODEL_NOT_AVAILABLE with ZERO BMW leakage
      final unknown = VehicleIdentity.unknown(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'MAC-UNKNOWN-99',
      );
      notifier.switchIdentity(unknown);
      expect(notifier.state.model3DPath, isEmpty);
      expect(notifier.state.hasExact3DModel, isFalse);
      expect(notifier.state.modelResolutionStatus, ModelResolutionStatus.identityUncertain);

      // Sequence F: Disconnect -> Must be empty
      notifier.disconnectAndPurge();

      // Sequence G: Connect Suzuki Burgman 125 -> Must have empty model (pending validation)
      final burgman = VehicleIdentity(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'MAC-BURGMAN',
        manufacturer: 'Suzuki',
        make: 'Suzuki',
        model: 'Burgman Street 125',
        confidence: IdentityConfidence.exactMatch,
        protocolAdapterId: 'suzuki_ble',
      );
      notifier.switchIdentity(burgman);
      expect(notifier.state.model3DPath, isEmpty);
      expect(notifier.state.modelResolutionStatus, ModelResolutionStatus.modelPendingValidation);
    });

    test('6. Conflicting or Partial Signatures Never Receive Exact 3D Models', () {
      // Conflicting signature
      final conflict = VehicleIdentity(
        connectionType: ConnectionTransportType.obdGateway,
        deviceIdentifier: 'CONFLICT-DEV',
        manufacturer: 'Yamaha',
        make: 'Yamaha',
        model: 'YZF-R1M',
        confidence: IdentityConfidence.conflict,
        protocolAdapterId: 'obd2',
      );

      final conflictRes = resolver.resolveIdentity(conflict);
      expect(conflictRes.status, VehicleModelStatus.unavailable);
      expect(conflictRes.modelPath, isEmpty);
      expect(conflictRes.resolutionStatus, ModelResolutionStatus.identityConflict);

      // Partial match (Generic brand without exact model)
      final partial = VehicleIdentity(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'PARTIAL-DEV',
        manufacturer: 'Yamaha',
        make: 'Yamaha',
        model: 'Connected Two-Wheeler',
        confidence: IdentityConfidence.partialMatch,
        protocolAdapterId: 'yamaha_ccu',
      );

      final partialRes = resolver.resolveIdentity(partial);
      expect(partialRes.status, VehicleModelStatus.unavailable);
      expect(partialRes.modelPath, isEmpty);
      expect(partialRes.resolutionStatus, ModelResolutionStatus.identityUncertain);
    });
  });
}
