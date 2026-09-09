import '../../telemetry/models/telemetry_snapshot.dart';
import '../../telemetry/models/metric_types.dart';
import '../models/component_wear.dart';

// Test automation checkpoint
class WearCalculator {
  // Configurable thresholds for wear accumulation
  static const double maxRpmThreshold = 8000.0;
  static const double overheatThreshold = 105.0; // Celsius
  static const double lowVoltageThreshold = 11.5; // Volts

  /// Evaluates the instantaneous telemetry snapshot and updates the component wear
  /// [deltaMs] is the time elapsed since the last evaluation to integrate wear over time.
  ComponentWear evaluateEngineWear(
    ComponentWear currentWear,
    NormalizedTelemetrySnapshot snapshot,
    int deltaMs,
  ) {
    final metric = snapshot.getMetric(TelemetryMetricId.engineRpm);
    if (metric == null || metric.freshness != TelemetryFreshness.fresh || metric.value == null) {
      return currentWear;
    }

    double wearIncrement = 0.0;
    final rpm = metric.value as num;

    // High RPM wear penalty
    if (rpm > maxRpmThreshold) {
      // Exponential wear based on how far over threshold
      final overage = rpm - maxRpmThreshold;
      wearIncrement += (overage * overage) * 0.0000001 * (deltaMs / 1000.0);
    }

    return currentWear.copyWith(
      wearAccumulation: (currentWear.wearAccumulation + wearIncrement).clamp(0.0, 100.0),
    );
  }

  ComponentWear evaluateThermalWear(
    ComponentWear currentWear,
    NormalizedTelemetrySnapshot snapshot,
    int deltaMs,
  ) {
    final metric = snapshot.getMetric(TelemetryMetricId.coolantTemperature);
    if (metric == null || metric.freshness != TelemetryFreshness.fresh || metric.value == null) {
      return currentWear;
    }

    double wearIncrement = 0.0;
    final temp = metric.value as num;

    // Overheating wear penalty
    if (temp > overheatThreshold) {
      final overage = temp - overheatThreshold;
      wearIncrement += (overage * 2.0) * 0.01 * (deltaMs / 1000.0);
    }

    return currentWear.copyWith(
      wearAccumulation: (currentWear.wearAccumulation + wearIncrement).clamp(0.0, 100.0),
    );
  }

  ComponentWear evaluateBatteryWear(
    ComponentWear currentWear,
    NormalizedTelemetrySnapshot snapshot,
    int deltaMs,
  ) {
    final metric = snapshot.getMetric(TelemetryMetricId.batteryVoltage);
    if (metric == null || metric.freshness != TelemetryFreshness.fresh || metric.value == null) {
      return currentWear;
    }

    double wearIncrement = 0.0;
    final volts = metric.value as num;

    // Deep discharge penalty
    if (volts < lowVoltageThreshold && volts > 5.0) { // ignoring 0V readings
      final deficit = lowVoltageThreshold - volts;
      wearIncrement += (deficit * 5.0) * 0.005 * (deltaMs / 1000.0);
    }

    return currentWear.copyWith(
      wearAccumulation: (currentWear.wearAccumulation + wearIncrement).clamp(0.0, 100.0),
    );
  }
}
