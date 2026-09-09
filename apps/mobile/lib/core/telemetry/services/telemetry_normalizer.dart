import '../models/metric_types.dart';
import '../models/telemetry_metric.dart';
import '../../diagnostics/models/diagnostic_types.dart';
import '../../diagnostics/models/pid_definition.dart';

/// Service that translates Phase 18 diagnostic PID measurements into
/// normalized telemetry data models with unit conversions and range validation.
class TelemetryNormalizer {
  static final TelemetryNormalizer instance = TelemetryNormalizer._internal();
  factory TelemetryNormalizer() => instance;
  TelemetryNormalizer._internal();

  /// Maps a Phase 18 [DecodedPidMeasurement] into a [NormalizedTelemetryMetric].
  NormalizedTelemetryMetric normalizePidMeasurement(
    DecodedPidMeasurement measurement, {
    EcuModule sourceEcu = EcuModule.engineControlModule_ECM,
    bool isSimulated = false,
  }) {
    final metricId = _mapPidToMetricId(measurement.pid);
    if (metricId == null) {
      return NormalizedTelemetryMetric.unavailable(
        metricId: TelemetryMetricId.vehicleSpeed,
        unit: TelemetryUnit.kilometersPerHour,
        sourceEcu: sourceEcu,
        diagnosticNote: 'Unmapped PID 0x${measurement.pid.code}',
      );
    }

    final rawVal = measurement.value;
    final unit = _resolveUnit(metricId);

    // Range / Sanity Validation
    if (rawVal < measurement.pid.minValidValue || rawVal > measurement.pid.maxValidValue) {
      return NormalizedTelemetryMetric.invalid(
        metricId: metricId,
        rawValue: rawVal,
        unit: unit,
        sourceEcu: sourceEcu,
        reason: 'Value $rawVal out of valid physical range [${measurement.pid.minValidValue}..${measurement.pid.maxValidValue}]',
      );
    }

    return NormalizedTelemetryMetric(
      metricId: metricId,
      category: metricId.category,
      value: rawVal,
      unit: unit,
      timestamp: measurement.timestamp,
      sourceEcu: sourceEcu,
      diagnosticPidCode: measurement.pid.code,
      freshness: TelemetryFreshness.fresh,
      qualityScore: 1.0,
      isSimulated: isSimulated,
      diagnosticNote: 'Decoded from standard Mode \$01 PID 0x${measurement.pid.code}',
    );
  }

  /// Calculates derived longitudinal acceleration from two consecutive speed measurements.
  NormalizedTelemetryMetric? computeDerivedAcceleration({
    required NormalizedTelemetryMetric previousSpeed,
    required NormalizedTelemetryMetric currentSpeed,
  }) {
    if (previousSpeed.value == null || currentSpeed.value == null) return null;

    final dt = currentSpeed.timestamp.difference(previousSpeed.timestamp).inMilliseconds / 1000.0;
    if (dt <= 0.001 || dt > 2.0) return null; // Avoid division by zero or large gaps

    // Convert km/h to m/s: v (m/s) = v (km/h) / 3.6
    final v0 = previousSpeed.value! / 3.6;
    final v1 = currentSpeed.value! / 3.6;
    final accelMs2 = (v1 - v0) / dt;

    // Clamp sanity limits (-15 m/s² hard emergency braking to +15 m/s² superbike launch)
    if (accelMs2 < -15.0 || accelMs2 > 15.0) return null;

    return NormalizedTelemetryMetric(
      metricId: TelemetryMetricId.longitudinalAcceleration,
      category: TelemetryMetricCategory.dynamics,
      value: accelMs2,
      unit: TelemetryUnit.metersPerSecondSquared,
      timestamp: currentSpeed.timestamp,
      sourceEcu: currentSpeed.sourceEcu,
      diagnosticPidCode: 'DERIVED_DV_DT',
      freshness: TelemetryFreshness.fresh,
      qualityScore: 0.95,
      isSimulated: currentSpeed.isSimulated,
      diagnosticNote: 'Derived from speed delta (Δv/Δt) over ${dt.toStringAsFixed(2)}s',
    );
  }

  static TelemetryMetricId? _mapPidToMetricId(DiagnosticPid pid) {
    switch (pid.code) {
      case '0C':
        return TelemetryMetricId.engineRpm;
      case '0D':
        return TelemetryMetricId.vehicleSpeed;
      case '05':
        return TelemetryMetricId.coolantTemperature;
      case '0F':
        return TelemetryMetricId.intakeAirTemperature;
      case '11':
        return TelemetryMetricId.throttlePosition;
      case '04':
        return TelemetryMetricId.calculatedEngineLoad;
      case '42':
        return TelemetryMetricId.controlModuleVoltage;
      case '2F':
        return TelemetryMetricId.fuelLevelPercentage;
      case '10':
        return TelemetryMetricId.massAirFlow;
      case '5C':
        return TelemetryMetricId.engineOilTemperature;
      default:
        return null;
    }
  }

  static TelemetryUnit _resolveUnit(TelemetryMetricId id) {
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
