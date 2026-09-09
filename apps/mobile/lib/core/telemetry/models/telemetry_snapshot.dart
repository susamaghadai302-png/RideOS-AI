import 'package:flutter/foundation.dart';
import 'metric_types.dart';
import 'telemetry_metric.dart';

/// Multi-metric normalized telemetry snapshot at an instant in time.
@immutable
class NormalizedTelemetrySnapshot {
  final Map<TelemetryMetricId, NormalizedTelemetryMetric> metrics;
  final DateTime timestamp;
  final bool isSimulated;
  final String? activeVehicleId;

  const NormalizedTelemetrySnapshot({
    required this.metrics,
    required this.timestamp,
    this.isSimulated = false,
    this.activeVehicleId,
  });

  /// Factory for an empty/unavailable initial snapshot.
  factory NormalizedTelemetrySnapshot.initial() {
    final metrics = <TelemetryMetricId, NormalizedTelemetryMetric>{};
    for (final id in TelemetryMetricId.values) {
      metrics[id] = NormalizedTelemetryMetric.unavailable(
        metricId: id,
        unit: _defaultUnitFor(id),
      );
    }
    return NormalizedTelemetrySnapshot(
      metrics: metrics,
      timestamp: DateTime.now(),
      isSimulated: false,
    );
  }

  // Convenience Typed Getters
  NormalizedTelemetryMetric? getMetric(TelemetryMetricId id) => metrics[id];

  double? get speedKmh => metrics[TelemetryMetricId.vehicleSpeed]?.value;
  double? get engineRpm => metrics[TelemetryMetricId.engineRpm]?.value;
  double? get coolantTempCelsius => metrics[TelemetryMetricId.coolantTemperature]?.value;
  double? get batteryVoltage => metrics[TelemetryMetricId.batteryVoltage]?.value;
  double? get throttlePercentage => metrics[TelemetryMetricId.throttlePosition]?.value;
  double? get fuelLevelPercentage => metrics[TelemetryMetricId.fuelLevelPercentage]?.value;

  /// Returns count of metrics currently reported as LIVE/fresh.
  int get liveMetricCount => metrics.values.where((m) => m.isLive).length;

  /// Returns count of stale metrics.
  int get staleMetricCount =>
      metrics.values.where((m) => m.freshness == TelemetryFreshness.stale).length;

  /// Returns true if primary powertrain stream (Speed or RPM) is live.
  bool get hasLivePowertrainStream =>
      (metrics[TelemetryMetricId.vehicleSpeed]?.isLive ?? false) ||
      (metrics[TelemetryMetricId.engineRpm]?.isLive ?? false);

  /// Creates an updated snapshot with a single updated or replaced metric.
  NormalizedTelemetrySnapshot withUpdatedMetric(NormalizedTelemetryMetric updated) {
    final newMetrics = Map<TelemetryMetricId, NormalizedTelemetryMetric>.from(metrics);
    newMetrics[updated.metricId] = updated;
    return NormalizedTelemetrySnapshot(
      metrics: newMetrics,
      timestamp: DateTime.now(),
      isSimulated: isSimulated,
      activeVehicleId: activeVehicleId,
    );
  }

  /// Evaluates and transitions stale metrics in the snapshot based on elapsed time.
  NormalizedTelemetrySnapshot evaluateFreshness(
    Duration freshnessThreshold,
    Duration unavailableThreshold,
  ) {
    final now = DateTime.now();
    final newMetrics = <TelemetryMetricId, NormalizedTelemetryMetric>{};
    bool changed = false;

    for (final entry in metrics.entries) {
      final metric = entry.value;
      if (metric.value == null || metric.freshness == TelemetryFreshness.unavailable) {
        newMetrics[entry.key] = metric;
        continue;
      }

      final elapsed = now.difference(metric.timestamp);
      if (elapsed > unavailableThreshold && metric.freshness != TelemetryFreshness.unavailable) {
        newMetrics[entry.key] = metric.copyWithFreshness(TelemetryFreshness.unavailable);
        changed = true;
      } else if (elapsed > freshnessThreshold && metric.freshness == TelemetryFreshness.fresh) {
        newMetrics[entry.key] = metric.copyWithFreshness(TelemetryFreshness.stale);
        changed = true;
      } else {
        newMetrics[entry.key] = metric;
      }
    }

    if (!changed) return this;

    return NormalizedTelemetrySnapshot(
      metrics: newMetrics,
      timestamp: now,
      isSimulated: isSimulated,
      activeVehicleId: activeVehicleId,
    );
  }

  Map<String, dynamic> toJson() => {
        'timestamp': timestamp.toIso8601String(),
        'isSimulated': isSimulated,
        'activeVehicleId': activeVehicleId,
        'metrics': metrics.map((k, v) => MapEntry(k.name, v.toJson())),
      };

  static TelemetryUnit _defaultUnitFor(TelemetryMetricId id) {
    switch (id) {
      case TelemetryMetricId.vehicleSpeed:
        return TelemetryUnit.kilometersPerHour;
      case TelemetryMetricId.engineRpm:
        return TelemetryUnit.revolutionsPerMinute;
      case TelemetryMetricId.throttlePosition:
      case TelemetryMetricId.calculatedEngineLoad:
      case TelemetryMetricId.fuelLevelPercentage:
        return TelemetryUnit.percentage;
      case TelemetryMetricId.coolantTemperature:
      case TelemetryMetricId.intakeAirTemperature:
      case TelemetryMetricId.engineOilTemperature:
        return TelemetryUnit.celsius;
      case TelemetryMetricId.batteryVoltage:
      case TelemetryMetricId.controlModuleVoltage:
        return TelemetryUnit.volts;
      case TelemetryMetricId.massAirFlow:
        return TelemetryUnit.gramsPerSecond;
      case TelemetryMetricId.estimatedFuelRateLph:
        return TelemetryUnit.litersPerHour;
      case TelemetryMetricId.energyConsumptionKwh:
        return TelemetryUnit.kilowattHours;
      case TelemetryMetricId.longitudinalAcceleration:
      case TelemetryMetricId.lateralAcceleration:
        return TelemetryUnit.metersPerSecondSquared;
    }
  }
}
