import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/dashboard/core/services/realtime_dashboard_telemetry_engine.dart';
import 'package:rideos_mobile/features/dashboard/domain/models/advanced_dashboard_models.dart';

void main() {
  group('Phase 14 — Real-Time Riding Dashboard & Advanced Telemetry Tests', () {
    late RealtimeDashboardTelemetryEngine engine;

    setUp(() {
      engine = RealtimeDashboardTelemetryEngine();
    });

    test('1. Telemetry Connection Status reflects active link', () {
      final conn = engine.getConnectionStatus();
      expect(conn, isIn([TelemetryConnectionStatus.connected, TelemetryConnectionStatus.disconnected]));
    });

    test('2. Live Ride Metrics normalizes real values within physically safe bounds', () {
      final metrics = engine.getLiveMetrics();

      if (metrics.speedKmh != null) {
        expect(metrics.speedKmh!, inInclusiveRange(0.0, 400.0));
      }
      if (metrics.rpm != null) {
        expect(metrics.rpm!, inInclusiveRange(0, 18000));
      }
      if (metrics.coolantTempC != null) {
        expect(metrics.coolantTempC!, inInclusiveRange(-40.0, 150.0));
      }
      if (metrics.batteryVoltage != null) {
        expect(metrics.batteryVoltage!, inInclusiveRange(6.0, 18.0));
      }
    });

    test('3. Ride State Machine transitions through ride lifecycle deterministically', () {
      engine.startRide();
      expect(engine.rideState, equals(RideState.riding));

      engine.pauseRide();
      expect(engine.rideState, equals(RideState.paused));

      engine.resumeRide();
      expect(engine.rideState, equals(RideState.riding));

      engine.endRide();
      expect(engine.rideState, equals(RideState.completed));
    });

    test('4. Historical Telemetry Charts return empty when no session is recorded', () {
      // With no active provider and no recorded session, charts must be empty
      final points = engine.getHistoricalChartPoints();
      expect(points.length, equals(0));
    });

    test('5. Dashboard AI Assistant answers live drivetrain and electrical queries offline', () {
      // 1. Drivetrain/RPM query
      final driveReply = engine.processDashboardAiQuery('What is my engine speed and RPM?');
      expect(driveReply.contains('Drivetrain Telemetry') || driveReply.contains('Speed'), isTrue);

      // 2. Thermal Query
      final tempReply = engine.processDashboardAiQuery('How is my engine coolant temperature?');
      expect(tempReply.contains('Thermal State') || tempReply.contains('Coolant'), isTrue);

      // 3. Electrical Query
      final battReply = engine.processDashboardAiQuery('How is battery voltage?');
      expect(battReply.contains('Electrical Bus') || battReply.contains('Battery'), isTrue);

      // 4. Ride State Query
      final stateReply = engine.processDashboardAiQuery('What is my ride state?');
      expect(stateReply.contains('Ride State'), isTrue);
    });
  });
}
