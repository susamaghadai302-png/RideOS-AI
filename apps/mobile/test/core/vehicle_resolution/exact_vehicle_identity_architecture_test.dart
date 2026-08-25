import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_identity.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/active_vehicle_context.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/exact_vehicle_model_registry.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_model_resolver.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/model_generation_pipeline.dart';
import 'package:rideos_mobile/core/vehicle_resolution/providers/active_vehicle_context_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RideOS-AI Exact Connected Vehicle Identity Architecture Tests', () {
    late ExactVehicleModelRegistry registry;
    late VehicleModelResolver resolver;
    late ModelGenerationPipeline pipeline;

    setUp(() {
      registry = ExactVehicleModelRegistry();
      resolver = VehicleModelResolver();
      pipeline = ModelGenerationPipeline();
    });

    test('1. Authoritative Exact Registry Enforces Strict 1-to-1 Vehicle Mappings', () {
      final records = registry.allVerifiedRecords;
      expect(records.length, equals(2)); // Panigale V4 S, BMW M 1000 RR

      final seenGlbs = <String, String>{};
      for (final r in records) {
        expect(r.glbAssetPath, isNotEmpty);
        expect(r.thumbnailPath, isNotEmpty);
        expect(r.assetChecksum, startsWith('sha256:'));
        expect(seenGlbs.containsKey(r.glbAssetPath), isFalse,
            reason: 'Zero duplicate 3D model assets allowed in registry');
        seenGlbs[r.glbAssetPath] = r.assetId;
      }
    });

    test('2. Exact Model Resolution Resolves Only True OEM Assets', () {
      // 1. Yamaha YZF-R1M (Model Validation Pending — Zero Dummy Model Loaded)
      final r1mIdentity = VehicleIdentity(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'AA:BB:CC:11:22:33',
        manufacturer: 'Yamaha',
        make: 'Yamaha',
        model: 'YZF-R1M',
        variant: 'Carbon',
        modelYear: 2024,
        protocolAdapterId: 'yamaha_ccu',
        confidence: IdentityConfidence.exactMatch,
      );
      final r1mRes = resolver.resolveIdentity(r1mIdentity);
      expect(r1mRes.isExact, isFalse);
      expect(r1mRes.modelPath, isEmpty);
      expect(r1mRes.status, VehicleModelStatus.unavailable);
      expect(r1mRes.resolutionStatus, ModelResolutionStatus.modelPendingValidation);

      // 2. Ducati Panigale V4 S (Verified OEM CAD Model)
      final ducatiIdentity = VehicleIdentity(
        connectionType: ConnectionTransportType.obdGateway,
        deviceIdentifier: 'OBD-BT-0912',
        manufacturer: 'Ducati',
        make: 'Ducati',
        model: 'Panigale V4 S',
        variant: 'V4 S',
        modelYear: 2022,
        protocolAdapterId: 'ducati_dms',
        confidence: IdentityConfidence.exactMatch,
      );
      final ducatiRes = resolver.resolveIdentity(ducatiIdentity);
      expect(ducatiRes.isExact, isTrue);
      expect(ducatiRes.modelPath, 'assets/models/ducati_panigale.glb');
      expect(ducatiRes.status, VehicleModelStatus.ready);

      // 3. BMW M 1000 RR (Verified OEM CAD Model)
      final bmwIdentity = VehicleIdentity(
        connectionType: ConnectionTransportType.canGateway,
        deviceIdentifier: 'CAN-BMW-778',
        manufacturer: 'BMW',
        make: 'BMW',
        model: 'M 1000 RR',
        variant: 'M Competition',
        modelYear: 2024,
        protocolAdapterId: 'bmw_motorrad_can',
        confidence: IdentityConfidence.exactMatch,
      );
      final bmwRes = resolver.resolveIdentity(bmwIdentity);
      expect(bmwRes.isExact, isTrue);
      expect(bmwRes.modelPath, 'assets/models/bmw_m1000rr.glb');
      expect(bmwRes.status, VehicleModelStatus.ready);

      // 4. Yamaha MT-09 SP (Pending Validation - No Dummy Geometry)
      final mt09Identity = VehicleIdentity(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'AA:BB:CC:44:55:66',
        manufacturer: 'Yamaha',
        make: 'Yamaha',
        model: 'MT-09 SP',
        variant: 'SP',
        modelYear: 2023,
        protocolAdapterId: 'yamaha_ccu',
        confidence: IdentityConfidence.exactMatch,
      );
      final mt09Res = resolver.resolveIdentity(mt09Identity);
      expect(mt09Res.isExact, isFalse);
      expect(mt09Res.modelPath, isEmpty);
      expect(mt09Res.status, VehicleModelStatus.unavailable);
      expect(mt09Res.resolutionStatus, ModelResolutionStatus.modelPendingValidation);

      // 5. Suzuki Burgman Street 125 EX (Pending Validation - No Dummy Geometry)
      final suzukiIdentity = VehicleIdentity(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'SZ-BLE-125',
        manufacturer: 'Suzuki',
        make: 'Suzuki',
        model: 'Burgman Street 125',
        variant: 'EX',
        modelYear: 2023,
        protocolAdapterId: 'suzuki_ride_connect',
        confidence: IdentityConfidence.exactMatch,
      );
      final suzukiRes = resolver.resolveIdentity(suzukiIdentity);
      expect(suzukiRes.isExact, isFalse);
      expect(suzukiRes.modelPath, isEmpty);
      expect(suzukiRes.status, VehicleModelStatus.unavailable);
      expect(suzukiRes.resolutionStatus, ModelResolutionStatus.modelPendingValidation);
    });

    test('3. Zero-Substitution Rule: Vehicles Without 3D Model Receive Truthful Unavailable State', () {
      // Yamaha R15 V4 (Connected but has no 3D asset - must NEVER borrow R1M)
      final r15Identity = VehicleIdentity(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'YM-R15-883',
        manufacturer: 'Yamaha',
        make: 'Yamaha',
        model: 'YZF-R15 V4',
        variant: 'M',
        modelYear: 2024,
        protocolAdapterId: 'yamaha_ccu',
        confidence: IdentityConfidence.exactMatch,
      );
      final r15Res = resolver.resolveIdentity(r15Identity);
      expect(r15Res.isExact, isFalse);
      expect(r15Res.modelPath, isEmpty, reason: 'R15 must NEVER borrow R1M model');
      expect(r15Res.status, VehicleModelStatus.unavailable);

      // KTM 390 Duke (No 3D asset)
      final ktmIdentity = VehicleIdentity(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'KTM-BLE-390',
        manufacturer: 'KTM',
        make: 'KTM',
        model: '390 Duke',
        variant: 'Gen 3',
        modelYear: 2024,
        protocolAdapterId: 'ktm_my_ride',
        confidence: IdentityConfidence.exactMatch,
      );
      final ktmRes = resolver.resolveIdentity(ktmIdentity);
      expect(ktmRes.isExact, isFalse);
      expect(ktmRes.modelPath, isEmpty);
      expect(ktmRes.status, VehicleModelStatus.unavailable);
    });

    test('4. Confidence Tiers: UNKNOWN, PARTIAL_MATCH, and CONFLICT Never Automatically Load 3D Models', () {
      // Unknown device
      final unknownIdentity = VehicleIdentity.unknown(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'UNKNOWN:MAC:00',
        rawAdvertisementName: 'ESP32_OBD_DONGLE',
      );
      final unknownRes = resolver.resolveIdentity(unknownIdentity);
      expect(unknownRes.isExact, isFalse);
      expect(unknownRes.modelPath, isEmpty);
      expect(unknownRes.status, VehicleModelStatus.unavailable);
      expect(unknownRes.resolutionStatus, ModelResolutionStatus.identityUncertain);

      // Conflicting signature
      final conflictIdentity = VehicleIdentity(
        connectionType: ConnectionTransportType.obdGateway,
        deviceIdentifier: 'OBD-CONFLICT-1',
        manufacturer: 'Yamaha',
        make: 'Yamaha',
        model: 'YZF-R1M',
        protocolAdapterId: 'obd_iso15765',
        confidence: IdentityConfidence.conflict,
      );
      final conflictRes = resolver.resolveIdentity(conflictIdentity);
      expect(conflictRes.isExact, isFalse);
      expect(conflictRes.modelPath, isEmpty);
      expect(conflictRes.resolutionStatus, ModelResolutionStatus.identityConflict);
    });

    test('5. Connection Session Isolation & Sequential Vehicle Switching', () {
      final notifier = ActiveVehicleContextNotifier();

      // Step 1: Connect BMW M 1000 RR (Official Validated Model)
      final bmw = VehicleIdentity(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'MAC-BMW-01',
        manufacturer: 'BMW',
        make: 'BMW',
        model: 'M 1000 RR',
        modelYear: 2024,
        protocolAdapterId: 'bmw_can',
        confidence: IdentityConfidence.exactMatch,
      );
      notifier.switchIdentity(bmw);

      expect(notifier.state.model3DPath, 'assets/models/bmw_m1000rr.glb');
      expect(notifier.state.hasExact3DModel, isTrue);

      // Step 2: Disconnect -> State & Model MUST be purged immediately
      notifier.disconnectAndPurge();
      expect(notifier.state.model3DPath, isEmpty);
      expect(notifier.state.vehicleId, isEmpty);
      expect(notifier.state.hasExact3DModel, isFalse);

      // Step 3: Connect Yamaha MT-09 SP -> Model pending validation, ZERO residue
      final mt09 = VehicleIdentity(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'MAC-MT09-02',
        manufacturer: 'Yamaha',
        make: 'Yamaha',
        model: 'MT-09 SP',
        modelYear: 2023,
        protocolAdapterId: 'yamaha_ccu',
        confidence: IdentityConfidence.exactMatch,
      );
      notifier.switchIdentity(mt09);

      expect(notifier.state.model3DPath, isEmpty);
      expect(notifier.state.hasExact3DModel, isFalse);
      expect(notifier.state.modelResolutionStatus, ModelResolutionStatus.modelPendingValidation);

      // Step 4: Connect Unknown Vehicle -> Model remains empty
      final unknown = VehicleIdentity.unknown(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'MAC-UNK-03',
      );
      notifier.switchIdentity(unknown);

      expect(notifier.state.model3DPath, isEmpty);
      expect(notifier.state.hasExact3DModel, isFalse);
      expect(notifier.state.modelResolutionStatus, ModelResolutionStatus.identityUncertain);

      // Step 5: Connect Ducati Panigale V4 S -> Panigale model appears
      final ducati = VehicleIdentity(
        connectionType: ConnectionTransportType.obdGateway,
        deviceIdentifier: 'MAC-DUCATI-04',
        manufacturer: 'Ducati',
        make: 'Ducati',
        model: 'Panigale V4 S',
        modelYear: 2022,
        protocolAdapterId: 'ducati_dms',
        confidence: IdentityConfidence.exactMatch,
      );
      notifier.switchIdentity(ducati);

      expect(notifier.state.model3DPath, 'assets/models/ducati_panigale.glb');
      expect(notifier.state.hasExact3DModel, isTrue);
    });

    test('6. Model Generation Pipeline Safe Lifecycle Transitions', () async {
      // Unmodelled vehicle creates safe request
      final unmodelledIdentity = VehicleIdentity(
        connectionType: ConnectionTransportType.ble,
        deviceIdentifier: 'YM-AEROX-1',
        manufacturer: 'Yamaha',
        make: 'Yamaha',
        model: 'Aerox 155',
        modelYear: 2024,
        protocolAdapterId: 'yamaha_ccu',
        confidence: IdentityConfidence.exactMatch,
      );

      final result = await pipeline.processIdentity(unmodelledIdentity);
      expect(result.status, ModelResolutionStatus.modelNotAvailable);
      expect(result.generationRequest, isNotNull);
      expect(result.generationRequest!.identity.model, 'Aerox 155');
      expect(result.assetRecord, isNull);
    });
  });
}
