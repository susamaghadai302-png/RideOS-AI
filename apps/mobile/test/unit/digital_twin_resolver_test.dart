import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/digital_twin/domain/models.dart';
import 'package:rideos_mobile/core/digital_twin/services/digital_twin_resolver.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/vehicle_identity.dart';

void main() {
  group('DigitalTwinResolver Tests', () {
    late DigitalTwinResolver resolver;

    setUp(() {
      resolver = DigitalTwinResolver();
    });

    test('Null identity defaults to Level 4 (2D)', () {
      final result = resolver.resolve(null);
      
      expect(result.fidelity, equals(DigitalTwinFidelity.level42D));
      expect(result.reason, contains('No vehicle identity'));
    });

    test('Exact match with verified OEM model resolves to Level 1 (Exact 3D)', () {
      final identity = VehicleIdentity(
        connectionType: ConnectionTransportType.manualSelection,
        deviceIdentifier: 'test-device',
        manufacturer: 'Ducati',
        make: 'Ducati',
        model: 'Panigale V4 S',
        variant: 'V4 S',
        modelYear: 2022,
        protocolAdapterId: 'generic_ble',
        confidence: IdentityConfidence.exactMatch,
      );

      final result = resolver.resolve(identity);
      
      expect(result.fidelity, equals(DigitalTwinFidelity.level1Exact3D));
      expect(result.asset?.assetId, equals('ducati_panigale_v4s'));
      expect(result.asset?.verificationStatus, equals(DigitalTwinAssetVerification.verified));
      expect(result.asset?.provenance, equals('OEM_CAD'));
    });

    test('Exact match WITHOUT verified model falls back to Procedural Level 3 (missing Level 2)', () {
      final identity = VehicleIdentity(
        connectionType: ConnectionTransportType.manualSelection,
        deviceIdentifier: 'test-device',
        manufacturer: 'Yamaha',
        make: 'Yamaha',
        model: 'YZF-R1M',
        variant: 'Carbon',
        modelYear: 2022,
        protocolAdapterId: 'generic_ble',
        confidence: IdentityConfidence.exactMatch,
      );

      final result = resolver.resolve(identity);
      
      // 'yamaha_yzf_r1m' is 'pending_cad_validation'. We removed the fake generic_motorcycle.glb Level 2 fallback.
      // Therefore, it must gracefully drop straight to Level 3.
      expect(result.fidelity, equals(DigitalTwinFidelity.level3Procedural));
      expect(result.asset?.assetId, equals('procedural_Yamaha_YZF-R1M'));
      expect(result.asset?.provenance, equals('PROCEDURAL'));
    });

    test('Unknown identity resolves to Procedural Wireframe (Level 3) if procedurally supported', () {
      final identity = VehicleIdentity(
        connectionType: ConnectionTransportType.manualSelection,
        deviceIdentifier: 'test-device',
        manufacturer: 'UnknownBrand',
        make: 'UnknownBrand',
        model: 'UnknownModel123',
        modelYear: 2022,
        protocolAdapterId: 'generic_ble',
        confidence: IdentityConfidence.unknown,
      );

      final result = resolver.resolve(identity);
      
      expect(result.fidelity, equals(DigitalTwinFidelity.level3Procedural));
      expect(result.asset?.assetId, equals('procedural_UnknownBrand_UnknownModel123'));
    });
  });
}
