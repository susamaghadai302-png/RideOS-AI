import 'package:flutter/foundation.dart';

enum HealthSubsystem {
  engine,
  battery,
  thermal,
  dynamics,
  general,
}

@immutable
class SubsystemHealth {
  final HealthSubsystem subsystem;
  final double score; // 0.0 to 100.0

  const SubsystemHealth({
    required this.subsystem,
    required this.score,
  });

  SubsystemHealth copyWith({
    HealthSubsystem? subsystem,
    double? score,
  }) {
    return SubsystemHealth(
      subsystem: subsystem ?? this.subsystem,
      score: score ?? this.score,
    );
  }

  bool get isCritical => score < 40.0;
  bool get isWarning => score >= 40.0 && score < 75.0;
  bool get isNominal => score >= 75.0;
}

@immutable
class PredictiveHealthScore {
  final double overallScore; // 0.0 to 100.0
  final Map<HealthSubsystem, SubsystemHealth> subsystems;
  final DateTime timestamp;

  const PredictiveHealthScore({
    required this.overallScore,
    required this.subsystems,
    required this.timestamp,
  });

  factory PredictiveHealthScore.initial() {
    return PredictiveHealthScore(
      overallScore: 100.0,
      subsystems: {
        for (var sub in HealthSubsystem.values)
          sub: SubsystemHealth(subsystem: sub, score: 100.0)
      },
      timestamp: DateTime.now(),
    );
  }

  PredictiveHealthScore copyWith({
    double? overallScore,
    Map<HealthSubsystem, SubsystemHealth>? subsystems,
    DateTime? timestamp,
  }) {
    return PredictiveHealthScore(
      overallScore: overallScore ?? this.overallScore,
      subsystems: subsystems ?? this.subsystems,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
