import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/sos_safety/core/crash_detection_algorithm.dart';

void main() {
  group('Phase 3 - Multi-Signal Crash & Impact Detection Tests', () {
    late CrashDetectionAlgorithm algorithm;

    setUp(() {
      algorithm = const CrashDetectionAlgorithm();
    });

    test('High-G impact + deceleration + roll triggers high confidence crash', () {
      final evaluation = algorithm.evaluateCrashConfidence(
        accelMagnitudeG: 6.2, // > 4.5G
        rollAngleDeg: 78.0, // > 65 deg
        currentSpeedKmh: 0.0,
        speedDropKmh: 45.0, // drop from 45 to 0
        durationSecSinceSpeedDrop: 3.0,
      );

      expect(evaluation.isCrashDetected, isTrue);
      expect(evaluation.confidenceScore, greaterThanOrEqualTo(0.65));
      expect(evaluation.source, CrashDetectionSource.phoneSensors);
      expect(evaluation.primaryTriggerReason, contains('High G-force impact'));
    });

    test('Static phone handling with low speed does not trigger false positive crash', () {
      final evaluation = algorithm.evaluateCrashConfidence(
        accelMagnitudeG: 1.8, // Normal movement
        rollAngleDeg: 12.0,
        currentSpeedKmh: 0.0,
        speedDropKmh: 0.0,
        durationSecSinceSpeedDrop: 0.0,
      );

      expect(evaluation.isCrashDetected, isFalse);
      expect(evaluation.confidenceScore, lessThan(0.30));
    });

    test('BLE ECU source is correctly attributed when connected', () {
      final evaluation = algorithm.evaluateCrashConfidence(
        accelMagnitudeG: 5.5,
        rollAngleDeg: 80.0,
        currentSpeedKmh: 0.0,
        speedDropKmh: 50.0,
        durationSecSinceSpeedDrop: 2.5,
        isBleEcuConnected: true,
      );

      expect(evaluation.isCrashDetected, isTrue);
      expect(evaluation.source, CrashDetectionSource.motorcycleCcuBle);
    });

    test('Lean over alone without speed drop or impact does not trigger crash', () {
      // Normal cornering lean (e.g. 45 deg while riding at 60 km/h)
      final evaluation = algorithm.evaluateCrashConfidence(
        accelMagnitudeG: 1.4,
        rollAngleDeg: 45.0,
        currentSpeedKmh: 60.0,
        speedDropKmh: 0.0,
        durationSecSinceSpeedDrop: 0.0,
      );

      expect(evaluation.isCrashDetected, isFalse);
    });
  });
}
