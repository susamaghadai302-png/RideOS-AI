class TelemetryValue<T> {
  final T? value;
  final String unit;
  final bool available;
  final String source; // vehicle, gps, imu, ecu_calculated, estimated
  final String quality; // live, stale, degraded, unavailable
  final DateTime timestamp;

  TelemetryValue({
    this.value,
    this.unit = '',
    required this.available,
    this.source = 'vehicle',
    this.quality = 'live',
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory TelemetryValue.unavailable() {
    return TelemetryValue(
      available: false,
      quality: 'unavailable',
      timestamp: DateTime.now(),
    );
  }

  factory TelemetryValue.live(
    T value,
    String unit, {
    String source = 'vehicle',
    String quality = 'live',
  }) {
    return TelemetryValue(
      value: value,
      unit: unit,
      available: true,
      source: source,
      quality: quality,
      timestamp: DateTime.now(),
    );
  }

  /// Calculates data freshness in milliseconds
  int get latencyMs => DateTime.now().difference(timestamp).inMilliseconds;

  /// Whether telemetry value is present and available
  bool get hasValue => available && value != null;

  /// Flags stale warning if data has not been updated within duration
  bool get isStale => available && latencyMs > 3000;

  Map<String, dynamic> toJson() => {
        'value': value,
        'unit': unit,
        'available': available,
        'source': source,
        'quality': isStale ? 'stale' : quality,
        'timestamp': timestamp.toIso8601String(),
        'latencyMs': latencyMs,
      };
}
