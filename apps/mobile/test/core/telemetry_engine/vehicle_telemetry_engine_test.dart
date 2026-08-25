import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/telemetry_engine/models/telemetry_metric_entry.dart';
import 'package:rideos_mobile/core/telemetry_engine/services/ride_session_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Real-Time Two-Wheeler Telemetry & Smart Cockpit Tests', () {
    late RideSessionManager sessionManager;

    setUp(() {
      sessionManager = RideSessionManager();
    });

    test('TelemetryMetric marks unsupported sensors accurately without fabricating zeros', () {
      const unsupported = TelemetryMetric<double>.unsupported(unit: 'RPM');
      expect(unsupported.isSupported, isFalse);
      expect(unsupported.state, equals(TelemetryFreshnessState.unsupported));
      expect(unsupported.formattedValue, equals('N/A'));
      expect(unsupported.formattedWithUnit, equals('Unsupported'));

      const live = TelemetryMetric<double>(
        value: 72.5,
        unit: 'km/h',
        timestamp: _StaticEpochDateTime(),
        state: TelemetryFreshnessState.live,
      );
      expect(live.isSupported, isTrue);
      expect(live.hasValidLiveValue, isTrue);
      expect(live.formattedValue, equals('72.5'));
      expect(live.formattedWithUnit, equals('72.5 km/h'));
    });

    test('RideSessionManager executes full lifecycle state transitions', () {
      expect(sessionManager.currentState, equals(RideSessionState.idle));

      sessionManager.startRideSession();
      expect(sessionManager.currentState, equals(RideSessionState.riding));

      sessionManager.pauseRideSession();
      expect(sessionManager.currentState, equals(RideSessionState.paused));

      sessionManager.resumeRideSession();
      expect(sessionManager.currentState, equals(RideSessionState.riding));

      final summary = sessionManager.endRideSession();
      expect(summary.sessionId, contains('ride_'));
      expect(sessionManager.currentState, equals(RideSessionState.idle));
    });

    test('LiveVehicleCockpitSnapshot initializes disconnected by default', () {
      final initial = LiveVehicleCockpitSnapshot.initialDisconnected();
      expect(initial.isVehicleConnected, isFalse);
      expect(initial.speedKmh.isSupported, isTrue);
      expect(initial.speedKmh.state, equals(TelemetryFreshnessState.unavailable));
    });
  });
}

class _StaticEpochDateTime implements DateTime {
  const _StaticEpochDateTime();

  @override
  int get year => 2026;
  @override
  int get month => 1;
  @override
  int get day => 1;
  @override
  int get hour => 0;
  @override
  int get minute => 0;
  @override
  int get second => 0;
  @override
  int get millisecond => 0;
  @override
  int get microsecond => 0;
  @override
  int get weekday => 4;
  @override
  int get millisecondsSinceEpoch => 0;
  @override
  int get microsecondsSinceEpoch => 0;
  @override
  String get timeZoneName => 'UTC';
  @override
  Duration get timeZoneOffset => Duration.zero;
  @override
  bool get isUtc => true;

  @override
  DateTime add(Duration duration) => DateTime.fromMillisecondsSinceEpoch(0).add(duration);
  @override
  DateTime subtract(Duration duration) => DateTime.fromMillisecondsSinceEpoch(0).subtract(duration);
  @override
  Duration difference(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).difference(other);
  @override
  int compareTo(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).compareTo(other);
  @override
  bool isAfter(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).isAfter(other);
  @override
  bool isBefore(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).isBefore(other);
  @override
  bool isAtSameMomentAs(DateTime other) => DateTime.fromMillisecondsSinceEpoch(0).isAtSameMomentAs(other);
  @override
  String toIso8601String() => '2026-01-01T00:00:00.000Z';
  @override
  DateTime toLocal() => DateTime.fromMillisecondsSinceEpoch(0).toLocal();
  @override
  DateTime toUtc() => this;
}
