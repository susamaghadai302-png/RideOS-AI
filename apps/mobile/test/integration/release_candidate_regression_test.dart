import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_resolution/models/active_vehicle_context.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_registry.dart';
import 'package:rideos_mobile/core/vehicle_resolution/services/vehicle_model_resolver.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/normalized_telemetry.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/telemetry_value.dart';
import 'package:rideos_mobile/core/error/app_error.dart';
import 'package:rideos_mobile/core/error/safe_retry_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Release Candidate (RC-1) E2E User Journey & Stability Tests', () {
    test('1. Fresh Install State: Empty active context without fake data', () {
      final ctx = ActiveVehicleContext.empty();

      expect(ctx.hasActiveVehicle, isFalse);
      expect(ctx.isConnected, isFalse);
      expect(ctx.hasExact3DModel, isFalse);
      expect(ctx.telemetryQuality, TelemetryQuality.unavailable);
      expect(ctx.telemetry.speed.available, isFalse);
    });

    test('2. Vehicle Registration & Protocol Resolution: Exact profile matching', () {
      final registry = VehicleRegistry();
      final r1m = registry.getProfileById('v_yamaha_r1m');

      expect(r1m, isNotNull);
      expect(r1m!.manufacturer, 'Yamaha');
      expect(r1m.protocolAdapter, 'yamaha_y_connect');

      final resolver = VehicleModelResolver();
      final modelRes = resolver.resolve(r1m);
      expect(modelRes.status, VehicleModelStatus.unavailable);
      expect(modelRes.isExact, isFalse);
      expect(modelRes.modelPath, isEmpty);
    });

    test('3. Multi-Vehicle Context Switching: Total isolation between Vehicle A and Vehicle B', () {
      final registry = VehicleRegistry();
      final r1m = registry.getProfileById('v_yamaha_r1m')!;
      final v4s = registry.getProfileById('v_ducati_v4s')!;

      var ctx = ActiveVehicleContext.empty().copyWith(
        vehicleId: r1m.id,
        profile: r1m,
        connectionStatus: VehicleConnectionStatus.connected,
        telemetryQuality: TelemetryQuality.live,
        telemetry: NormalizedTelemetry.empty().copyWith(
          speed: TelemetryValue.live(90.0, 'km/h'),
        ),
      );

      expect(ctx.vehicleId, 'v_yamaha_r1m');
      expect(ctx.telemetry.speed.value, 90.0);

      // Switch to Vehicle B (Ducati Panigale V4 S)
      final resolver = VehicleModelResolver();
      final v4sModel = resolver.resolve(v4s);

      ctx = ActiveVehicleContext(
        vehicleId: v4s.id,
        profile: v4s,
        connectionStatus: VehicleConnectionStatus.disconnected,
        modelStatus: v4sModel.status,
        model3DPath: v4sModel.modelPath,
        supportedCapabilities: v4s.specifications.keys.toList(),
        telemetry: NormalizedTelemetry.empty(), // Cleared
        telemetryQuality: TelemetryQuality.unavailable, // Reset
        activeDtcCodes: const [],
        activeTripId: null,
        lastUpdated: DateTime.now(),
      );

      expect(ctx.vehicleId, 'v_ducati_v4s');
      expect(ctx.model3DPath, 'assets/models/ducati_panigale.glb');
      expect(ctx.telemetry.speed.available, isFalse); // No cross-vehicle data leakage
      expect(ctx.isConnected, isFalse);
    });

    test('4. Graceful Error Recovery: Generates non-sensitive correlation ID on failure', () {
      final error = AppError.fromException('TimeoutException: Bluetooth connection lost');

      expect(error.category, ErrorCategory.bluetoothError);
      expect(error.errorId.startsWith('RID-2026-'), isTrue);
      expect(error.userTitle.isNotEmpty, isTrue);
      expect(error.dataSafetyNote.contains('GPS'), isTrue);
    });

    test('5. Safe Retry Policy: Prevents infinite aggressive loops', () async {
      final retryEngine = SafeRetryEngine();
      int callCount = 0;

      final result = await retryEngine.run(
        taskName: 'ble_connect_test',
        policy: const RetryPolicy(
          maxAttempts: 3,
          initialDelay: Duration(milliseconds: 10),
          maxDelay: Duration(milliseconds: 30),
          addJitter: false,
        ),
        action: () async {
          callCount++;
          if (callCount < 2) throw Exception('Simulated momentary glitch');
          return 'CONNECTED';
        },
      );

      expect(result, 'CONNECTED');
      expect(callCount, 2);
    });
  });
}
