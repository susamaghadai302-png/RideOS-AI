import 'package:flutter/foundation.dart';
import '../models/metric_types.dart';

/// Configurable policy determining when telemetry transitions between
/// FRESH, STALE, and UNAVAILABLE states.
@immutable
class TelemetryFreshnessPolicy {
  /// Default duration after which a metric is classified as STALE if no update is received.
  final Duration defaultFreshnessThreshold;

  /// Default duration after which a metric is classified as UNAVAILABLE.
  final Duration defaultUnavailableThreshold;

  /// Per-metric freshness duration overrides.
  final Map<TelemetryMetricId, Duration> metricFreshnessOverrides;

  /// Per-metric unavailable duration overrides.
  final Map<TelemetryMetricId, Duration> metricUnavailableOverrides;

  const TelemetryFreshnessPolicy({
    this.defaultFreshnessThreshold = const Duration(seconds: 3),
    this.defaultUnavailableThreshold = const Duration(seconds: 8),
    this.metricFreshnessOverrides = const {
      // High-frequency dynamic metrics expire faster
      TelemetryMetricId.vehicleSpeed: Duration(milliseconds: 1500),
      TelemetryMetricId.engineRpm: Duration(milliseconds: 1500),
      TelemetryMetricId.throttlePosition: Duration(milliseconds: 1500),
      // Slow-changing thermal metrics have longer tolerance
      TelemetryMetricId.coolantTemperature: Duration(seconds: 5),
      TelemetryMetricId.engineOilTemperature: Duration(seconds: 5),
      TelemetryMetricId.intakeAirTemperature: Duration(seconds: 5),
    },
    this.metricUnavailableOverrides = const {
      TelemetryMetricId.vehicleSpeed: Duration(seconds: 5),
      TelemetryMetricId.engineRpm: Duration(seconds: 5),
    },
  });

  /// Standard production freshness policy instance.
  static const TelemetryFreshnessPolicy standard = TelemetryFreshnessPolicy();

  /// High-responsiveness track / racing freshness policy.
  static const TelemetryFreshnessPolicy trackPerformance = TelemetryFreshnessPolicy(
    defaultFreshnessThreshold: Duration(milliseconds: 1000),
    defaultUnavailableThreshold: Duration(seconds: 3),
  );

  /// Evaluates the current freshness state for a given measurement timestamp.
  TelemetryFreshness evaluateFreshness(
    DateTime measurementTime, {
    TelemetryMetricId? metricId,
    DateTime? currentTime,
  }) {
    final now = currentTime ?? DateTime.now();
    final elapsed = now.difference(measurementTime);

    if (elapsed.isNegative) {
      // Clock skew or future timestamp -> treat as fresh
      return TelemetryFreshness.fresh;
    }

    final unavailThreshold = (metricId != null ? metricUnavailableOverrides[metricId] : null) ??
        defaultUnavailableThreshold;

    if (elapsed > unavailThreshold) {
      return TelemetryFreshness.unavailable;
    }

    final freshThreshold = (metricId != null ? metricFreshnessOverrides[metricId] : null) ??
        defaultFreshnessThreshold;

    if (elapsed > freshThreshold) {
      return TelemetryFreshness.stale;
    }

    return TelemetryFreshness.fresh;
  }
}
