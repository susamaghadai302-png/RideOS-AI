import 'package:flutter/foundation.dart';
import 'normalized_telemetry_models.dart';

@immutable
class FieldLinkHealthSnapshot {
  final double packetRateHz;
  final double packetLossPercentage;
  final int latencyMs;
  final int reconnectCount;
  final double sensorFreshnessSeconds;
  final int dataQualityScore; // 0 - 100
  final TelemetryDataSource source;
  final int rssi;

  const FieldLinkHealthSnapshot({
    required this.packetRateHz,
    required this.packetLossPercentage,
    required this.latencyMs,
    required this.reconnectCount,
    required this.sensorFreshnessSeconds,
    required this.dataQualityScore,
    required this.source,
    required this.rssi,
  });

  String get sourceBadgeText {
    switch (source) {
      case TelemetryDataSource.realDevice:
        return 'LIVE HARDWARE';
      case TelemetryDataSource.benchTest:
        return 'BENCH TEST';

    }
  }

  bool get isHealthy => packetLossPercentage < 5.0 && latencyMs < 120 && sensorFreshnessSeconds < 2.0;
}

@immutable
class RecordedRideSession {
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final double totalDistanceKm;
  final double durationMinutes;
  final double maxSpeedKmh;
  final double averageSpeedKmh;
  final int maxRpm;
  final int averageRpm;
  final double maxLeanAngleDeg;
  final double batteryMinVoltage;
  final double batteryMaxVoltage;
  final int totalPacketsReceived;
  final double averagePacketLossPct;
  final int connectionInterruptions;
  final List<DiagnosticTroubleCode> detectedDtcs;
  final TelemetryDataSource dataSource;

  const RecordedRideSession({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    required this.totalDistanceKm,
    required this.durationMinutes,
    required this.maxSpeedKmh,
    required this.averageSpeedKmh,
    required this.maxRpm,
    required this.averageRpm,
    required this.maxLeanAngleDeg,
    required this.batteryMinVoltage,
    required this.batteryMaxVoltage,
    required this.totalPacketsReceived,
    required this.averagePacketLossPct,
    required this.connectionInterruptions,
    required this.detectedDtcs,
    required this.dataSource,
  });

  Map<String, dynamic> toJson() => {
    'sessionId': sessionId,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'totalDistanceKm': totalDistanceKm,
    'durationMinutes': durationMinutes,
    'maxSpeedKmh': maxSpeedKmh,
    'averageSpeedKmh': averageSpeedKmh,
    'maxRpm': maxRpm,
    'averageRpm': averageRpm,
    'maxLeanAngleDeg': maxLeanAngleDeg,
    'batteryMinVoltage': batteryMinVoltage,
    'batteryMaxVoltage': batteryMaxVoltage,
    'totalPacketsReceived': totalPacketsReceived,
    'averagePacketLossPct': averagePacketLossPct,
    'connectionInterruptions': connectionInterruptions,
    'detectedDtcs': detectedDtcs.map((d) => d.toJson()).toList(),
    'dataSource': dataSource.name,
  };
}
