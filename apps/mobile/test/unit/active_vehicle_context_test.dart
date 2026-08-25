import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/active_vehicle_context.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/data_freshness_policy.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_model_resolver.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_status_engine.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_animation_controller.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_registry.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/normalized_telemetry.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/telemetry_value.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActiveVehicleContext Model Tests', () {
    test('Empty context reflects disconnected and unavailable state', () {
      final ctx = ActiveVehicleContext.empty();

      expect(ctx.hasActiveVehicle, isFalse);
      expect(ctx.isConnected, isFalse);
      expect(ctx.hasExact3DModel, isFalse);
      expect(ctx.isTelemetryLive, isFalse);
      expect(ctx.telemetryQuality, TelemetryQuality.unavailable);
    });

    test('CopyWith updates properties immutably', () {
      final ctx = ActiveVehicleContext.empty().copyWith(
        vehicleId: 'v_yamaha_r1m',
        connectionStatus: VehicleConnectionStatus.connected,
        telemetryQuality: TelemetryQuality.live,
      );

      expect(ctx.vehicleId, 'v_yamaha_r1m');
      expect(ctx.isConnected, isTrue);
      expect(ctx.isTelemetryLive, isTrue);
    });
  });

  group('DataFreshnessPolicy Tests', () {
    test('Classifies recent packet as live', () {
      final now = DateTime.now();
      final quality = DataFreshnessPolicy.evaluate(
        lastPacketTime: now.subtract(const Duration(milliseconds: 500)),
        isConnected: true,
      );

      expect(quality, TelemetryQuality.live);
    });

    test('Classifies 5-second delayed packet as stale', () {
      final now = DateTime.now();
      final quality = DataFreshnessPolicy.evaluate(
        lastPacketTime: now.subtract(const Duration(seconds: 5)),
        isConnected: true,
      );

      expect(quality, TelemetryQuality.stale);
    });

    test('Classifies disconnected vehicle as unavailable', () {
      final quality = DataFreshnessPolicy.evaluate(
        lastPacketTime: DateTime.now(),
        isConnected: false,
      );

      expect(quality, TelemetryQuality.unavailable);
    });
  });

  group('VehicleModelResolver Tests', () {
    test('Resolves exact 3D asset for Ducati and pending validation for Yamaha', () {
      final registry = VehicleRegistry();
      final resolver = VehicleModelResolver();

      final r1m = registry.getProfileById('v_yamaha_r1m');
      final resR1m = resolver.resolve(r1m);
      expect(resR1m.status, VehicleModelStatus.unavailable);
      expect(resR1m.isExact, isFalse);
      expect(resR1m.modelPath, isEmpty);

      final v4s = registry.getProfileById('v_ducati_v4s');
      final resV4s = resolver.resolve(v4s);
      expect(resV4s.status, VehicleModelStatus.ready);
      expect(resV4s.isExact, isTrue);
      expect(resV4s.modelPath, 'assets/models/ducati_panigale.glb');
    });

    test('Marks generic vehicle as unavailable without fake 3D asset', () {
      final registry = VehicleRegistry();
      final resolver = VehicleModelResolver();

      final generic = registry.getProfileById('v_generic_obd2');
      final resGeneric = resolver.resolve(generic);
      expect(resGeneric.status, VehicleModelStatus.unavailable);
      expect(resGeneric.isExact, isFalse);
      expect(resGeneric.modelPath, isEmpty);
    });
  });

  group('VehicleStatusEngine & AnimationController Tests', () {
    test('VehicleStatusEngine detects real warnings and alerts', () {
      final registry = VehicleRegistry();
      final statusEngine = VehicleStatusEngine();

      final r1m = registry.getProfileById('v_yamaha_r1m')!;
      final telemetryWithWarning = NormalizedTelemetry.empty().copyWith(
        engineTemperature: TelemetryValue.live(112, '°C'),
        batteryVoltage: TelemetryValue.live(11.2, 'V'),
      );

      final ctx = ActiveVehicleContext.empty().copyWith(
        vehicleId: r1m.id,
        profile: r1m,
        connectionStatus: VehicleConnectionStatus.connected,
        telemetry: telemetryWithWarning,
        telemetryQuality: TelemetryQuality.live,
        activeDtcCodes: ['P0300'],
      );

      final report = statusEngine.evaluate(ctx);
      expect(report.isOperational, isFalse);
      expect(report.activeDtcCount, 1);
      expect(report.activeWarnings.length, 3); // Overheat, Low Voltage, DTC
      expect(report.statusSummary.contains('Alerts'), isTrue);
    });

    test('VehicleAnimationController translates telemetry into visual animation state', () {
      final registry = VehicleRegistry();
      final animCtrl = VehicleAnimationController();

      final r1m = registry.getProfileById('v_yamaha_r1m')!;
      final telemetryActive = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(75.0, 'km/h'),
        rpm: TelemetryValue.live(9200, 'RPM'),
        leanAngle: TelemetryValue.live(32.0, 'deg'),
      );

      final ctx = ActiveVehicleContext.empty().copyWith(
        vehicleId: r1m.id,
        profile: r1m,
        connectionStatus: VehicleConnectionStatus.connected,
        telemetry: telemetryActive,
        telemetryQuality: TelemetryQuality.live,
      );

      final visual = animCtrl.computeVisualState(ctx);
      expect(visual.mode, VisualAnimationMode.activeRide);
      expect(visual.speedKmh, 75.0);
      expect(visual.leanAngleDeg, 32.0);
      expect(visual.isEngineRunning, isTrue);
    });
  });
}
