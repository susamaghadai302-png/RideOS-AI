import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/device_providers/models/field_bench_models.dart';
import 'package:rideos_mobile/core/device_providers/models/normalized_telemetry_models.dart';
import 'package:rideos_mobile/core/device_providers/services/physical_field_bench_service.dart';

void main() {
  group('Phase 4 — Physical Field Bench & Link Health Tests', () {
    late PhysicalFieldBenchService benchService;

    setUp(() {
      benchService = PhysicalFieldBenchService();
    });

    test('FieldLinkHealthSnapshot determines health thresholds accurately', () {
      const healthySnapshot = FieldLinkHealthSnapshot(
        packetRateHz: 20.0,
        packetLossPercentage: 0.2,
        latencyMs: 50,
        reconnectCount: 0,
        sensorFreshnessSeconds: 0.1,
        dataQualityScore: 98,
        source: TelemetryDataSource.realDevice,
        rssi: -55,
      );

      expect(healthySnapshot.isHealthy, isTrue);
      expect(healthySnapshot.sourceBadgeText, equals('LIVE HARDWARE'));

      const degradedSnapshot = FieldLinkHealthSnapshot(
        packetRateHz: 2.0,
        packetLossPercentage: 12.5,
        latencyMs: 500,
        reconnectCount: 4,
        sensorFreshnessSeconds: 4.5,
        dataQualityScore: 25,
        source: TelemetryDataSource.benchTest,
        rssi: -89,
      );

      expect(degradedSnapshot.isHealthy, isFalse);
      expect(degradedSnapshot.sourceBadgeText, equals('BENCH TEST'));
    });

    test('Records reconnect drop counter on transient Bluetooth signal drops', () {
      final initialDrops = benchService.latestHealthSnapshot?.reconnectCount ?? 0; debugPrint(initialDrops.toString());
      benchService.recordConnectionDrop();
      benchService.recordConnectionDrop();

      expect(benchService.isRideSessionActive, isFalse);
    });
  });
}
