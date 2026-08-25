import 'package:flutter/foundation.dart';

enum MaintenancePriority {
  critical,
  high,
  medium,
  normal;

  String get label {
    switch (this) {
      case MaintenancePriority.critical:
        return 'CRITICAL';
      case MaintenancePriority.high:
        return 'HIGH';
      case MaintenancePriority.medium:
        return 'MEDIUM';
      case MaintenancePriority.normal:
        return 'NORMAL';
    }
  }
}

enum InsightCategory {
  health,
  safety,
  maintenance,
  performance,
  trip,
}

@immutable
class VehicleHealthSummary {
  final int overallHealthScore; // 0 - 100%
  final int engineScore;
  final int batteryScore;
  final int coolantScore;
  final int maintenanceScore;
  final int tirePressureScore;
  final List<String> criticalWarnings;
  final List<String> normalIndicators;
  final List<String> recommendations;

  const VehicleHealthSummary({
    required this.overallHealthScore,
    required this.engineScore,
    required this.batteryScore,
    required this.coolantScore,
    required this.maintenanceScore,
    required this.tirePressureScore,
    required this.criticalWarnings,
    required this.normalIndicators,
    required this.recommendations,
  });
}

@immutable
class RidingAnalyticsSummary {
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final double totalDistanceKm;
  final double totalDurationMinutes;
  final int peakRpm;
  final double maxLeanAngleDeg;
  final int ridingConsistencyScore; // 0 - 100
  final int overallSafetyScore; // 0 - 100
  final String efficiencyRating; // 'Apex Elite', 'Sport Tourer', etc.
  final List<String> performanceInsights;

  const RidingAnalyticsSummary({
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    required this.totalDistanceKm,
    required this.totalDurationMinutes,
    required this.peakRpm,
    required this.maxLeanAngleDeg,
    required this.ridingConsistencyScore,
    required this.overallSafetyScore,
    required this.efficiencyRating,
    required this.performanceInsights,
  });
}

@immutable
class SmartMaintenanceMilestone {
  final String taskType;
  final MaintenancePriority priority;
  final int performedAtKm;
  final int nextDueKm;
  final int remainingKm;
  final String explanation;
  final String recommendedAction;

  const SmartMaintenanceMilestone({
    required this.taskType,
    required this.priority,
    required this.performedAtKm,
    required this.nextDueKm,
    required this.remainingKm,
    required this.explanation,
    required this.recommendedAction,
  });
}

@immutable
class AiRiderInsight {
  final String id;
  final InsightCategory category;
  final String title;
  final String message;
  final bool isActionable;
  final DateTime timestamp;

  const AiRiderInsight({
    required this.id,
    required this.category,
    required this.title,
    required this.message,
    this.isActionable = false,
    required this.timestamp,
  });
}
