import 'package:flutter/foundation.dart';
import '../models/metric_types.dart';

/// Configurable Deadband Filter Policy to suppress redundant stream emissions
/// caused by negligible sensor jitter or analog noise.
@immutable
class TelemetryDeadbandPolicy {
  /// Minimum absolute delta change required to trigger a stream emission per metric.
  final Map<TelemetryMetricId, double> deltaThresholds;

  /// Whether deadband filtering is globally enabled.
  final bool isEnabled;

  const TelemetryDeadbandPolicy({
    this.isEnabled = true,
    this.deltaThresholds = const {
      // Dynamics
      TelemetryMetricId.vehicleSpeed: 0.5,            // 0.5 km/h
      TelemetryMetricId.engineRpm: 25.0,              // 25.0 RPM
      TelemetryMetricId.throttlePosition: 0.5,        // 0.5 %
      TelemetryMetricId.calculatedEngineLoad: 0.5,    // 0.5 %
      TelemetryMetricId.longitudinalAcceleration: 0.05, // 0.05 m/s²
      TelemetryMetricId.lateralAcceleration: 0.05,      // 0.05 m/s²

      // Thermal
      TelemetryMetricId.coolantTemperature: 0.5,      // 0.5 °C
      TelemetryMetricId.intakeAirTemperature: 0.5,    // 0.5 °C
      TelemetryMetricId.engineOilTemperature: 0.5,    // 0.5 °C

      // Electrical
      TelemetryMetricId.batteryVoltage: 0.05,         // 0.05 V
      TelemetryMetricId.controlModuleVoltage: 0.05,   // 0.05 V

      // Fuel & Energy
      TelemetryMetricId.fuelLevelPercentage: 0.5,     // 0.5 %
      TelemetryMetricId.massAirFlow: 0.2,             // 0.2 g/s
      TelemetryMetricId.estimatedFuelRateLph: 0.1,    // 0.1 L/h
    },
  });

  /// Standard production deadband policy.
  static const TelemetryDeadbandPolicy standard = TelemetryDeadbandPolicy();

  /// Zero-deadband policy for raw calibration / high-rate telemetry logging.
  static const TelemetryDeadbandPolicy zeroDeadband = TelemetryDeadbandPolicy(
    isEnabled: false,
    deltaThresholds: {},
  );

  /// Determines whether a new measurement differs enough from the previous value
  /// to justify emitting a stream event.
  bool shouldEmit(
    TelemetryMetricId metricId,
    double? previousValue,
    double? newValue,
  ) {
    if (!isEnabled) return true;

    // If either value is null (e.g. transition to/from unavailable), always emit
    if (previousValue == null || newValue == null) return true;

    final threshold = deltaThresholds[metricId] ?? 0.0;
    if (threshold <= 0.0) return true;

    final delta = (newValue - previousValue).abs();
    return delta >= threshold;
  }
}
