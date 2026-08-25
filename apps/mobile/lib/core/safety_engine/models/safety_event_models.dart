import 'package:flutter/foundation.dart';

enum SafetyEventType {
  crashSuspected,
  hardImpact,
  abnormalStop,
  suddenDeceleration,
  longStop,
  vehicleDisconnected,
  vehicleMovementDetected,
  temperatureWarning,
  batteryWarning,
  lowFuel,
  lowBattery,
  ridingAnomaly,
  manualSos,
}

enum SafetyEventConfidence {
  low,
  medium,
  high,
}

enum SafetySeverity {
  info,
  caution,
  warning,
  critical,
}

enum SafetyEventResolution {
  pending,
  riderConfirmedSafe,
  emergencyConfirmed,
  autoExpired,
  falsePositive,
}

@immutable
class SafetyEvent {
  final String eventId;
  final SafetyEventType eventType;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final String? vehicleId;
  final String? rideSessionId;
  final SafetyEventConfidence confidence;
  final SafetySeverity severity;
  final String source; // Phone Sensors, Vehicle Telemetry, Manual Trigger
  final SafetyEventResolution resolution;
  final bool isSimulated;
  final String description;

  const SafetyEvent({
    required this.eventId,
    required this.eventType,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.vehicleId,
    this.rideSessionId,
    required this.confidence,
    required this.severity,
    required this.source,
    this.resolution = SafetyEventResolution.pending,
    this.isSimulated = false,
    required this.description,
  });

  SafetyEvent copyWithResolution(SafetyEventResolution newResolution) {
    return SafetyEvent(
      eventId: eventId,
      eventType: eventType,
      timestamp: timestamp,
      latitude: latitude,
      longitude: longitude,
      vehicleId: vehicleId,
      rideSessionId: rideSessionId,
      confidence: confidence,
      severity: severity,
      source: source,
      resolution: newResolution,
      isSimulated: isSimulated,
      description: description,
    );
  }
}

@immutable
class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final String relationship;
  final bool isEnabled;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
    this.isEnabled = true,
  });

  EmergencyContact copyWith({
    String? name,
    String? phoneNumber,
    String? relationship,
    bool? isEnabled,
  }) {
    return EmergencyContact(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      relationship: relationship ?? this.relationship,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

@immutable
class LiveLocationShareSession {
  final String sessionId;
  final DateTime startedAt;
  final DateTime expiresAt;
  final bool isActive;
  final DateTime lastUpdated;
  final double? latitude;
  final double? longitude;

  const LiveLocationShareSession({
    required this.sessionId,
    required this.startedAt,
    required this.expiresAt,
    required this.isActive,
    required this.lastUpdated,
    this.latitude,
    this.longitude,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get age => DateTime.now().difference(lastUpdated);
}

@immutable
class RiderSafetyScore {
  final int overallScore; // 0 - 100
  final Map<String, int> subScores; // Harsh Braking, Smooth Accel, Speed Adherence, Thermal Health
  final List<String> positiveFactors;
  final List<String> improvementAreas;
  final DateTime evaluatedAt;

  const RiderSafetyScore({
    required this.overallScore,
    required this.subScores,
    required this.positiveFactors,
    required this.improvementAreas,
    required this.evaluatedAt,
  });
}
