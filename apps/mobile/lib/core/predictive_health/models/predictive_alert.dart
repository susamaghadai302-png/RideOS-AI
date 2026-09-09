import 'package:flutter/foundation.dart';
import 'predictive_health_score.dart';

enum AlertSeverity {
  info,
  warning,
  critical,
}

@immutable
class PredictiveAlert {
  final String id;
  final HealthSubsystem subsystem;
  final String title;
  final String description;
  final String recommendedAction;
  final AlertSeverity severity;
  final Duration? estimatedTimeToFailure;
  final DateTime timestamp;

  const PredictiveAlert({
    required this.id,
    required this.subsystem,
    required this.title,
    required this.description,
    required this.recommendedAction,
    required this.severity,
    this.estimatedTimeToFailure,
    required this.timestamp,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PredictiveAlert && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
