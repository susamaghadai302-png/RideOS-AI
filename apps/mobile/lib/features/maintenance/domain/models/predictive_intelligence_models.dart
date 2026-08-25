import 'package:flutter/foundation.dart';

enum PredictionConfidence {
  high,
  medium,
  low;

  String get label {
    switch (this) {
      case PredictionConfidence.high:
        return 'HIGH';
      case PredictionConfidence.medium:
        return 'MEDIUM';
      case PredictionConfidence.low:
        return 'LOW';
    }
  }
}

enum VehicleHealthRiskTier {
  healthy,
  monitor,
  serviceSoon,
  highRisk,
  critical;

  String get label {
    switch (this) {
      case VehicleHealthRiskTier.healthy:
        return 'HEALTHY';
      case VehicleHealthRiskTier.monitor:
        return 'MONITOR';
      case VehicleHealthRiskTier.serviceSoon:
        return 'SERVICE SOON';
      case VehicleHealthRiskTier.highRisk:
        return 'HIGH RISK';
      case VehicleHealthRiskTier.critical:
        return 'CRITICAL';
    }
  }
}

enum AlertSeverityLevel {
  info,
  normal,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case AlertSeverityLevel.info:
        return 'INFO';
      case AlertSeverityLevel.normal:
        return 'NORMAL';
      case AlertSeverityLevel.medium:
        return 'MEDIUM';
      case AlertSeverityLevel.high:
        return 'HIGH';
      case AlertSeverityLevel.critical:
        return 'CRITICAL';
    }
  }
}

@immutable
class PredictiveMaintenanceItem {
  final String componentName;
  final int currentOdometerKm;
  final int lastServicedAtKm;
  final int nextExpectedServiceKm;
  final int remainingKm;
  final String priority; // 'CRITICAL', 'HIGH', 'MEDIUM', 'NORMAL'
  final PredictionConfidence confidence;
  final String riskAssessment;
  final String recommendedInspection;

  const PredictiveMaintenanceItem({
    required this.componentName,
    required this.currentOdometerKm,
    required this.lastServicedAtKm,
    required this.nextExpectedServiceKm,
    required this.remainingKm,
    required this.priority,
    required this.confidence,
    required this.riskAssessment,
    required this.recommendedInspection,
  });
}

@immutable
class BatteryThermalTrendReport {
  final String batteryStatus;
  final String batteryTrend;
  final String thermalStatus;
  final String thermalTrend;
  final int lowVoltageEventsCount;
  final int highTempEventsCount;
  final String electricalAssessment;
  final String thermalAssessment;

  const BatteryThermalTrendReport({
    required this.batteryStatus,
    required this.batteryTrend,
    required this.thermalStatus,
    required this.thermalTrend,
    required this.lowVoltageEventsCount,
    required this.highTempEventsCount,
    required this.electricalAssessment,
    required this.thermalAssessment,
  });
}

@immutable
class RideIntelligenceScore {
  final int overallScore; // 0 - 100
  final int smoothnessScore;
  final int efficiencyScore;
  final int thermalStabilityScore;
  final int rpmBehaviorScore;
  final int brakingBehaviorScore;
  final int accelerationScore;
  final List<String> improvementSuggestions;

  const RideIntelligenceScore({
    required this.overallScore,
    required this.smoothnessScore,
    required this.efficiencyScore,
    required this.thermalStabilityScore,
    required this.rpmBehaviorScore,
    required this.brakingBehaviorScore,
    required this.accelerationScore,
    required this.improvementSuggestions,
  });
}

@immutable
class SmartAlertItem {
  final String id;
  final AlertSeverityLevel severity;
  final String vehicleName;
  final String title;
  final String message;
  final bool isAcknowledged;
  final DateTime timestamp;

  const SmartAlertItem({
    required this.id,
    required this.severity,
    required this.vehicleName,
    required this.title,
    required this.message,
    this.isAcknowledged = false,
    required this.timestamp,
  });

  SmartAlertItem copyWith({bool? isAcknowledged}) {
    return SmartAlertItem(
      id: id,
      severity: severity,
      vehicleName: vehicleName,
      title: title,
      message: message,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      timestamp: timestamp,
    );
  }
}
