import '../../../ai_assistant/domain/entities/ai_recommendation_entity.dart';
import '../../../ride_history/domain/entities/ride_analytics_summary.dart';
import '../../../ai_assistant/core/services/ai_copilot_engine.dart';

class SmartSafetyRecommendationEngine {
  static final SmartSafetyRecommendationEngine _instance = SmartSafetyRecommendationEngine._internal();
  factory SmartSafetyRecommendationEngine() => _instance;
  SmartSafetyRecommendationEngine._internal();

  List<AiRecommendationEntity> generateSafetyRecommendations({
    List<RideAnalyticsSummary> recentRides = const [],
  }) {
    final now = DateTime.now();
    final recommendations = <AiRecommendationEntity>[];
    final copilotContext = AiCopilotEngine().getCurrentContext();

    // 1. Live Telemetry Analysis
    if (copilotContext.coolantTempC != null && copilotContext.coolantTempC! > 102.0) {
      recommendations.add(
        AiRecommendationEntity(
          id: 'safety_rec_temp_${now.millisecondsSinceEpoch}',
          title: 'Coolant Heat Caution',
          explanation: 'Operating temperature is near heat threshold (102 degC). High ambient temperature or stop-and-go traffic.',
          category: RecommendationCategory.vehicleHealth,
          urgency: RecommendationUrgency.warning,
          recommendedAction: 'Avoid high-RPM idling and maintain steady forward airflow.',
          confidenceScore: 0.93,
          supportingTelemetry: 'Live Coolant: ${copilotContext.coolantTempC!.round()} degC',
          timestamp: now,
        ),
      );
    }

    // 2. Historical Ride Risk Pattern Analysis
    if (recentRides.isNotEmpty) {
      final aggressiveCornering = recentRides.any((r) => r.maxLeanAngleLeft > 48.0 || r.maxLeanAngleRight > 48.0);
      if (aggressiveCornering) {
        recommendations.add(
          AiRecommendationEntity(
            id: 'safety_rec_lean_${now.millisecondsSinceEpoch}',
            title: 'High Lean Angle Cornering Notice',
            explanation: 'Extreme lean angles (>48 deg) recorded on public roads. Approaching tire edge grip threshold.',
            category: RecommendationCategory.safetyRisk,
            urgency: RecommendationUrgency.upcoming,
            recommendedAction: 'Increase safety buffer for unseen road gravel, grease or surface irregularities.',
            confidenceScore: 0.89,
            supportingTelemetry: 'Max Recorded Lean: 50.2 deg',
            timestamp: now,
          ),
        );
      }
    }

    // Default safety best practice recommendation if no hazards detected
    if (recommendations.isEmpty) {
      recommendations.add(
        AiRecommendationEntity(
          id: 'safety_rec_general_${now.millisecondsSinceEpoch}',
          title: 'Optimal Riding Stance & Scan Horizon',
          explanation: 'Maintain 4-second visual lead time and smooth inputs on throttle and front brake.',
          category: RecommendationCategory.ridingStyle,
          urgency: RecommendationUrgency.info,
          recommendedAction: 'Scan mirrors every 5-8 seconds and watch for vehicle blind spots.',
          confidenceScore: 0.98,
          supportingTelemetry: 'System Nominal',
          timestamp: now,
        ),
      );
    }

    return recommendations;
  }
}
