import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/telemetry/models/metric_types.dart';
import 'package:rideos_mobile/core/telemetry/models/telemetry_metric.dart';
import 'package:rideos_mobile/core/telemetry/models/telemetry_snapshot.dart';
import 'package:rideos_mobile/core/telemetry/policies/freshness_policy.dart';
import 'package:rideos_mobile/core/telemetry/policies/deadband_policy.dart';
import 'package:rideos_mobile/core/telemetry/policies/source_precedence_policy.dart';
import 'package:rideos_mobile/core/telemetry/services/telemetry_normalizer.dart';
import 'package:rideos_mobile/core/telemetry/services/telemetry_pipeline.dart';
import 'package:rideos_mobile/core/telemetry/presentation/screens/live_telemetry_stream_screen.dart';
import 'package:rideos_mobile/core/diagnostics/models/diagnostic_types.dart';
import 'package:rideos_mobile/core/diagnostics/models/pid_definition.dart';

void main() {
  group('Phase 19: Live Telemetry Normalization & Stream Pipeline Tests', () {
    // ======================================================================
    // 1. Model Creation & Metric Categories
    // ======================================================================
    test('1. NormalizedTelemetryMetric initializes with category, units, and timestamps', () {
      final now = DateTime.now();
      final speed = NormalizedTelemetryMetric(
        metricId: TelemetryMetricId.vehicleSpeed,
        category: TelemetryMetricCategory.dynamics,
        value: 120.5,
        unit: TelemetryUnit.kilometersPerHour,
        timestamp: now,
        sourceEcu: EcuModule.antiLockBraking_ABS,
        diagnosticPidCode: '0D',
        freshness: TelemetryFreshness.fresh,
      );

      expect(speed.metricId, equals(TelemetryMetricId.vehicleSpeed));
      expect(speed.category, equals(TelemetryMetricCategory.dynamics));
      expect(speed.value, equals(120.5));
      expect(speed.unit, equals(TelemetryUnit.kilometersPerHour));
      expect(speed.sourceEcu, equals(EcuModule.antiLockBraking_ABS));
      expect(speed.isLive, isTrue);
      expect(speed.formattedDisplay, equals('120.5'));
    });

    test('2. NormalizedTelemetryMetric formats RPM without decimal point', () {
      final rpm = NormalizedTelemetryMetric(
        metricId: TelemetryMetricId.engineRpm,
        category: TelemetryMetricCategory.dynamics,
        value: 8500.0,
        unit: TelemetryUnit.revolutionsPerMinute,
        timestamp: DateTime.now(),
        freshness: TelemetryFreshness.fresh,
      );

      expect(rpm.formattedDisplay, equals('8500'));
    });

    // ======================================================================
    // 3. Normalizer & PID Ingestion
    // ======================================================================
    test('3. TelemetryNormalizer maps diagnostic PIDs to normalized metrics', () {
      final normalizer = TelemetryNormalizer.instance;
      final measurement = DecodedPidMeasurement(
        pid: DiagnosticPid.coolantTemperature,
        value: 88.0,
        unit: '°C',
        timestamp: DateTime.now(),
      );

      final metric = normalizer.normalizePidMeasurement(
        measurement,
        sourceEcu: EcuModule.engineControlModule_ECM,
      );

      expect(metric.metricId, equals(TelemetryMetricId.coolantTemperature));
      expect(metric.category, equals(TelemetryMetricCategory.thermal));
      expect(metric.value, equals(88.0));
      expect(metric.unit, equals(TelemetryUnit.celsius));
      expect(metric.freshness, equals(TelemetryFreshness.fresh));
      expect(metric.sourceEcu, equals(EcuModule.engineControlModule_ECM));
    });

    test('4. TelemetryNormalizer flags out-of-range sensor readings as INVALID', () {
      final normalizer = TelemetryNormalizer.instance;
      // Coolant temp valid range: -40 to +215 °C. Value 300.0 is impossible.
      final invalidMeasurement = DecodedPidMeasurement(
        pid: DiagnosticPid.coolantTemperature,
        value: 300.0,
        unit: '°C',
        timestamp: DateTime.now(),
      );

      final metric = normalizer.normalizePidMeasurement(invalidMeasurement);
      expect(metric.freshness, equals(TelemetryFreshness.invalid));
      expect(metric.isLive, isFalse);
      expect(metric.formattedDisplay, equals('ERR'));
    });

    // ======================================================================
    // 5. Derived Acceleration Calculation
    // ======================================================================
    test('5. TelemetryNormalizer calculates derived longitudinal acceleration from speed delta', () {
      final normalizer = TelemetryNormalizer.instance;
      final t0 = DateTime(2026, 9, 1, 12, 0, 0);
      final t1 = DateTime(2026, 9, 1, 12, 0, 1); // 1.0 second later

      final speed0 = NormalizedTelemetryMetric(
        metricId: TelemetryMetricId.vehicleSpeed,
        category: TelemetryMetricCategory.dynamics,
        value: 36.0, // 36 km/h = 10.0 m/s
        unit: TelemetryUnit.kilometersPerHour,
        timestamp: t0,
        freshness: TelemetryFreshness.fresh,
      );

      final speed1 = NormalizedTelemetryMetric(
        metricId: TelemetryMetricId.vehicleSpeed,
        category: TelemetryMetricCategory.dynamics,
        value: 72.0, // 72 km/h = 20.0 m/s
        unit: TelemetryUnit.kilometersPerHour,
        timestamp: t1,
        freshness: TelemetryFreshness.fresh,
      );

      final accel = normalizer.computeDerivedAcceleration(
        previousSpeed: speed0,
        currentSpeed: speed1,
      );

      // (20.0 m/s - 10.0 m/s) / 1.0s = 10.0 m/s²
      expect(accel, isNotNull);
      expect(accel!.metricId, equals(TelemetryMetricId.longitudinalAcceleration));
      expect(accel.value, closeTo(10.0, 0.01));
      expect(accel.unit, equals(TelemetryUnit.metersPerSecondSquared));
    });

    // ======================================================================
    // 6. Freshness Policy Evaluation
    // ======================================================================
    test('6. TelemetryFreshnessPolicy evaluates LIVE, STALE, and UNAVAILABLE states', () {
      const policy = TelemetryFreshnessPolicy(
        defaultFreshnessThreshold: Duration(seconds: 3),
        defaultUnavailableThreshold: Duration(seconds: 8),
      );

      final now = DateTime.now();

      // Fresh (1.0s old)
      final freshTime = now.subtract(const Duration(seconds: 1));
      expect(policy.evaluateFreshness(freshTime, currentTime: now), equals(TelemetryFreshness.fresh));

      // Stale (4.0s old)
      final staleTime = now.subtract(const Duration(seconds: 4));
      expect(policy.evaluateFreshness(staleTime, currentTime: now), equals(TelemetryFreshness.stale));

      // Unavailable (10.0s old)
      final unavailTime = now.subtract(const Duration(seconds: 10));
      expect(policy.evaluateFreshness(unavailTime, currentTime: now), equals(TelemetryFreshness.unavailable));
    });

    test('7. TelemetryFreshnessPolicy respects per-metric duration overrides', () {
      const policy = TelemetryFreshnessPolicy();
      final now = DateTime.now();

      // Speed override is 1.5s -> 2.0s old speed is STALE
      final speedTime = now.subtract(const Duration(milliseconds: 2000));
      expect(
        policy.evaluateFreshness(speedTime, metricId: TelemetryMetricId.vehicleSpeed, currentTime: now),
        equals(TelemetryFreshness.stale),
      );

      // Coolant temp override is 5.0s -> 2.0s old coolant is still FRESH
      expect(
        policy.evaluateFreshness(speedTime, metricId: TelemetryMetricId.coolantTemperature, currentTime: now),
        equals(TelemetryFreshness.fresh),
      );
    });

    // ======================================================================
    // 8. Deadband Filter Policy
    // ======================================================================
    test('8. TelemetryDeadbandPolicy suppresses sub-threshold changes and passes significant deltas', () {
      const deadband = TelemetryDeadbandPolicy();

      // Speed threshold is 0.5 km/h:
      // Delta = 0.2 km/h -> should NOT emit (noise)
      expect(deadband.shouldEmit(TelemetryMetricId.vehicleSpeed, 50.0, 50.2), isFalse);

      // Delta = 0.8 km/h -> SHOULD emit
      expect(deadband.shouldEmit(TelemetryMetricId.vehicleSpeed, 50.0, 50.8), isTrue);

      // RPM threshold is 25.0 RPM:
      // Delta = 10 RPM -> should NOT emit
      expect(deadband.shouldEmit(TelemetryMetricId.engineRpm, 4000.0, 4010.0), isFalse);

      // Delta = 50 RPM -> SHOULD emit
      expect(deadband.shouldEmit(TelemetryMetricId.engineRpm, 4000.0, 4050.0), isTrue);

      // Transition from null (initial) always emits
      expect(deadband.shouldEmit(TelemetryMetricId.vehicleSpeed, null, 25.0), isTrue);
    });

    // ======================================================================
    // 9. Multi-ECU Source Precedence
    // ======================================================================
    test('9. SourcePrecedencePolicy enforces ABS > ECM > IPC for vehicle speed', () {
      const policy = SourcePrecedencePolicy();

      // ABS overrides ECM for speed
      expect(
        policy.shouldOverride(
          TelemetryMetricId.vehicleSpeed,
          EcuModule.engineControlModule_ECM,
          EcuModule.antiLockBraking_ABS,
        ),
        isTrue,
      );

      // ECM does NOT override active ABS speed
      expect(
        policy.shouldOverride(
          TelemetryMetricId.vehicleSpeed,
          EcuModule.antiLockBraking_ABS,
          EcuModule.engineControlModule_ECM,
        ),
        isFalse,
      );

      // Same ECU always allowed to update
      expect(
        policy.shouldOverride(
          TelemetryMetricId.vehicleSpeed,
          EcuModule.antiLockBraking_ABS,
          EcuModule.antiLockBraking_ABS,
        ),
        isTrue,
      );
    });

    // ======================================================================
    // 10. Telemetry Pipeline Stream Lifecycle & Ingestion
    // ======================================================================
    test('10. TelemetryPipeline ingests metrics and broadcasts updated snapshots', () async {
      final pipeline = TelemetryPipeline();

      final snapshots = <NormalizedTelemetrySnapshot>[];
      final sub = pipeline.snapshotStream.listen(snapshots.add);

      final speedMetric = NormalizedTelemetryMetric(
        metricId: TelemetryMetricId.vehicleSpeed,
        category: TelemetryMetricCategory.dynamics,
        value: 80.0,
        unit: TelemetryUnit.kilometersPerHour,
        timestamp: DateTime.now(),
        freshness: TelemetryFreshness.fresh,
      );

      pipeline.ingestMetric(speedMetric);

      // Wait brief microtask for broadcast delivery
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await sub.cancel();

      expect(snapshots, isNotEmpty);
      expect(pipeline.currentSnapshot.speedKmh, equals(80.0));
      expect(pipeline.currentSnapshot.hasLivePowertrainStream, isTrue);
    });

    test('11. TelemetryPipeline handles transport disconnect by setting snapshot unavailable', () {
      final pipeline = TelemetryPipeline();

      // Ingest live metric
      pipeline.ingestMetric(NormalizedTelemetryMetric(
        metricId: TelemetryMetricId.engineRpm,
        category: TelemetryMetricCategory.dynamics,
        value: 3500.0,
        unit: TelemetryUnit.revolutionsPerMinute,
        timestamp: DateTime.now(),
        freshness: TelemetryFreshness.fresh,
      ));
      expect(pipeline.currentSnapshot.engineRpm, equals(3500.0));

      // Trigger disconnect
      pipeline.handleTransportDisconnect();

      // All metrics are now UNAVAILABLE
      expect(pipeline.currentSnapshot.engineRpm, isNull);
      expect(pipeline.currentSnapshot.hasLivePowertrainStream, isFalse);
    });

    // ======================================================================
    // 12. Snapshot Freshness Evaluation
    // ======================================================================
    test('12. NormalizedTelemetrySnapshot transitions metrics from fresh to stale over time', () {
      final now = DateTime.now();
      final oldTime = now.subtract(const Duration(seconds: 4));

      var snapshot = NormalizedTelemetrySnapshot.initial();
      final freshMetric = NormalizedTelemetryMetric(
        metricId: TelemetryMetricId.coolantTemperature,
        category: TelemetryMetricCategory.thermal,
        value: 90.0,
        unit: TelemetryUnit.celsius,
        timestamp: oldTime,
        freshness: TelemetryFreshness.fresh,
      );

      snapshot = snapshot.withUpdatedMetric(freshMetric);
      expect(snapshot.getMetric(TelemetryMetricId.coolantTemperature)!.freshness, equals(TelemetryFreshness.fresh));

      // Evaluate freshness with 3.0s threshold
      final evaluated = snapshot.evaluateFreshness(
        const Duration(seconds: 3),
        const Duration(seconds: 8),
      );

      expect(evaluated.getMetric(TelemetryMetricId.coolantTemperature)!.freshness, equals(TelemetryFreshness.stale));
      expect(evaluated.staleMetricCount, equals(1));
    });

    // ======================================================================
    // 13. UI Console Screen Widget Test
    // ======================================================================
    testWidgets('13. LiveTelemetryStreamScreen renders tabs and category grids', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LiveTelemetryStreamScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // App bar title
      expect(find.text('LIVE TELEMETRY STREAM'), findsOneWidget);

      // Tabs
      expect(find.text('DYNAMICS'), findsOneWidget);
      expect(find.text('THERMAL'), findsOneWidget);
      expect(find.text('ELECTRICAL'), findsOneWidget);
      expect(find.text('FUEL & ENERGY'), findsOneWidget);

      // Tap THERMAL tab
      await tester.tap(find.text('THERMAL'));
      await tester.pumpAndSettle();

      // Tap ELECTRICAL tab
      await tester.tap(find.text('ELECTRICAL'));
      await tester.pumpAndSettle();

      // Tap FUEL & ENERGY tab
      await tester.tap(find.text('FUEL & ENERGY'));
      await tester.pumpAndSettle();
    });
  });
}
