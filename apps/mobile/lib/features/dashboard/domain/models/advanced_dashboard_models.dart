import 'package:flutter/foundation.dart';

enum RideState {
  idle,
  ready,
  riding,
  paused,
  completed,
  error;

  String get label {
    switch (this) {
      case RideState.idle:
        return 'IDLE';
      case RideState.ready:
        return 'READY';
      case RideState.riding:
        return 'RIDING';
      case RideState.paused:
        return 'PAUSED';
      case RideState.completed:
        return 'COMPLETED';
      case RideState.error:
        return 'ERROR';
    }
  }
}

enum TelemetryConnectionStatus {
  connected,
  connecting,
  disconnected,
  error,
  unsupported;

  String get label {
    switch (this) {
      case TelemetryConnectionStatus.connected:
        return 'CONNECTED';
      case TelemetryConnectionStatus.connecting:
        return 'CONNECTING';
      case TelemetryConnectionStatus.disconnected:
        return 'DISCONNECTED';
      case TelemetryConnectionStatus.error:
        return 'ERROR';
      case TelemetryConnectionStatus.unsupported:
        return 'UNSUPPORTED';
    }
  }
}

@immutable
class LiveRideMetrics {
  final double? speedKmh;
  final int? rpm;
  final int? gear;
  final double? coolantTempC;
  final double? batteryVoltage;
  final double? fuelLevelPercent;
  final double? leanAngleDeg;
  final double distanceKm;
  final int durationSeconds;
  final DateTime timestamp;
  final bool isStale;

  const LiveRideMetrics({
    this.speedKmh,
    this.rpm,
    this.gear,
    this.coolantTempC,
    this.batteryVoltage,
    this.fuelLevelPercent,
    this.leanAngleDeg,
    this.distanceKm = 0.0,
    this.durationSeconds = 0,
    required this.timestamp,
    this.isStale = false,
  });

  LiveRideMetrics copyWith({
    double? speedKmh,
    int? rpm,
    int? gear,
    double? coolantTempC,
    double? batteryVoltage,
    double? fuelLevelPercent,
    double? leanAngleDeg,
    double? distanceKm,
    int? durationSeconds,
    DateTime? timestamp,
    bool? isStale,
  }) {
    return LiveRideMetrics(
      speedKmh: speedKmh ?? this.speedKmh,
      rpm: rpm ?? this.rpm,
      gear: gear ?? this.gear,
      coolantTempC: coolantTempC ?? this.coolantTempC,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      fuelLevelPercent: fuelLevelPercent ?? this.fuelLevelPercent,
      leanAngleDeg: leanAngleDeg ?? this.leanAngleDeg,
      distanceKm: distanceKm ?? this.distanceKm,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      timestamp: timestamp ?? this.timestamp,
      isStale: isStale ?? this.isStale,
    );
  }
}

@immutable
class HistoricalChartPoint {
  final DateTime timestamp;
  final double speedKmh;
  final int rpm;
  final double coolantTempC;
  final double batteryVoltage;

  const HistoricalChartPoint({
    required this.timestamp,
    required this.speedKmh,
    required this.rpm,
    required this.coolantTempC,
    required this.batteryVoltage,
  });
}
