import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/contracts/safety_interlock.dart';
import 'package:rideos_mobile/core/contracts/safety_classification_registry.dart';
import 'package:rideos_mobile/core/contracts/safety_context_bridge.dart';
import 'package:rideos_mobile/core/vehicle_commands/models/vehicle_command.dart';
import 'package:rideos_mobile/core/vehicle_commands/services/vehicle_safety_manager.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/normalized_telemetry.dart';
import 'package:rideos_mobile/core/vehicle_protocols/models/telemetry_value.dart';
import 'package:rideos_mobile/core/device_providers/interfaces/device_provider.dart';
import 'package:rideos_mobile/core/device_providers/models/normalized_telemetry_models.dart';


void main() {
  const interlock = MotionSafetyInterlock();

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 1: MotionSafetyInterlock — Core Fail-Closed Policy
  // ═══════════════════════════════════════════════════════════════════════════

  group('MotionSafetyInterlock — Core Fail-Closed Policy', () {
    test('ALLOW: speed=0 + forbiddenWhileMoving command', () {
      final context = VehicleSafetyContext(
        speedKmh: 0.0,
        speedTrust: SpeedTrustLevel.trusted,
        isVehicleConnected: true,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isAllowed, isTrue);
      expect(verdict.decision, SafetyDecision.allow);
    });

    test('BLOCK: speed>0 + forbiddenWhileMoving command', () {
      final context = VehicleSafetyContext(
        speedKmh: 45.0,
        speedTrust: SpeedTrustLevel.trusted,
        isVehicleConnected: true,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isBlocked, isTrue);
      expect(verdict.decision, SafetyDecision.block);
    });

    test('BLOCK: speed>0 + safetySensitive command', () {
      final context = VehicleSafetyContext(
        speedKmh: 10.0,
        speedTrust: SpeedTrustLevel.trusted,
        isVehicleConnected: true,
        commandClassification: SafetyClassification.safetySensitive,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isBlocked, isTrue);
    });

    test('ALLOW: speed>0 + safeWhileMoving command', () {
      final context = VehicleSafetyContext(
        speedKmh: 120.0,
        speedTrust: SpeedTrustLevel.trusted,
        isVehicleConnected: true,
        commandClassification: SafetyClassification.safeWhileMoving,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isAllowed, isTrue);
    });

    test('ALLOW: speed>0 + conditionallySafe command', () {
      final context = VehicleSafetyContext(
        speedKmh: 80.0,
        speedTrust: SpeedTrustLevel.trusted,
        isVehicleConnected: true,
        commandClassification: SafetyClassification.conditionallySafe,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isAllowed, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 2: Fail-Closed Telemetry Provenance Checks
  // ═══════════════════════════════════════════════════════════════════════════

  group('MotionSafetyInterlock — Fail-Closed Telemetry Provenance', () {
    test('BLOCK: speed unavailable (null) for forbiddenWhileMoving', () {
      final context = VehicleSafetyContext(
        speedKmh: null,
        speedTrust: SpeedTrustLevel.unavailable,
        isVehicleConnected: true,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isBlocked, isTrue);
      expect(verdict.reason, contains('unavailable'));
    });

    test('BLOCK: speed stale for forbiddenWhileMoving', () {
      final context = VehicleSafetyContext(
        speedKmh: 0.0,
        speedTrust: SpeedTrustLevel.stale,
        isVehicleConnected: true,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
        speedAgeMs: 5000,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isBlocked, isTrue);
      expect(verdict.reason, contains('stale'));
    });

    test('BLOCK: speed NaN for forbiddenWhileMoving', () {
      final context = VehicleSafetyContext(
        speedKmh: double.nan,
        speedTrust: SpeedTrustLevel.invalid,
        isVehicleConnected: true,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isBlocked, isTrue);
      expect(verdict.reason, contains('invalid'));
    });

    test('BLOCK: speed negative for safetySensitive', () {
      final context = VehicleSafetyContext(
        speedKmh: -5.0,
        speedTrust: SpeedTrustLevel.trusted, // Even if trust says trusted, value validation catches it
        isVehicleConnected: true,
        commandClassification: SafetyClassification.safetySensitive,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isBlocked, isTrue);
    });

    test('BLOCK: speed impossibly high (>500 km/h)', () {
      final context = VehicleSafetyContext(
        speedKmh: 600.0,
        speedTrust: SpeedTrustLevel.trusted,
        isVehicleConnected: true,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isBlocked, isTrue);
    });

    test('BLOCK: speed infinite for forbiddenWhileMoving', () {
      final context = VehicleSafetyContext(
        speedKmh: double.infinity,
        speedTrust: SpeedTrustLevel.trusted,
        isVehicleConnected: true,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isBlocked, isTrue);
    });

    test('BLOCK: vehicle disconnected for forbiddenWhileMoving', () {
      final context = VehicleSafetyContext.disconnected(
        commandClassification: SafetyClassification.forbiddenWhileMoving,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isBlocked, isTrue);
      expect(verdict.reason, contains('disconnected'));
    });

    test('BLOCK: vehicle disconnected for safetySensitive', () {
      final context = VehicleSafetyContext.disconnected(
        commandClassification: SafetyClassification.safetySensitive,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isBlocked, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 3: Boundary Conditions
  // ═══════════════════════════════════════════════════════════════════════════

  group('MotionSafetyInterlock — Boundary Conditions', () {
    test('ALLOW: speed exactly 0.0 for forbiddenWhileMoving', () {
      final context = VehicleSafetyContext(
        speedKmh: 0.0,
        speedTrust: SpeedTrustLevel.trusted,
        isVehicleConnected: true,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isAllowed, isTrue);
    });

    test('BLOCK: speed 0.000001 (just above zero) for forbiddenWhileMoving', () {
      final context = VehicleSafetyContext(
        speedKmh: 0.000001,
        speedTrust: SpeedTrustLevel.trusted,
        isVehicleConnected: true,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isBlocked, isTrue);
    });

    test('ALLOW: speed exactly at max valid boundary (500.0) for safeWhileMoving', () {
      final context = VehicleSafetyContext(
        speedKmh: 500.0,
        speedTrust: SpeedTrustLevel.trusted,
        isVehicleConnected: true,
        commandClassification: SafetyClassification.safeWhileMoving,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isAllowed, isTrue);
    });

    test('BLOCK: speed at 500.01 (just above max) for forbiddenWhileMoving', () {
      final context = VehicleSafetyContext(
        speedKmh: 500.01,
        speedTrust: SpeedTrustLevel.trusted,
        isVehicleConnected: true,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
      );
      final verdict = interlock.evaluate(context);
      expect(verdict.isBlocked, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 4: No Bypass — All Origins Same Decision
  // ═══════════════════════════════════════════════════════════════════════════

  group('MotionSafetyInterlock — No Bypass Verification', () {
    // The interlock has no concept of request origin. It evaluates only
    // VehicleSafetyContext. This test verifies that the exact same context
    // produces the same decision regardless of how it was constructed.
    test('same context from any origin produces identical decision', () {
      final context = VehicleSafetyContext(
        speedKmh: 30.0,
        speedTrust: SpeedTrustLevel.trusted,
        isVehicleConnected: true,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
      );

      // Evaluate multiple times — must be deterministic
      final verdict1 = interlock.evaluate(context);
      final verdict2 = interlock.evaluate(context);
      final verdict3 = interlock.evaluate(context);

      expect(verdict1.decision, verdict2.decision);
      expect(verdict2.decision, verdict3.decision);
      expect(verdict1.isBlocked, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 5: Safety Classification Registry
  // ═══════════════════════════════════════════════════════════════════════════

  group('SafetyClassificationRegistry', () {
    test('all VehicleCommandType values are classified', () {
      for (final type in VehicleCommandType.values) {
        final classification = classifyCommand(type);
        expect(classification, isNotNull,
            reason: '$type must have a classification');
      }
    });

    test('toggleLock is forbiddenWhileMoving', () {
      expect(classifyCommand(VehicleCommandType.toggleLock),
          SafetyClassification.forbiddenWhileMoving);
    });

    test('clearFaultCodes is forbiddenWhileMoving', () {
      expect(classifyCommand(VehicleCommandType.clearFaultCodes),
          SafetyClassification.forbiddenWhileMoving);
    });

    test('toggleHeadlight is safeWhileMoving', () {
      expect(classifyCommand(VehicleCommandType.toggleHeadlight),
          SafetyClassification.safeWhileMoving);
    });

    test('triggerHorn is safeWhileMoving', () {
      expect(classifyCommand(VehicleCommandType.triggerHorn),
          SafetyClassification.safeWhileMoving);
    });

    test('setRidingMode is conditionallySafe', () {
      expect(classifyCommand(VehicleCommandType.setRidingMode),
          SafetyClassification.conditionallySafe);
    });

    test('startCharging is forbiddenWhileMoving', () {
      expect(classifyCommand(VehicleCommandType.startCharging),
          SafetyClassification.forbiddenWhileMoving);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 6: SafetyContextBridge — NormalizedTelemetry path
  // ═══════════════════════════════════════════════════════════════════════════

  group('SafetyContextBridge — fromNormalizedTelemetry', () {
    test('null telemetry → unavailable speed trust', () {
      final context = SafetyContextBridge.fromNormalizedTelemetry(
        null,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
        isVehicleConnected: false,
      );
      expect(context.speedKmh, isNull);
      expect(context.speedTrust, SpeedTrustLevel.disconnected);
    });

    test('unavailable speed → unavailable trust', () {
      final telemetry = NormalizedTelemetry.empty();
      final context = SafetyContextBridge.fromNormalizedTelemetry(
        telemetry,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
        isVehicleConnected: true,
      );
      expect(context.speedTrust, SpeedTrustLevel.unavailable);
    });

    test('live speed → trusted', () {
      final telemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(25.0, 'km/h'),
      );
      final context = SafetyContextBridge.fromNormalizedTelemetry(
        telemetry,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
        isVehicleConnected: true,
      );
      expect(context.speedTrust, SpeedTrustLevel.trusted);
      expect(context.speedKmh, 25.0);
    });

    test('stale quality speed → stale trust', () {
      final telemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue(
          value: 10.0,
          unit: 'km/h',
          available: true,
          quality: 'stale',
        ),
      );
      final context = SafetyContextBridge.fromNormalizedTelemetry(
        telemetry,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
        isVehicleConnected: true,
      );
      expect(context.speedTrust, SpeedTrustLevel.stale);
    });

    test('NaN speed value → invalid trust', () {
      final telemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(double.nan, 'km/h'),
      );
      final context = SafetyContextBridge.fromNormalizedTelemetry(
        telemetry,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
        isVehicleConnected: true,
      );
      expect(context.speedTrust, SpeedTrustLevel.invalid);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 7: SafetyContextBridge — NormalizedTelemetrySnapshot path
  // ═══════════════════════════════════════════════════════════════════════════

  group('SafetyContextBridge — fromTelemetrySnapshot', () {
    test('null snapshot + disconnected → disconnected trust', () {
      final context = SafetyContextBridge.fromTelemetrySnapshot(
        null,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
        linkState: DeviceLinkState.disconnected,
      );
      expect(context.speedTrust, SpeedTrustLevel.disconnected);
      expect(context.isVehicleConnected, isFalse);
    });

    test('valid snapshot with live speed → trusted', () {
      final now = DateTime.now();
      final snapshot = NormalizedTelemetrySnapshot(
        dataSource: TelemetryDataSource.realDevice,
        timestamp: now,
        vehicleSpeedKmh: TelemetryMetric(
          value: 0.0,
          unit: 'km/h',
          timestamp: now,
          confidence: MetricConfidence.validLive,
        ),
        engineRpm: TelemetryMetric(value: 0, unit: 'RPM', timestamp: now),
        gearPosition: TelemetryMetric(value: 0, unit: 'N', timestamp: now),
        throttlePositionPct: TelemetryMetric(value: 0.0, unit: '%', timestamp: now),
        engineLoadPct: TelemetryMetric(value: 0.0, unit: '%', timestamp: now),
        coolantTempC: TelemetryMetric(value: 85.0, unit: 'degC', timestamp: now),
        engineTempC: TelemetryMetric(value: 90.0, unit: 'degC', timestamp: now),
        intakeTempC: TelemetryMetric(value: 25.0, unit: 'degC', timestamp: now),
        batteryVoltage: TelemetryMetric(value: 12.8, unit: 'V', timestamp: now),
        batteryCurrentAmps: TelemetryMetric(value: 0.0, unit: 'A', timestamp: now),
        fuelLevelPct: TelemetryMetric(value: 100.0, unit: '%', timestamp: now),
        leanAngleDeg: TelemetryMetric(value: 0.0, unit: 'deg', timestamp: now),
        vibrationLevelG: TelemetryMetric(value: 0.0, unit: 'G', timestamp: now),
        accelerationX: TelemetryMetric(value: 0.0, unit: 'G', timestamp: now),
        accelerationY: TelemetryMetric(value: 0.0, unit: 'G', timestamp: now),
        accelerationZ: TelemetryMetric(value: 1.0, unit: 'G', timestamp: now),
      );

      final context = SafetyContextBridge.fromTelemetrySnapshot(
        snapshot,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
        linkState: DeviceLinkState.connected,
      );
      expect(context.speedTrust, SpeedTrustLevel.trusted);
      expect(context.speedKmh, 0.0);
      expect(context.isVehicleConnected, isTrue);
    });

    test('stale confidence speed → stale trust', () {
      final now = DateTime.now();
      final snapshot = NormalizedTelemetrySnapshot(
        dataSource: TelemetryDataSource.realDevice,
        timestamp: now,
        vehicleSpeedKmh: TelemetryMetric(
          value: 30.0,
          unit: 'km/h',
          timestamp: now,
          confidence: MetricConfidence.stale,
        ),
        engineRpm: TelemetryMetric(value: 0, unit: 'RPM', timestamp: now),
        gearPosition: TelemetryMetric(value: 0, unit: 'N', timestamp: now),
        throttlePositionPct: TelemetryMetric(value: 0.0, unit: '%', timestamp: now),
        engineLoadPct: TelemetryMetric(value: 0.0, unit: '%', timestamp: now),
        coolantTempC: TelemetryMetric(value: 85.0, unit: 'degC', timestamp: now),
        engineTempC: TelemetryMetric(value: 90.0, unit: 'degC', timestamp: now),
        intakeTempC: TelemetryMetric(value: 25.0, unit: 'degC', timestamp: now),
        batteryVoltage: TelemetryMetric(value: 12.8, unit: 'V', timestamp: now),
        batteryCurrentAmps: TelemetryMetric(value: 0.0, unit: 'A', timestamp: now),
        fuelLevelPct: TelemetryMetric(value: 100.0, unit: '%', timestamp: now),
        leanAngleDeg: TelemetryMetric(value: 0.0, unit: 'deg', timestamp: now),
        vibrationLevelG: TelemetryMetric(value: 0.0, unit: 'G', timestamp: now),
        accelerationX: TelemetryMetric(value: 0.0, unit: 'G', timestamp: now),
        accelerationY: TelemetryMetric(value: 0.0, unit: 'G', timestamp: now),
        accelerationZ: TelemetryMetric(value: 1.0, unit: 'G', timestamp: now),
      );

      final context = SafetyContextBridge.fromTelemetrySnapshot(
        snapshot,
        commandClassification: SafetyClassification.forbiddenWhileMoving,
        linkState: DeviceLinkState.connected,
      );
      expect(context.speedTrust, SpeedTrustLevel.stale);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 8: Hardened VehicleSafetyManager Integration
  // ═══════════════════════════════════════════════════════════════════════════

  group('VehicleSafetyManager — Hardened Integration', () {
    final manager = VehicleSafetyManager();

    test('BLOCK: null telemetry + forbiddenWhileMoving (fail-open bug fix)', () {
      final command = VehicleCommand(type: VehicleCommandType.toggleLock);
      final result = manager.evaluateCommandSafety(command, null);
      // Previously this was SAFE (the bug) — now it must be BLOCKED
      expect(result.isSafe, isFalse);
      expect(result.reason, isNotEmpty);
    });

    test('BLOCK: null telemetry + clearFaultCodes', () {
      final command = VehicleCommand(type: VehicleCommandType.clearFaultCodes);
      final result = manager.evaluateCommandSafety(command, null);
      expect(result.isSafe, isFalse);
    });

    test('ALLOW: null telemetry + safeWhileMoving (headlight toggle)', () {
      final command = VehicleCommand(type: VehicleCommandType.toggleHeadlight);
      final result = manager.evaluateCommandSafety(command, null);
      expect(result.isSafe, isTrue);
    });

    test('ALLOW: stationary with valid telemetry + toggleLock', () {
      final telemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(0.0, 'km/h'),
      );
      final command = VehicleCommand(type: VehicleCommandType.toggleLock);
      final result = manager.evaluateCommandSafety(command, telemetry);
      expect(result.isSafe, isTrue);
    });

    test('BLOCK: moving with valid telemetry + toggleLock', () {
      final telemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(50.0, 'km/h'),
      );
      final command = VehicleCommand(type: VehicleCommandType.toggleLock);
      final result = manager.evaluateCommandSafety(command, telemetry);
      expect(result.isSafe, isFalse);
    });

    test('BLOCK: engine running + startCharging (non-motion safety check preserved)', () {
      final telemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(0.0, 'km/h'),
        engineState: TelemetryValue.live('RUNNING', ''),
      );
      final command = VehicleCommand(type: VehicleCommandType.startCharging);
      final result = manager.evaluateCommandSafety(command, telemetry);
      expect(result.isSafe, isFalse);
      expect(result.reason, contains('Engine is running'));
    });

    test('BLOCK: invalid riding mode parameter (parameter validation preserved)', () {
      final telemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(0.0, 'km/h'),
      );
      final command = VehicleCommand(type: VehicleCommandType.setRidingMode, parameter: 'INVALID_MODE');
      final result = manager.evaluateCommandSafety(command, telemetry);
      expect(result.isSafe, isFalse);
      expect(result.reason, contains('Invalid riding mode'));
    });

    test('ALLOW: valid riding mode parameter while stationary', () {
      final telemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(0.0, 'km/h'),
      );
      final command = VehicleCommand(type: VehicleCommandType.setRidingMode, parameter: 'SPORT');
      final result = manager.evaluateCommandSafety(command, telemetry);
      expect(result.isSafe, isTrue);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // SECTION 9: End-to-End Safety Chain Verification
  // ═══════════════════════════════════════════════════════════════════════════

  group('End-to-End Safety Chain', () {
    final manager = VehicleSafetyManager();

    test('ALL forbiddenWhileMoving commands blocked when speed > 0', () {
      final forbiddenTypes = VehicleCommandType.values
          .where((t) => classifyCommand(t) == SafetyClassification.forbiddenWhileMoving)
          .toList();

      expect(forbiddenTypes, isNotEmpty, reason: 'Must have forbidden commands');

      final telemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(25.0, 'km/h'),
      );

      for (final type in forbiddenTypes) {
        final command = VehicleCommand(type: type);
        final result = manager.evaluateCommandSafety(command, telemetry);
        expect(result.isSafe, isFalse,
            reason: '${type.name} should be blocked while moving');
      }
    });

    test('ALL safeWhileMoving commands allowed when speed > 0', () {
      final safeTypes = VehicleCommandType.values
          .where((t) => classifyCommand(t) == SafetyClassification.safeWhileMoving)
          .toList();

      expect(safeTypes, isNotEmpty, reason: 'Must have safe commands');

      final telemetry = NormalizedTelemetry.empty().copyWith(
        speed: TelemetryValue.live(80.0, 'km/h'),
      );

      for (final type in safeTypes) {
        final command = VehicleCommand(type: type);
        final result = manager.evaluateCommandSafety(command, telemetry);
        expect(result.isSafe, isTrue,
            reason: '${type.name} should be allowed while moving');
      }
    });

    test('ALL forbiddenWhileMoving commands blocked with null telemetry', () {
      final forbiddenTypes = VehicleCommandType.values
          .where((t) => classifyCommand(t) == SafetyClassification.forbiddenWhileMoving)
          .toList();

      for (final type in forbiddenTypes) {
        final command = VehicleCommand(type: type);
        final result = manager.evaluateCommandSafety(command, null);
        expect(result.isSafe, isFalse,
            reason: '${type.name} must be blocked with null telemetry (fail-closed)');
      }
    });
  });
}
