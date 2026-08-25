import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/safety_engine/models/safety_event_models.dart';
import 'package:rideos_mobile/core/safety_engine/services/safety_event_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RideOS Advanced Rider Safety & Emergency Response Tests', () {
    late SafetyEventEngine safetyEngine;

    setUp(() {
      safetyEngine = SafetyEventEngine();
    });

    test('Multi-Signal Fusion triggers High-Confidence Crash Event and countdown', () {
      final event = safetyEngine.evaluateMultiSignalEvent(
        peakGForce: 5.5,
        speedDropKmh: 42.0,
        vehicleConnectionLost: true,
        isStationaryAfterImpact: true,
        isSimulated: true,
      );

      expect(event.eventType, equals(SafetyEventType.crashSuspected));
      expect(event.confidence, equals(SafetyEventConfidence.high));
      expect(event.severity, equals(SafetySeverity.critical));
      expect(event.isSimulated, isTrue);
      expect(safetyEngine.countdownState, equals(CrashCountdownState.countdownActive));
      expect(safetyEngine.secondsRemaining, greaterThan(0));
    });

    test('False-Positive Protection: Filters isolated pothole impact without triggering countdown', () {
      safetyEngine.cancelCountdownRiderSafe();
      expect(safetyEngine.countdownState, equals(CrashCountdownState.idle));

      final event = safetyEngine.evaluateMultiSignalEvent(
        peakGForce: 3.2,
        speedDropKmh: 0.0,
        vehicleConnectionLost: false,
        isStationaryAfterImpact: false,
        isSimulated: true,
      );

      expect(event.eventType, equals(SafetyEventType.hardImpact));
      expect(event.confidence, equals(SafetyEventConfidence.low));
      expect(event.resolution, equals(SafetyEventResolution.falsePositive));
      expect(safetyEngine.countdownState, equals(CrashCountdownState.idle));
    });

    test('Crash Countdown State Machine allows rider to cancel countdown safely', () {
      safetyEngine.triggerManualSos(isSimulated: true);
      expect(safetyEngine.countdownState, equals(CrashCountdownState.countdownActive));

      safetyEngine.cancelCountdownRiderSafe();
      expect(safetyEngine.countdownState, equals(CrashCountdownState.idle));
      expect(safetyEngine.safetyHistory.first.resolution, equals(SafetyEventResolution.riderConfirmedSafe));
    });

    test('Emergency Contacts Manager supports adding, toggling and removing contacts', () {
      final initialCount = safetyEngine.emergencyContacts.length;
      const newContact = EmergencyContact(
        id: 'contact_test_99',
        name: 'Test Responder',
        phoneNumber: '+1-555-000-1111',
        relationship: 'Colleague',
      );

      safetyEngine.addEmergencyContact(newContact);
      expect(safetyEngine.emergencyContacts.length, equals(initialCount + 1));

      safetyEngine.toggleEmergencyContact('contact_test_99', false);
      expect(safetyEngine.emergencyContacts.firstWhere((c) => c.id == 'contact_test_99').isEnabled, isFalse);

      safetyEngine.removeEmergencyContact('contact_test_99');
      expect(safetyEngine.emergencyContacts.any((c) => c.id == 'contact_test_99'), isFalse);
    });

    test('Calculates Transparent Rider Safety Score with explicit breakdown factors', () {
      final safetyScore = safetyEngine.calculateRiderSafetyScore();
      expect(safetyScore.overallScore, greaterThan(0));
      expect(safetyScore.overallScore, lessThanOrEqualTo(100));
      expect(safetyScore.subScores.containsKey('Braking Smoothness'), isTrue);
      expect(safetyScore.positiveFactors, isNotEmpty);
      expect(safetyScore.improvementAreas, isNotEmpty);
    });
  });
}
