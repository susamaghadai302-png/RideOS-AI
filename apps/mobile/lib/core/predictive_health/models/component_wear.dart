import 'package:flutter/foundation.dart';
import 'predictive_health_score.dart';

@immutable
class ComponentWear {
  final HealthSubsystem subsystem;
  final double wearAccumulation; // 0.0 (new) to 100.0 (completely degraded)
  final double wearRate; // Rate of accumulation per hour of operation

  const ComponentWear({
    required this.subsystem,
    required this.wearAccumulation,
    required this.wearRate,
  });

  factory ComponentWear.initial(HealthSubsystem subsystem) {
    return ComponentWear(
      subsystem: subsystem,
      wearAccumulation: 0.0,
      wearRate: 0.0,
    );
  }

  ComponentWear copyWith({
    HealthSubsystem? subsystem,
    double? wearAccumulation,
    double? wearRate,
  }) {
    return ComponentWear(
      subsystem: subsystem ?? this.subsystem,
      wearAccumulation: wearAccumulation ?? this.wearAccumulation,
      wearRate: wearRate ?? this.wearRate,
    );
  }
}
