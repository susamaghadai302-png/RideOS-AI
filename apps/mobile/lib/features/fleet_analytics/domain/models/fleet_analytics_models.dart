import 'package:flutter/foundation.dart';

@immutable
class HistoricalRideEntry {
  final String sessionId;
  final DateTime date;
  final double distanceKm;
  final double durationMinutes;
  final double maxSpeedKmh;
  final double maxLeanAngleDeg;
  final int maxRpm;
  final bool isSynced;

  const HistoricalRideEntry({
    required this.sessionId,
    required this.date,
    required this.distanceKm,
    required this.durationMinutes,
    required this.maxSpeedKmh,
    required this.maxLeanAngleDeg,
    required this.maxRpm,
    this.isSynced = true,
  });
}

@immutable
class MaintenanceServiceRecord {
  final String id;
  final String bikeId;
  final String taskType; // 'OIL_CHANGE', 'CHAIN_LUBE', 'BRAKE_PADS', 'TIRES'
  final int performedAtKm;
  final DateTime performedAtDate;
  final int nextDueKm;
  final double cost;
  final String notes;

  const MaintenanceServiceRecord({
    required this.id,
    required this.bikeId,
    required this.taskType,
    required this.performedAtKm,
    required this.performedAtDate,
    required this.nextDueKm,
    this.cost = 0.0,
    this.notes = '',
  });
}

@immutable
class FleetAnalyticsSummary {
  final int totalRides;
  final double totalDistanceKm;
  final double totalDurationMinutes;
  final double averageSpeedKmh;
  final double topMaxSpeedKmh;
  final int topMaxRpm;
  final double peakLeanAngleDeg;
  final double batteryHealthScorePct;
  final double coolantStabilityPct;
  final int activeDtcCount;
  final int fleetSafetyScore;
  final List<HistoricalRideEntry> recentRides;
  final List<MaintenanceServiceRecord> maintenanceRecords;

  const FleetAnalyticsSummary({
    required this.totalRides,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.averageSpeedKmh,
    required this.topMaxSpeedKmh,
    required this.topMaxRpm,
    required this.peakLeanAngleDeg,
    required this.batteryHealthScorePct,
    required this.coolantStabilityPct,
    required this.activeDtcCount,
    required this.fleetSafetyScore,
    required this.recentRides,
    required this.maintenanceRecords,
  });
}
