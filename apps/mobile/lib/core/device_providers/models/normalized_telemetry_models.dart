import 'package:flutter/foundation.dart';

enum TelemetryDataSource {
  realDevice,
  benchTest;

  String get label {
    switch (this) {
      case TelemetryDataSource.realDevice:
        return 'REAL DEVICE';
      case TelemetryDataSource.benchTest:
        return 'BENCH TEST';
    }
  }
}

enum MetricConfidence {
  validLive,
  stale,
  unsupported;
}

@immutable
class TelemetryMetric<T> {
  final T? value;
  final String unit;
  final DateTime timestamp;
  final TelemetryDataSource source;
  final MetricConfidence confidence;

  const TelemetryMetric({
    this.value,
    required this.unit,
    required this.timestamp,
    this.source = TelemetryDataSource.realDevice,
    this.confidence = MetricConfidence.unsupported,
  });

  bool get isAvailable => value != null && confidence != MetricConfidence.unsupported;
  bool get isLive => isAvailable && confidence == MetricConfidence.validLive;

  String get formattedValue {
    if (!isAvailable) return '--';
    if (value is double) return (value as double).toStringAsFixed(1);
    return value.toString();
  }

  String get formattedWithUnit => '$formattedValue $unit'.trim();
}

@immutable
class NormalizedTelemetrySnapshot {
  final TelemetryDataSource dataSource;
  final DateTime timestamp;
  final int rssi;
  final double packetLossPercentage;

  // Powertrain Metrics
  final TelemetryMetric<double> vehicleSpeedKmh;
  final TelemetryMetric<int> engineRpm;
  final TelemetryMetric<int> gearPosition;
  final TelemetryMetric<double> throttlePositionPct;
  final TelemetryMetric<double> engineLoadPct;

  // Thermal & Electrical Metrics
  final TelemetryMetric<double> coolantTempC;
  final TelemetryMetric<double> engineTempC;
  final TelemetryMetric<double> intakeTempC;
  final TelemetryMetric<double> batteryVoltage;
  final TelemetryMetric<double> batteryCurrentAmps;
  final TelemetryMetric<double> fuelLevelPct;

  // Dynamics & IMU
  final TelemetryMetric<double> leanAngleDeg;
  final TelemetryMetric<double> vibrationLevelG;
  final TelemetryMetric<double> accelerationX;
  final TelemetryMetric<double> accelerationY;
  final TelemetryMetric<double> accelerationZ;

  // Safety & Switches
  final bool isIgnitionOn;
  final bool isSideStandDown;
  final bool isBrakeEngaged;
  final bool isAbsActive;
  final bool isTractionControlActive;
  final String ridingMode;

  const NormalizedTelemetrySnapshot({
    required this.dataSource,
    required this.timestamp,
    this.rssi = -60,
    this.packetLossPercentage = 0.0,
    required this.vehicleSpeedKmh,
    required this.engineRpm,
    required this.gearPosition,
    required this.throttlePositionPct,
    required this.engineLoadPct,
    required this.coolantTempC,
    required this.engineTempC,
    required this.intakeTempC,
    required this.batteryVoltage,
    required this.batteryCurrentAmps,
    required this.fuelLevelPct,
    required this.leanAngleDeg,
    required this.vibrationLevelG,
    required this.accelerationX,
    required this.accelerationY,
    required this.accelerationZ,
    this.isIgnitionOn = true,
    this.isSideStandDown = false,
    this.isBrakeEngaged = false,
    this.isAbsActive = false,
    this.isTractionControlActive = false,
    this.ridingMode = 'STREET',
  });
}

enum DtcSeverity {
  info,
  caution,
  warning,
  critical;
}

@immutable
class DiagnosticTroubleCode {
  final String code; // e.g. "P0300"
  final String subsystem; // e.g. "Powertrain / Ignition"
  final String description;
  final DtcSeverity severity;
  final DateTime firstDetectedAt;
  final DateTime lastDetectedAt;
  final bool isActive;
  final Map<String, dynamic>? freezeFrameData;

  const DiagnosticTroubleCode({
    required this.code,
    required this.subsystem,
    required this.description,
    required this.severity,
    required this.firstDetectedAt,
    required this.lastDetectedAt,
    this.isActive = true,
    this.freezeFrameData,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'subsystem': subsystem,
    'description': description,
    'severity': severity.name,
    'firstDetectedAt': firstDetectedAt.toIso8601String(),
    'lastDetectedAt': lastDetectedAt.toIso8601String(),
    'isActive': isActive,
    'freezeFrameData': freezeFrameData,
  };
}
