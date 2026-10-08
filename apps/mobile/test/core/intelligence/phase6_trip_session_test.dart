import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/intelligence/models/trip_session.dart';
import 'package:rideos_mobile/core/intelligence/models/ride_ai_context.dart';
import 'package:rideos_mobile/core/safety/models/rider_alert.dart';

void main() {
  group('Phase 6 — Trip Intelligence Architecture Tests', () {
    test('1. TripSession initializes successfully without synthetic values', () {
      final now = DateTime.now();
      final session = TripSession(
        sessionId: 'trip_123',
        startTime: now,
      );

      expect(session.sessionId, 'trip_123');
      expect(session.distanceMeters, 0.0);
      expect(session.duration, Duration.zero);
      expect(session.alerts.isEmpty, isTrue);
      expect(session.contextSnapshots.isEmpty, isTrue);
    });

    test('2. TripSession accurately records duration on endSession', () async {
      final now = DateTime.now();
      final session = TripSession(
        sessionId: 'trip_124',
        startTime: now,
      );

      await Future.delayed(const Duration(milliseconds: 100));
      session.endSession();

      expect(session.duration.inMilliseconds, greaterThanOrEqualTo(100));
      expect(session.endTime, isNotNull);
    });

    test('3. TripSession correctly stores RideAIContext snapshots and Alerts', () {
      final session = TripSession(
        sessionId: 'trip_125',
        startTime: DateTime.now(),
      );

      session.addAlert(RiderAlert(
        id: 'alert_1',
        reason: 'GPS_DEGRADED',
        severity: AlertSeverity.warning,
        source: AlertSource.navigation,
        confidence: 1.0,
        timestamp: DateTime.now(),
      ));

      session.captureSnapshot(RideAIContext.empty());

      expect(session.alerts.length, 1);
      expect(session.alerts.first.reason, 'GPS_DEGRADED');
      expect(session.contextSnapshots.length, 1);
      expect(session.contextSnapshots.first.weatherState, 'UNAVAILABLE'); // Ensuring it's empty context
    });
  });
}
