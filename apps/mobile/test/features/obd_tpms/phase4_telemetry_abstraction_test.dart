import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/obd_tpms/core/services/obd_full_telemetry_service.dart';

void main() {
  group('Phase 4 - Telemetry Abstraction & Hardware vs Simulator Tests', () {
    late ObdFullTelemetryService service;

    setUp(() {
      service = ObdFullTelemetryService();
    });

    test('Offline mode emits unconnectedOffline telemetry with null metrics', () {
      service.updateTelemetry(ObdFullTelemetryData(
        source: TelemetryDataSource.unconnectedOffline,
        timestamp: DateTime.now(),
      ));
      final telemetry = service.getLatestTelemetry();

      expect(telemetry.source, TelemetryDataSource.unconnectedOffline);
      expect(telemetry.isSimulated, isFalse);
      expect(telemetry.engineRpm, isNull);
      expect(telemetry.getDisplayValue(telemetry.engineRpm, 'RPM'), 'Not available from vehicle');
    });

    test('Stale data detector flags timestamps older than 3 seconds', () {
      final freshData = ObdFullTelemetryData(
        source: TelemetryDataSource.realHardwareBle,
        timestamp: DateTime.now(),
        engineRpm: 5200,
      );
      expect(freshData.isStale(), isFalse);

      final oldData = ObdFullTelemetryData(
        source: TelemetryDataSource.realHardwareBle,
        timestamp: DateTime.now().subtract(const Duration(seconds: 5)),
        engineRpm: 5200,
      );
      expect(oldData.isStale(), isTrue);
    });
  });
}
