import 'package:flutter/material.dart';
import '../../design_system/roados_tokens.dart';
import '../../vehicle_resolution/models/vehicle_profile.dart';

enum AiState {
  idle('IDLE', 'System in standby', RoadOSColors.textMuted, Icons.pause_circle_outline_rounded),
  ready('AI READY', 'Waiting for vehicle hardware connection', RoadOSColors.cyberCyan, Icons.check_circle_outline_rounded),
  analyzing('ANALYZING', 'Processing telemetry stream & diagnostics', RoadOSColors.neonViolet, Icons.psychology_rounded),
  monitoring('MONITORING', 'Active real-time vehicle protection & telemetry', RoadOSColors.apexEmerald, Icons.sensors_rounded),
  attention('ATTENTION REQUIRED', 'Subsystem or diagnostic notice detected', RoadOSColors.warningAmber, Icons.warning_amber_rounded),
  offline('OFFLINE', 'Hardware disconnected / Standby', RoadOSColors.textMuted, Icons.cloud_off_rounded);

  final String label;
  final String description;
  final Color color;
  final IconData icon;
  const AiState(this.label, this.description, this.color, this.icon);
}

enum InsightSeverity {
  info(RoadOSColors.cyberCyan, Icons.info_outline_rounded, 'INFO'),
  success(RoadOSColors.apexEmerald, Icons.check_circle_outline_rounded, 'OPTIMAL'),
  attention(RoadOSColors.warningAmber, Icons.notifications_active_rounded, 'NOTICE'),
  warning(RoadOSColors.hyperOrange, Icons.warning_amber_rounded, 'WARNING'),
  critical(RoadOSColors.errorCrimson, Icons.error_outline_rounded, 'CRITICAL');

  final Color color;
  final IconData icon;
  final String label;
  const InsightSeverity(this.color, this.icon, this.label);
}

class AiInsight {
  final String id;
  final String title;
  final String explanation;
  final String whyItMatters;
  final InsightSeverity severity;
  final DateTime timestamp;
  final String source;
  final String? recommendedAction;
  final String? actionRoute;

  const AiInsight({
    required this.id,
    required this.title,
    required this.explanation,
    required this.whyItMatters,
    required this.severity,
    required this.timestamp,
    required this.source,
    this.recommendedAction,
    this.actionRoute,
  });
}

class AiRecommendation {
  final String id;
  final String title;
  final String description;
  final InsightSeverity priority;
  final String actionLabel;
  final VoidCallback? onAction;

  const AiRecommendation({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.actionLabel,
    this.onAction,
  });
}

class VehicleIntelligenceSnapshot {
  final VehicleProfile vehicle;
  final AiState aiState;
  final String stateExplanation;
  final bool isConnected;
  final bool isSimulator;
  final List<AiInsight> activeInsights;
  final List<AiRecommendation> recommendations;
  final double rideReadinessPercent;
  final String thermalStatus;
  final String healthGrade;
  final DateTime lastUpdated;

  const VehicleIntelligenceSnapshot({
    required this.vehicle,
    required this.aiState,
    required this.stateExplanation,
    required this.isConnected,
    required this.isSimulator,
    required this.activeInsights,
    required this.recommendations,
    required this.rideReadinessPercent,
    required this.thermalStatus,
    required this.healthGrade,
    required this.lastUpdated,
  });
}
