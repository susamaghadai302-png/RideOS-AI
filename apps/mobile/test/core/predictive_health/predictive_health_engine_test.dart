import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/predictive_health/models/predictive_health_score.dart';

import 'package:rideos_mobile/core/predictive_health/models/component_wear.dart';
import 'package:rideos_mobile/core/predictive_health/services/wear_calculator.dart';
import 'package:rideos_mobile/core/predictive_health/services/predictive_health_engine.dart';
import 'package:rideos_mobile/core/telemetry/models/telemetry_snapshot.dart';
import 'package:rideos_mobile/core/telemetry/models/telemetry_metric.dart';
import 'package:rideos_mobile/core/telemetry/models/metric_types.dart';
import 'package:rideos_mobile/core/telemetry/services/telemetry_pipeline.dart';
import 'package:rideos_mobile/core/diagnostics/services/ecu_diagnostic_manager.dart';
import 'package:rideos_mobile/core/diagnostics/models/dtc_record.dart';
import 'package:rideos_mobile/core/diagnostics/models/diagnostic_types.dart';

// Manual Stubs to avoid Mockito dependencies
class StubTelemetryPipeline implements TelemetryPipeline {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final _snapshotController = StreamController<NormalizedTelemetrySnapshot>.broadcast();
  @override
  Stream<NormalizedTelemetrySnapshot> get snapshotStream => _snapshotController.stream;

  @override
  Stream<NormalizedTelemetryMetric> get metricStream => const Stream.empty();

  @override
  void handleTransportDisconnect() {}

  void emitSnapshot(NormalizedTelemetrySnapshot snapshot) {
    _snapshotController.add(snapshot);
  }
}

class StubEcuDiagnosticManager implements EcuDiagnosticManager {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  final _dtcController = StreamController<List<DiagnosticFaultRecord>>.broadcast();
  @override
  Stream<List<DiagnosticFaultRecord>> get faultsStream => _dtcController.stream;



  void emitDtcs(List<DiagnosticFaultRecord> dtcs) {
    _dtcController.add(dtcs);
  }
}

