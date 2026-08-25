import 'package:flutter/foundation.dart';
import '../../telemetry_engine/models/telemetry_metric_entry.dart';
import '../../telemetry_engine/services/ride_session_manager.dart';
import '../../vehicle_resolution/models/vehicle_profile.dart';

enum RideAssistantIntent {
  navigation,
  vehicleStatus,
  vehicleConnection,
  rideControl,
  safety,
  weather,
  maintenance,
  analytics,
  garage,
  expenses,
  squad,
  settings,
  generalQuery,
  unknown;

  String get label {
    switch (this) {
      case RideAssistantIntent.navigation:
        return 'Navigation';
      case RideAssistantIntent.vehicleStatus:
        return 'Vehicle Status';
      case RideAssistantIntent.vehicleConnection:
        return 'Vehicle Connection';
      case RideAssistantIntent.rideControl:
        return 'Ride Control';
      case RideAssistantIntent.safety:
        return 'Safety Alert';
      case RideAssistantIntent.weather:
        return 'Weather Forecast';
      case RideAssistantIntent.maintenance:
        return 'Maintenance';
      case RideAssistantIntent.analytics:
        return 'Riding Analytics';
      case RideAssistantIntent.garage:
        return 'Digital Garage';
      case RideAssistantIntent.expenses:
        return 'Expense Logging';
      case RideAssistantIntent.squad:
        return 'Squad Ride';
      case RideAssistantIntent.settings:
        return 'System Settings';
      case RideAssistantIntent.generalQuery:
        return 'General Assistance';
      case RideAssistantIntent.unknown:
        return 'Clarification Required';
    }
  }
}

enum ActionRiskLevel {
  readOnly,
  userConfirmation,
  safetyCritical,
}

enum RoutePreferenceOption {
  fastest,
  shortest,
  safest,
  lowerTraffic,
  weatherAware,
  fuelEfficiency,
  balanced,
}

@immutable
class AssistantActionExecution {
  final String actionType;
  final ActionRiskLevel riskLevel;
  final String title;
  final String description;
  final Map<String, dynamic> payload;
  final bool isBlockedForSafety;

  const AssistantActionExecution({
    required this.actionType,
    required this.riskLevel,
    required this.title,
    required this.description,
    this.payload = const {},
    this.isBlockedForSafety = false,
  });
}

@immutable
class PredictiveRideInsight {
  final String insightId;
  final String title;
  final String category; // Efficiency, Maintenance, RidingBehavior, Safety
  final String predictionText;
  final double confidenceScore; // 0.0 to 1.0
  final bool isAiPrediction;
  final DateTime generatedAt;

  const PredictiveRideInsight({
    required this.insightId,
    required this.title,
    required this.category,
    required this.predictionText,
    required this.confidenceScore,
    this.isAiPrediction = true,
    required this.generatedAt,
  });
}

@immutable
class PersonalizedRideBriefing {
  final String vehicleName;
  final bool isVehicleConnected;
  final String fuelOrBatteryStatus;
  final String routeReadiness;
  final String weatherStatus;
  final String vehicleHealthStatus;
  final String upcomingMaintenance;
  final String aiRecommendation;
  final bool hasCaution;
  final List<PredictiveRideInsight> insights;

  const PersonalizedRideBriefing({
    required this.vehicleName,
    required this.isVehicleConnected,
    required this.fuelOrBatteryStatus,
    required this.routeReadiness,
    required this.weatherStatus,
    required this.vehicleHealthStatus,
    required this.upcomingMaintenance,
    required this.aiRecommendation,
    this.hasCaution = false,
    this.insights = const [],
  });
}

@immutable
class RideContextSnapshot {
  final VehicleProfile? activeVehicle;
  final bool isVehicleConnected;
  final LiveVehicleCockpitSnapshot telemetry;
  final RideSessionState sessionState;
  final bool isOffline;
  final String? currentRouteDestination;
  final double? currentLatitude;
  final double? currentLongitude;

  const RideContextSnapshot({
    this.activeVehicle,
    required this.isVehicleConnected,
    required this.telemetry,
    required this.sessionState,
    this.isOffline = false,
    this.currentRouteDestination,
    this.currentLatitude,
    this.currentLongitude,
  });
}

@immutable
class AssistantResponse {
  final String responseId;
  final String spokenText;
  final String displayText;
  final RideAssistantIntent intent;
  final double confidence;
  final List<AssistantActionExecution> suggestedActions;
  final List<PredictiveRideInsight> predictions;
  final bool isOfflineAi;
  final bool requiresClarification;

  const AssistantResponse({
    required this.responseId,
    required this.spokenText,
    required this.displayText,
    required this.intent,
    required this.confidence,
    this.suggestedActions = const [],
    this.predictions = const [],
    this.isOfflineAi = false,
    this.requiresClarification = false,
  });
}
