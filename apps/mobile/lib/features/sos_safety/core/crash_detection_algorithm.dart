import 'dart:math' as math;

enum CrashDetectionSource {
  phoneSensors,
  motorcycleCcuBle,
  obdDiagnostics,
}

class CrashConfidenceEvaluation {
  final bool isCrashDetected;
  final double confidenceScore; // 0.0 to 1.0
  final String primaryTriggerReason;
  final CrashDetectionSource source;
  final Map<String, dynamic> sensorMetrics;

  const CrashConfidenceEvaluation({
    required this.isCrashDetected,
    required this.confidenceScore,
    required this.primaryTriggerReason,
    this.source = CrashDetectionSource.phoneSensors,
    this.sensorMetrics = const {},
  });
}

class CrashDetectionAlgorithm {
  // Configurable thresholds for multi-signal crash assessment
  final double impactGThreshold;
  final double decelerationKmhPerSecThreshold;
  final double rollOverThresholdDeg;
  final double minPreImpactSpeedKmh;
  final double postImpactInactivitySpeedThresholdKmh;
  final double confidenceTriggerThreshold;

  const CrashDetectionAlgorithm({
    this.impactGThreshold = 4.5,
    this.decelerationKmhPerSecThreshold = 25.0,
    this.rollOverThresholdDeg = 65.0,
    this.minPreImpactSpeedKmh = 15.0,
    this.postImpactInactivitySpeedThresholdKmh = 3.0,
    this.confidenceTriggerThreshold = 0.65,
  });

  /// Evaluates multi-signal telemetry stream to compute a deterministic crash confidence score
  CrashConfidenceEvaluation evaluateCrashConfidence({
    required double accelMagnitudeG,
    required double rollAngleDeg,
    required double currentSpeedKmh,
    required double speedDropKmh,
    required double durationSecSinceSpeedDrop,
    bool isBleEcuConnected = false,
  }) {
    double confidence = 0.0;
    final List<String> reasons = [];

    // 1. High-G Impact Signal (Weight: 0.40)
    if (accelMagnitudeG >= impactGThreshold) {
      final impactWeight = math.min(0.40, (accelMagnitudeG / impactGThreshold) * 0.35);
      confidence += impactWeight;
      reasons.add('High G-force impact (${accelMagnitudeG.toStringAsFixed(1)}G)');
    }

    // 2. Sudden Deceleration Signal (Weight: 0.30)
    if (speedDropKmh >= decelerationKmhPerSecThreshold) {
      final decelWeight = math.min(0.30, (speedDropKmh / decelerationKmhPerSecThreshold) * 0.25);
      confidence += decelWeight;
      reasons.add('Sudden velocity drop (Δ${speedDropKmh.toStringAsFixed(1)} km/h)');
    }

    // 3. Extreme Roll / High Lean Over (Weight: 0.20)
    if (rollAngleDeg.abs() >= rollOverThresholdDeg) {
      confidence += 0.20;
      reasons.add('Extreme roll angle (${rollAngleDeg.abs().toStringAsFixed(1)} deg)');
    }

    // 4. Post-Impact Inactivity Confirmation (Weight: 0.15)
    if (currentSpeedKmh <= postImpactInactivitySpeedThresholdKmh && durationSecSinceSpeedDrop >= 2.0) {
      confidence += 0.15;
      reasons.add('Prolonged post-impact standstill');
    }

    // False-positive reduction: If the rider was never moving at meaningful speed (<10 km/h) and no extreme G-force
    if (currentSpeedKmh < 10.0 && speedDropKmh < 10.0 && accelMagnitudeG < impactGThreshold) {
      confidence *= 0.2; // Severely down-weight static phone handling
    }

    final normalizedConfidence = math.min(1.0, math.max(0.0, confidence));
    final isCrash = normalizedConfidence >= confidenceTriggerThreshold;

    return CrashConfidenceEvaluation(
      isCrashDetected: isCrash,
      confidenceScore: double.parse(normalizedConfidence.toStringAsFixed(2)),
      primaryTriggerReason: reasons.isNotEmpty ? reasons.join(' + ') : 'Normal Riding Dynamics',
      source: isBleEcuConnected ? CrashDetectionSource.motorcycleCcuBle : CrashDetectionSource.phoneSensors,
      sensorMetrics: {
        'accelMagnitudeG': accelMagnitudeG,
        'rollAngleDeg': rollAngleDeg,
        'currentSpeedKmh': currentSpeedKmh,
        'speedDropKmh': speedDropKmh,
        'durationSecSinceSpeedDrop': durationSecSinceSpeedDrop,
      },
    );
  }

  /// Backward compatible helper
  bool detectCrash({
    required double accelMagnitudeG,
    required double rollAngleDeg,
    required double speedKmh,
  }) {
    return evaluateCrashConfidence(
      accelMagnitudeG: accelMagnitudeG,
      rollAngleDeg: rollAngleDeg,
      currentSpeedKmh: speedKmh,
      speedDropKmh: speedKmh < 5 ? 25.0 : 0.0,
      durationSecSinceSpeedDrop: 3.0,
    ).isCrashDetected;
  }
}
