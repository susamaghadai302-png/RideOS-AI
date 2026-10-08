enum TelemetryQuality {
  verified,
  stale,
  estimated,
  unavailable,
}

class TelemetryDataPoint<T> {
  final T? value;
  final String unit;
  final String source;
  final DateTime timestamp;
  final TelemetryQuality quality;
  final double confidence;

  const TelemetryDataPoint({
    this.value,
    required this.unit,
    required this.source,
    required this.timestamp,
    required this.quality,
    this.confidence = 1.0,
  });

  factory TelemetryDataPoint.unavailable({required String unit, required String source}) {
    return TelemetryDataPoint(
      value: null,
      unit: unit,
      source: source,
      timestamp: DateTime.now(),
      quality: TelemetryQuality.unavailable,
      confidence: 0.0,
    );
  }

  bool get isValid => value != null && quality == TelemetryQuality.verified;
}

class VehicleTelemetry {
  final TelemetryDataPoint<int> rpm;
  final TelemetryDataPoint<int> speedKmh;
  final TelemetryDataPoint<int> coolantTempC;
  final TelemetryDataPoint<int> intakeTempC;
  final TelemetryDataPoint<double> batteryVoltage;
  final TelemetryDataPoint<double> throttlePositionPercent;
  
  const VehicleTelemetry({
    required this.rpm,
    required this.speedKmh,
    required this.coolantTempC,
    required this.intakeTempC,
    required this.batteryVoltage,
    required this.throttlePositionPercent,
  });

  factory VehicleTelemetry.empty() {
    return VehicleTelemetry(
      rpm: TelemetryDataPoint.unavailable(unit: 'RPM', source: 'SYSTEM'),
      speedKmh: TelemetryDataPoint.unavailable(unit: 'km/h', source: 'SYSTEM'),
      coolantTempC: TelemetryDataPoint.unavailable(unit: '°C', source: 'SYSTEM'),
      intakeTempC: TelemetryDataPoint.unavailable(unit: '°C', source: 'SYSTEM'),
      batteryVoltage: TelemetryDataPoint.unavailable(unit: 'V', source: 'SYSTEM'),
      throttlePositionPercent: TelemetryDataPoint.unavailable(unit: '%', source: 'SYSTEM'),
    );
  }
}
