import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/device_providers/models/normalized_telemetry_models.dart';
import 'package:rideos_mobile/core/device_providers/services/fleet_telematics_engine.dart';
import 'package:rideos_mobile/core/device_providers/services/physical_field_bench_service.dart';

void main() {
  group('Phase 4 — On-Road Ride Field Session Recording Tests', () {
    late PhysicalFieldBenchService benchService;
    late FleetTelematicsEngine telematicsEngine;

    setUp(() {
      benchService = PhysicalFieldBenchService();
      telematicsEngine = FleetTelematicsEngine();
    });

    test('Executes complete Start Ride -> Record -> Stop Ride field session workflow', () async {
      telematicsEngine.switchProvider('simulator');
      await telematicsEngine.connectDevice('sim_01');

      benchService.startLiveRideSession();
      expect(benchService.isRideSessionActive, isTrue);

      await Future.delayed(const Duration(milliseconds: 300));

      final session = benchService.stopLiveRideSession();
      expect(benchService.isRideSessionActive, isFalse);
      expect(session.sessionId.startsWith('field_sess_'), isTrue);
      expect(session.durationMinutes, greaterThanOrEqualTo(0.0));
      expect(session.dataSource, equals(TelemetryDataSource.benchTest));

      final jsonMap = session.toJson();
      expect(jsonMap['sessionId'], isNotNull);
      expect(jsonMap['dataSource'], equals('benchTest'));
    });
  });
}
