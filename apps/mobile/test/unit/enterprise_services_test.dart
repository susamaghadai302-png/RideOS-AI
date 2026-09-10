import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/di/service_locator.dart';
import 'package:rideos_mobile/core/events/rideos_event_bus.dart';
import 'package:rideos_mobile/core/feature_flags/feature_flag_service.dart';
import 'package:rideos_mobile/core/security/input_sanitizer.dart';
import 'package:rideos_mobile/core/security/security_service.dart';
import 'package:rideos_mobile/core/offline/offline_sync_engine.dart';
import 'package:rideos_mobile/features/crash_detection/core/services/crash_detection_engine.dart';
import 'package:rideos_mobile/features/telematics/core/services/digital_twin_service.dart';

void main() {
  group('Enterprise Core Services Unit Tests', () {
    test('ServiceLocator initializes singletons properly', () {
      getIt.setupLocator();
      expect(getIt.isInitialized, isTrue);
      expect(getIt.securityService, isNotNull);
      expect(getIt.offlineSyncEngine, isNotNull);
      expect(getIt.digitalTwinService, isNotNull);
      expect(getIt.v2vMeshService, isNotNull);
      expect(getIt.smartCityService, isNotNull);
    });

    test('InputSanitizer validates email and password correctly', () {
      expect(InputSanitizer.isValidEmail('rider@example.com'), isTrue);
      expect(InputSanitizer.isValidEmail('invalid-email'), isFalse);

      expect(InputSanitizer.isStrongPassword('superSecret123'), isTrue);
      expect(InputSanitizer.isStrongPassword('123'), isFalse);

      final sanitized = InputSanitizer.sanitizeString("<script>alert('hack')</script>");
      expect(sanitized.contains('<script>'), isFalse);
    });

    test('SecurityService encrypts and decrypts payload with checksum tag', () {
      final secService = SecurityService();
      const rawPayload = '{"riderId":"123","speed":110.5}';

      final encrypted = secService.encryptPayload(rawPayload);
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(rawPayload)));

      final decrypted = secService.decryptPayload(encrypted);
      expect(decrypted, equals(rawPayload));
    });

    test('SecurityService biometrics authentication gate passes', () async {
      final secService = SecurityService();
      secService.setBiometrics(true);
      final isAuth = await secService.authenticateBiometric();
      expect(isAuth, isTrue);
    });

    test('SecurityService PIN verification and modification operate cleanly', () {
      final secService = SecurityService();
      expect(secService.verifyPin('1234'), isTrue);
      expect(secService.verifyPin('0000'), isFalse);

      secService.setPin('9820');
      expect(secService.verifyPin('9820'), isTrue);
    });

    test('SecurityService root detection and tamper integrity checks pass', () async {
      final secService = SecurityService();
      final isRooted = await secService.checkRootOrJailbreakStatus();
      final isTampered = await secService.checkTamperIntegrity();

      expect(isRooted, isFalse);
      expect(isTampered, isTrue);
    });

    test('SecurityService session timeout calculation functions accurately', () {
      final secService = SecurityService();
      final recentTimestamp = DateTime.now().millisecondsSinceEpoch - 1000; // 1 sec ago
      final oldTimestamp = DateTime.now().millisecondsSinceEpoch - (20 * 60 * 1000); // 20 mins ago

      expect(secService.isSessionTimedOut(recentTimestamp), isFalse);
      expect(secService.isSessionTimedOut(oldTimestamp), isTrue);
    });

    test('DigitalTwinService returns valid telemetry state', () {
      final twinService = DigitalTwinService();
      final state = twinService.getTwinState();
      expect(state.engineHealthScore, greaterThan(90.0));
      expect(state.batteryPct, equals(94.0));
      expect(state.activeSensors, contains('6-Axis IMU'));
    });

    test('OfflineSyncEngine resolves Last-Write-Wins conflict correctly', () {
      final engine = OfflineSyncEngine();
      final clientRecord = {'updatedAt': '2026-08-05T12:00:00Z', 'value': 'client'};
      final serverRecord = {'updatedAt': '2026-08-05T10:00:00Z', 'value': 'server'};

      final resolved = engine.resolveConflict(clientRecord: clientRecord, serverRecord: serverRecord);
      expect(resolved['value'], equals('client'));
    });

    test('FeatureFlagService flags and A/B variants operate correctly', () {
      final flagService = FeatureFlagService();
      expect(flagService.isFeatureEnabled('enable_ai_copilot_voice'), isTrue);
      expect(flagService.getAbTestVariant('ai_hud_theme_variant'), equals('hyper_neon'));
    });

    test('RideOSEventBus publishes and receives events cleanly', () async {
      final eventBus = RideOSEventBus();
      expectLater(
        eventBus.onType(RideOSEventType.crashDetected),
        emits(predicate<RideOSBaseEvent>((e) => e.data['forceG'] == 5.8)),
      );

      eventBus.publishEvent(RideOSEventType.crashDetected, {'forceG': 5.8});
    });

    test('CrashDetectionEngine evaluates IMU thresholds', () {
      final engine = CrashDetectionEngine();
      final isImpact = engine.evaluateSensorInputs(
        gForce: 6.2,
        decelerationMps2: 15.0,
        tiltDegrees: 82.0,
      );
      expect(isImpact, isTrue);
      expect(engine.state, equals(CrashDetectionState.countdownActive));
      engine.cancelCountdown();
    });
  });
}
