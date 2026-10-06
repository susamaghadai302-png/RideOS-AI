import 'dart:async';
import 'dart:math' as math;

enum SafetyAlertType {
  speeding,
  sharpTurn,
  accidentProneZone,
  fogWarning,
  rainWarning,
  animalCrossing,
  schoolZone,
  potholeAhead,
  dangerousRoad,
  abnormalStop,
  harshBraking,
  harshAcceleration,
}

class SafetyAlertEvent {
  final SafetyAlertType type;
  final String title;
  final String description;
  final String voicePrompt;
  final String severity; // HIGH, MEDIUM, LOW

  const SafetyAlertEvent({
    required this.type,
    required this.title,
    required this.description,
    required this.voicePrompt,
    required this.severity,
  });
}

class AbnormalStopEvaluation {
  final bool isAbnormalStop;
  final String reason;
  final double standstillDurationSec;
  final bool shouldPromptRider;

  const AbnormalStopEvaluation({
    required this.isAbnormalStop,
    required this.reason,
    required this.standstillDurationSec,
    required this.shouldPromptRider,
  });
}

class RideSafetyScoreEvaluation {
  final int overallScore; // 0 to 100
  final int harshBrakingEvents;
  final int harshAccelEvents;
  final int overspeedEvents;
  final int highLeanCorneringEvents;
  final int abnormalStopCount;
  final List<String> deductionsSummary;

  const RideSafetyScoreEvaluation({
    required this.overallScore,
    required this.harshBrakingEvents,
    required this.harshAccelEvents,
    required this.overspeedEvents,
    required this.highLeanCorneringEvents,
    required this.abnormalStopCount,
    required this.deductionsSummary,
  });
}

class RiderSafetyAiEngine {
  static final RiderSafetyAiEngine _instance = RiderSafetyAiEngine._internal();
  factory RiderSafetyAiEngine() => _instance;
  RiderSafetyAiEngine._internal();

  bool voiceAlertsEnabled = true;
  double maxSpeedLimitKmH = 80.0;

  final _alertController = StreamController<SafetyAlertEvent>.broadcast();
  Stream<SafetyAlertEvent> get alertStream => _alertController.stream;

  /// Evaluates whether a stop is abnormal (e.g. sudden drop from highway speed + prolonged standstill away from POIs)
  AbnormalStopEvaluation evaluateAbnormalStop({
    required bool isRideActive,
    required double preStopSpeedKmh,
    required double currentSpeedKmh,
    required double standstillDurationSec,
    bool isNearTrafficLightOrFuel = false,
  }) {
    if (!isRideActive || isNearTrafficLightOrFuel) {
      return AbnormalStopEvaluation(
        isAbnormalStop: false,
        reason: isNearTrafficLightOrFuel ? 'Normal stop at traffic light / POI' : 'Ride inactive',
        standstillDurationSec: standstillDurationSec,
        shouldPromptRider: false,
      );
    }

    // High pre-stop speed (>45 km/h) dropping to 0 km/h with standstill >45 seconds
    if (preStopSpeedKmh >= 45.0 && currentSpeedKmh < 2.0 && standstillDurationSec >= 45.0) {
      return AbnormalStopEvaluation(
        isAbnormalStop: true,
        reason: 'Sudden highway standstill for ${standstillDurationSec.toInt()}s',
        standstillDurationSec: standstillDurationSec,
        shouldPromptRider: standstillDurationSec >= 60.0,
      );
    }

    return AbnormalStopEvaluation(
      isAbnormalStop: false,
      reason: 'Normal stop or within safe grace period',
      standstillDurationSec: standstillDurationSec,
      shouldPromptRider: false,
    );
  }

  /// Calculates a real-time safety score (0-100) based on recorded dynamic telemetry incidents
  RideSafetyScoreEvaluation computeRideSafetyScore({
    required double distanceKm,
    required int harshBrakingCount,
    required int harshAccelCount,
    required int overspeedCount,
    required int highLeanCount,
    required int abnormalStopCount,
  }) {
    int score = 100;
    final deductions = <String>[];

    // Deduct for harsh braking (-4 pts per event)
    if (harshBrakingCount > 0) {
      final deduction = math.min(24, harshBrakingCount * 4);
      score -= deduction;
      deductions.add('-$deduction pts: $harshBrakingCount harsh braking instances');
    }

    // Deduct for harsh acceleration (-3 pts per event)
    if (harshAccelCount > 0) {
      final deduction = math.min(18, harshAccelCount * 3);
      score -= deduction;
      deductions.add('-$deduction pts: $harshAccelCount aggressive throttle spikes');
    }

    // Deduct for overspeeding (-5 pts per event)
    if (overspeedCount > 0) {
      final deduction = math.min(30, overspeedCount * 5);
      score -= deduction;
      deductions.add('-$deduction pts: $overspeedCount speed limit violations');
    }

    // Deduct for excessive lean angle (>48 deg) (-3 pts per event)
    if (highLeanCount > 0) {
      final deduction = math.min(15, highLeanCount * 3);
      score -= deduction;
      deductions.add('-$deduction pts: $highLeanCount extreme lean cornering');
    }

    // Deduct for abnormal stops (-6 pts per event)
    if (abnormalStopCount > 0) {
      final deduction = math.min(18, abnormalStopCount * 6);
      score -= deduction;
      deductions.add('-$deduction pts: $abnormalStopCount unexpected roadside stops');
    }

    final finalScore = math.max(0, math.min(100, score));

    return RideSafetyScoreEvaluation(
      overallScore: finalScore,
      harshBrakingEvents: harshBrakingCount,
      harshAccelEvents: harshAccelCount,
      overspeedEvents: overspeedCount,
      highLeanCorneringEvents: highLeanCount,
      abnormalStopCount: abnormalStopCount,
      deductionsSummary: deductions.isNotEmpty ? deductions : ['+0 deductions: Perfect smooth riding'],
    );
  }

  List<SafetyAlertEvent> getActiveSafetyAlerts({
    required double currentSpeedKmH,
    required double leanAngleDeg,
  }) {
    final alerts = <SafetyAlertEvent>[];

    if (currentSpeedKmH > maxSpeedLimitKmH) {
      alerts.add(
        SafetyAlertEvent(
          type: SafetyAlertType.speeding,
          title: 'SPEED WARNING',
          description: 'Current speed ${currentSpeedKmH.toInt()} km/h exceeds ${maxSpeedLimitKmH.toInt()} km/h limit.',
          voicePrompt: 'Warning: Reduce speed. Speed limit is ${maxSpeedLimitKmH.toInt()} km/h.',
          severity: 'HIGH',
        ),
      );
    }

    if (leanAngleDeg > 35.0) {
      alerts.add(
        SafetyAlertEvent(
          type: SafetyAlertType.sharpTurn,
          title: 'SHARP TURN AHEAD',
          description: 'High lean angle corner ($leanAngleDeg deg). Slow down before entry.',
          voicePrompt: 'Caution: Sharp hairpin turn ahead. Prepare to trail brake.',
          severity: 'HIGH',
        ),
      );
    }



    return alerts;
  }

  void dispose() {
    _alertController.close();
  }
}
