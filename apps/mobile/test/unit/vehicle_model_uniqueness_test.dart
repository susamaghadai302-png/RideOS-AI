import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_registry.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_model_registry.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/exact_vehicle_model_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vehicle 3D Model Architecture & Strict Uniqueness Tests', () {
    late VehicleRegistry registry;
    late VehicleModelRegistry modelRegistry;
    late ExactVehicleModelRegistry exactRegistry;

    setUp(() {
      registry = VehicleRegistry();
      modelRegistry = VehicleModelRegistry();
      exactRegistry = ExactVehicleModelRegistry();
    });

    test('Verified OEM vehicles must have distinct, unique 3D model paths with zero reuse', () {
      final r1m = registry.getProfileById('v_yamaha_r1m')!;
      final panigale = registry.getProfileById('v_ducati_v4s')!;
      final m1000rr = registry.getProfileById('v_bmw_m1000rr')!;
      final mt09 = registry.getProfileById('v_yamaha_mt09_sp')!;
      final burgman = registry.getProfileById('v_suzuki_burgman125')!;
      final obd = registry.getProfileById('v_generic_obd2')!;

      // 1. Assert Yamaha YZF-R1M has NO dummy primitive GLB (Pending Validation)
      expect(r1m.model3DUrl, isEmpty);
      expect(r1m.has3DModel, isFalse);

      // 2. Assert Ducati Panigale V4 S has its OWN dedicated verified GLB
      expect(panigale.model3DUrl, equals('assets/models/ducati_panigale.glb'));
      expect(panigale.model3DUrl, isNot(equals(m1000rr.model3DUrl)));

      // 3. Assert BMW M 1000 RR has its OWN dedicated verified GLB
      expect(m1000rr.model3DUrl, equals('assets/models/bmw_m1000rr.glb'));

      // 4. Assert Yamaha MT-09 SP has NO dummy primitive GLB (Pending Validation)
      expect(mt09.model3DUrl, isEmpty);
      expect(mt09.has3DModel, isFalse);

      // 5. Assert Suzuki Burgman 125 EX has NO dummy primitive GLB (Pending Validation)
      expect(burgman.model3DUrl, isEmpty);
      expect(burgman.has3DModel, isFalse);
      expect(burgman.category, equals('Scooter'));

      // 6. Assert Universal OBD-II has NO fake 3D bike model
      expect(obd.model3DUrl, isEmpty);
      expect(obd.category, equals('Universal OBD-II'));
    });

    test('VehicleModelRegistry configurations match VehicleRegistry 1-to-1', () {
      final verifiedWithModels = ['v_ducati_v4s', 'v_bmw_m1000rr'];
      for (final id in verifiedWithModels) {
        final profile = registry.getProfileById(id)!;
        final config = modelRegistry.getModelConfig(id);

        expect(config.modelAvailable, isTrue);
        expect(config.modelPath, equals(profile.model3DUrl));
        expect(config.thumbnailPath, equals(profile.thumbnailUrl));
      }

      final pendingModels = ['v_yamaha_r1m', 'v_yamaha_mt09_sp', 'v_suzuki_burgman125', 'v_generic_obd2'];
      for (final id in pendingModels) {
        final config = modelRegistry.getModelConfig(id);
        expect(config.modelAvailable, isFalse);
        expect(config.modelPath, isEmpty);
      }
    });

    test('Vehicle specifications strictly match authentic manufacturer data', () {
      final mt09 = registry.getProfileById('v_yamaha_mt09_sp')!;
      expect(mt09.displacementCc, equals(890));
      expect(mt09.powerBhp, closeTo(117.3, 0.1));

      final r1m = registry.getProfileById('v_yamaha_r1m')!;
      expect(r1m.powerBhp, closeTo(197.3, 0.1));

      final panigale = registry.getProfileById('v_ducati_v4s')!;
      expect(panigale.powerBhp, closeTo(215.5, 0.1));

      final m1000rr = registry.getProfileById('v_bmw_m1000rr')!;
      expect(m1000rr.powerBhp, closeTo(212.0, 0.1));

      final burgman = registry.getProfileById('v_suzuki_burgman125')!;
      expect(burgman.powerBhp, closeTo(8.5, 0.1));
    });
  });
}