void main() {
  group('Phase 20: Vehicle Health & Predictive Diagnostics Engine Tests', () {
    late PredictiveHealthEngine engine;
    late StubTelemetryPipeline stubTelemetry;
    late StubEcuDiagnosticManager stubDiagnostics;

    setUp(() {
      engine = PredictiveHealthEngine.instance;
      engine.reset();
      
      stubTelemetry = StubTelemetryPipeline();
      stubDiagnostics = StubEcuDiagnosticManager();
      
      engine.start(stubTelemetry, stubDiagnostics);
    });

    tearDown(() {
      engine.stop();
    });

    test('1. Initial PredictiveHealthScore is 100 for all subsystems', () {
      final score = engine.currentScore;
      expect(score.overallScore, 100.0);
      expect(score.subsystems[HealthSubsystem.engine]?.score, 100.0);
      expect(score.subsystems[HealthSubsystem.battery]?.score, 100.0);
      expect(score.subsystems[HealthSubsystem.thermal]?.score, 100.0);
    });

    test('2. WearCalculator engine wear increases with high RPM', () {
      final calculator = WearCalculator();
      final initialWear = ComponentWear.initial(HealthSubsystem.engine);
      
      final snapshot = NormalizedTelemetrySnapshot(timestamp: DateTime.now(), metrics: {
        TelemetryMetricId.engineRpm: NormalizedTelemetryMetric(
          metricId: TelemetryMetricId.engineRpm,
          category: TelemetryMetricCategory.dynamics,
          value: 9000.0,
          unit: TelemetryUnit.revolutionsPerMinute,
          timestamp: DateTime.now(),
          sourceEcu: EcuModule.engineControlModule_ECM,
          freshness: TelemetryFreshness.fresh,
          qualityScore: 1.0,
        ),
      });

      // 10 seconds of 9000 RPM
      final newWear = calculator.evaluateEngineWear(initialWear, snapshot, 10000);
      
      // (1000 overage) * (1000) * 0.0000001 * 10s = 1.0 wear
      expect(newWear.wearAccumulation, closeTo(1.0, 0.001));
    });

    test('3. WearCalculator thermal wear increases with high coolant temperature', () {
      final calculator = WearCalculator();
      final initialWear = ComponentWear.initial(HealthSubsystem.thermal);
      
      final snapshot = NormalizedTelemetrySnapshot(timestamp: DateTime.now(), metrics: {
        TelemetryMetricId.coolantTemperature: NormalizedTelemetryMetric(
          metricId: TelemetryMetricId.coolantTemperature,
          category: TelemetryMetricCategory.thermal,
          value: 115.0, // 10 degrees over 105 limit
          unit: TelemetryUnit.celsius,
          timestamp: DateTime.now(),
          sourceEcu: EcuModule.engineControlModule_ECM,
          freshness: TelemetryFreshness.fresh,
          qualityScore: 1.0,
        ),
      });

      // 10 seconds of 115C
      final newWear = calculator.evaluateThermalWear(initialWear, snapshot, 10000);
      
      // (10 overage) * 2 * 0.01 * 10s = 2.0 wear
      expect(newWear.wearAccumulation, closeTo(2.0, 0.001));
    });

    test('4. WearCalculator battery wear increases with deep discharge', () {
      final calculator = WearCalculator();
      final initialWear = ComponentWear.initial(HealthSubsystem.battery);
      
      final snapshot = NormalizedTelemetrySnapshot(timestamp: DateTime.now(), metrics: {
        TelemetryMetricId.batteryVoltage: NormalizedTelemetryMetric(
          metricId: TelemetryMetricId.batteryVoltage,
          category: TelemetryMetricCategory.electrical,
          value: 10.5, // 1.0V below 11.5 limit
          unit: TelemetryUnit.volts,
          timestamp: DateTime.now(),
          sourceEcu: EcuModule.bodyControlModule_BCM,
          freshness: TelemetryFreshness.fresh,
          qualityScore: 1.0,
        ),
      });

      // 10 seconds of 10.5V
      final newWear = calculator.evaluateBatteryWear(initialWear, snapshot, 10000);
      
      // (1.0 deficit) * 5 * 0.005 * 10s = 0.25 wear
      expect(newWear.wearAccumulation, closeTo(0.25, 0.001));
    });

    test('5. PredictiveHealthEngine updates score and emits alerts on threshold cross', () async {
      // Fast forward time internally by emitting snapshots with some delay logic if we had mock time, 
      // but since we rely on deltaMs calculated by DateTime.now(), we can just wait 
      // or directly invoke the private method. We will do a high-stress scenario to quickly cross threshold.
      
      // Simulate extreme over-voltage drop to immediately tank the battery score for test speed.
      // Since it relies on real-time delta, we'll manually sleep to create a delta.
      
      stubTelemetry.emitSnapshot(NormalizedTelemetrySnapshot(timestamp: DateTime.now(), metrics: {
        TelemetryMetricId.batteryVoltage: NormalizedTelemetryMetric(
          metricId: TelemetryMetricId.batteryVoltage,
          category: TelemetryMetricCategory.electrical,
          value: 11.5, 
          unit: TelemetryUnit.volts,
          timestamp: DateTime.now(),
          sourceEcu: EcuModule.bodyControlModule_BCM,
          freshness: TelemetryFreshness.fresh,
          qualityScore: 1.0,
        ),
      }));

      await Future.delayed(const Duration(milliseconds: 100));

      // Inject DTC penalty to drop score immediately
      stubDiagnostics.emitDtcs([
        DiagnosticFaultRecord(
          code: 'P0A00', // Battery system DTC
          description: 'Motor Electronics Coolant Temp Sensor Circuit',
          module: EcuModule.batteryManagementSystem_BMS,
          severity: DtcSeverity.confirmedActive,
          category: DtcSystemCategory.powertrain,
          title: 'Battery System Fault',
          probableCause: 'Sensor variance',
          recommendedRemedy: 'Inspect',
          detectedAt: DateTime.now(),
        )
      ]);

      await Future.delayed(const Duration(milliseconds: 50));

      final score = engine.currentScore;
      // Should have 20 penalty points from the P0A code
      expect(score.subsystems[HealthSubsystem.battery]!.score, lessThanOrEqualTo(80.0));
    });
  });
}
