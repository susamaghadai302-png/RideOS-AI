import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/dashcam/core/services/dashcam_sentry_engine.dart';
import 'package:rideos_mobile/features/dashcam/domain/entities/dashcam_incident_entity.dart';

void main() {
  group('Phase 6 - AI Vision Dashcam & Sentry Engine Tests', () {
    late DashcamSentryEngine engine;

    setUp(() {
      engine = DashcamSentryEngine();
      engine.clearIncidentVault();
      engine.toggleSentryMode(false);
      engine.stopRecording();
    });

    test('Initializes in standby mode', () {
      expect(engine.status, equals(DashcamPipelineStatus.standby));
      expect(engine.isRecording, isFalse);
      expect(engine.isSentryActive, isFalse);
      expect(engine.lockedIncidents.isEmpty, isTrue);
    });

    test('Transitions correctly into recording and standby', () {
      engine.startRecording();
      expect(engine.status, equals(DashcamPipelineStatus.recording));
      expect(engine.isRecording, isTrue);

      engine.stopRecording();
      expect(engine.status, equals(DashcamPipelineStatus.standby));
      expect(engine.isRecording, isFalse);
    });

    test('Locks incident footage on emergency crash trigger', () {
      engine.startRecording();

      engine.triggerIncidentLock(
        trigger: IncidentTriggerType.crashDetected,
        gForce: 5.2,
        speedAtTriggerKmh: 75.0,
      );

      expect(engine.lockedIncidents.length, equals(1));
      expect(engine.lockedIncidents.first.triggerType, equals(IncidentTriggerType.crashDetected));
      expect(engine.lockedIncidents.first.isLocked, isTrue);
      expect(engine.lockedIncidents.first.maxGForce, equals(5.2));
    });

    test('Sentry mode triggers tamper lock when motion is detected', () {
      engine.toggleSentryMode(true);
      expect(engine.isSentryActive, isTrue);
      expect(engine.status, equals(DashcamPipelineStatus.sentryActive));

      engine.simulateSentryTamperDetection();
      expect(engine.lockedIncidents.length, equals(1));
      expect(engine.lockedIncidents.first.triggerType, equals(IncidentTriggerType.sentryTamperMotion));
    });

    test('Updates AI hazard overlay state accurately', () {
      const hazard = AiHazardOverlayState(
        hazardType: AiHazardDetectionType.forwardCollision,
        description: 'BRAKE WARNING: Lead vehicle decelerating rapidly in 18m',
        distanceMeters: 18.0,
        confidencePct: 99.1,
      );

      engine.updateAiHazard(hazard);
      expect(engine.currentHazardState.hazardType, equals(AiHazardDetectionType.forwardCollision));
      expect(engine.currentHazardState.distanceMeters, equals(18.0));
      expect(engine.currentHazardState.confidencePct, equals(99.1));
    });
  });
}
