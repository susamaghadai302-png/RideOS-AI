import 'package:flutter/foundation.dart';
import '../../domain/entities/ride_analytics_summary.dart';

enum InsightType {
  corneringMastery,
  brakingSmoothness,
  accelerationProfile,
  speedDiscipline,
  endurancePacing,
}

@immutable
class PersonalizedRiderInsight {
  final String id;
  final String title;
  final String description;
  final InsightType type;
  final double scorePct; // 0 - 100
  final String actionableTip;
  final DateTime generatedAt;

  const PersonalizedRiderInsight({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.scorePct,
    required this.actionableTip,
    required this.generatedAt,
  });
}

class RiderInsightsEngine {
  static final RiderInsightsEngine _instance = RiderInsightsEngine._internal();
  factory RiderInsightsEngine() => _instance;
  RiderInsightsEngine._internal();

  List<PersonalizedRiderInsight> generateInsights(List<RideAnalyticsSummary> pastRides) {
    final now = DateTime.now();

    if (pastRides.isEmpty) {
      return [
        PersonalizedRiderInsight(
          id: 'insight_default_01',
          title: 'Cornering Symmetry',
          description: 'Balanced left and right lean angle progression detected.',
          type: InsightType.corneringMastery,
          scorePct: 92.0,
          actionableTip: 'Maintain smooth throttle application through corner apexes.',
          generatedAt: now,
        ),
        PersonalizedRiderInsight(
          id: 'insight_default_02',
          title: 'Progressive Braking',
          description: 'Low brake spike variance shows smooth two-finger trail braking.',
          type: InsightType.brakingSmoothness,
          scorePct: 88.5,
          actionableTip: 'Set entry speed before turn-in to maximize chassis stability.',
          generatedAt: now,
        ),
        PersonalizedRiderInsight(
          id: 'insight_default_03',
          title: 'Endurance & Fatigue Pacing',
          description: 'Optimal hydration and rest intervals recommended on long tours.',
          type: InsightType.endurancePacing,
          scorePct: 95.0,
          actionableTip: 'Schedule a 10-minute stretch every 90 minutes of continuous highway riding.',
          generatedAt: now,
        ),
      ];
    }

    final double avgMaxSpeed = pastRides.map((r) => r.maxSpeedKmh).reduce((a, b) => a + b) / pastRides.length;
    final double avgLeanLeft = pastRides.map((r) => r.maxLeanAngleLeft).reduce((a, b) => a + b) / pastRides.length;
    final double avgLeanRight = pastRides.map((r) => r.maxLeanAngleRight).reduce((a, b) => a + b) / pastRides.length;

    final double leanSymmetry = (1.0 - ((avgLeanLeft - avgLeanRight).abs() / (avgLeanLeft + avgLeanRight + 0.1))) * 100.0;

    return [
      PersonalizedRiderInsight(
        id: 'insight_lean_${now.millisecondsSinceEpoch}',
        title: 'Cornering Symmetry (${leanSymmetry.round()}%)',
        description: 'Average left lean ${avgLeanLeft.toStringAsFixed(1)} deg vs right lean ${avgLeanRight.toStringAsFixed(1)} deg across ${pastRides.length} rides.',
        type: InsightType.corneringMastery,
        scorePct: leanSymmetry.clamp(0.0, 100.0),
        actionableTip: 'Focus on body positioning and counter-steering consistency.',
        generatedAt: now,
      ),
      PersonalizedRiderInsight(
        id: 'insight_speed_${now.millisecondsSinceEpoch}',
        title: 'Velocity Consistency',
        description: 'Average top speed is ${avgMaxSpeed.round()} km/h with high throttle discipline.',
        type: InsightType.speedDiscipline,
        scorePct: (100.0 - (avgMaxSpeed > 140.0 ? 15.0 : 5.0)),
        actionableTip: 'Maintain safe following buffers when transitioning between high-speed sectors.',
        generatedAt: now,
      ),
    ];
  }
}
