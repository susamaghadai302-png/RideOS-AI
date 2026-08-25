import 'package:flutter/foundation.dart';

enum IncidentTriggerType {
  crashDetected,
  emergencySos,
  hardBraking,
  sentryTamperMotion,
  manualSave,
}

@immutable
class DashcamIncidentEntity {
  final String id;
  final String title;
  final String videoPath;
  final DateTime timestamp;
  final Duration duration;
  final IncidentTriggerType triggerType;
  final bool isLocked;
  final double? maxGForce;
  final double? speedAtTriggerKmh;

  const DashcamIncidentEntity({
    required this.id,
    required this.title,
    required this.videoPath,
    required this.timestamp,
    required this.duration,
    required this.triggerType,
    this.isLocked = true,
    this.maxGForce,
    this.speedAtTriggerKmh,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'videoPath': videoPath,
      'timestamp': timestamp.toIso8601String(),
      'durationSeconds': duration.inSeconds,
      'triggerType': triggerType.name,
      'isLocked': isLocked,
      'maxGForce': maxGForce,
      'speedAtTriggerKmh': speedAtTriggerKmh,
    };
  }
}
