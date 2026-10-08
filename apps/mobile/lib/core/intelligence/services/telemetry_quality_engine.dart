import 'package:rideos_mobile/core/hardware/telemetry/vehicle_telemetry.dart';

class TelemetryQualityEngine {
  static const Duration _staleThreshold = Duration(seconds: 10);

  static TelemetryDataPoint<T> evaluateQuality<T>({
    required T? value,
    required String unit,
    required String source,
    required DateTime? timestamp,
    required bool isHardwareConnected,
  }) {
    if (!isHardwareConnected) {
      if (value != null && timestamp != null) {
        return TelemetryDataPoint<T>(
          value: value,
          unit: unit,
          source: source,
          timestamp: timestamp,
          quality: TelemetryQuality.stale,
          confidence: 0.5,
        );
      }
      return TelemetryDataPoint<T>.unavailable(unit: unit, source: source);
    }

    if (value == null || timestamp == null) {
      return TelemetryDataPoint<T>.unavailable(unit: unit, source: source);
    }

    final age = DateTime.now().difference(timestamp);
    if (age > _staleThreshold) {
      return TelemetryDataPoint<T>(
        value: value,
        unit: unit,
        source: source,
        timestamp: timestamp,
        quality: TelemetryQuality.stale,
        confidence: 0.7,
      );
    }

    return TelemetryDataPoint<T>(
      value: value,
      unit: unit,
      source: source,
      timestamp: timestamp,
      quality: TelemetryQuality.verified,
      confidence: 1.0,
    );
  }
}
