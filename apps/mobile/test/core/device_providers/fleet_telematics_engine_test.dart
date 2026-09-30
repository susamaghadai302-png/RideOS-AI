import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/device_providers/models/normalized_telemetry_models.dart';
import 'package:rideos_mobile/core/device_providers/services/fleet_telematics_engine.dart';

void main() {
  group('FleetTelematicsEngine Tests', () {
    late FleetTelematicsEngine engine;

    setUp(() {
      engine = FleetTelematicsEngine();
    });

    test('Production initializes with no active provider (DISCONNECTED)', () {
      expect(engine.activeProvider, isNull);
      expect(engine.linkState.name, equals('disconnected'));
    });

    test('Explicit switchProvider activates SimulatorProvider', () {
      engine.switchProvider('simulator');
      expect(engine.activeProvider, isNotNull);
      expect(engine.activeProvider!.dataSourceClassification, equals(TelemetryDataSource.benchTest));
    });

    test('Switches hardware provider to OBD-II CAN link', () {
      engine.switchProvider('obd2_can');
      expect(engine.activeProvider!.dataSourceClassification, equals(TelemetryDataSource.realDevice));
      expect(engine.activeProvider!.canClearDtcCodes, isTrue);
    });

    test('Records ride telemetry session and computes summary metrics', () async {
      engine.switchProvider('simulator');
      await engine.connectDevice('sim_01');

      engine.startRecordingSession();
      expect(engine.isRecordingSession, isTrue);

      await Future.delayed(const Duration(milliseconds: 250));

      final summary = engine.stopRecordingSession();
      expect(engine.isRecordingSession, isFalse);
      expect(summary['totalSamples'], greaterThanOrEqualTo(0));
      expect(summary['dataSource'], equals('benchTest'));
    });
  });
}
