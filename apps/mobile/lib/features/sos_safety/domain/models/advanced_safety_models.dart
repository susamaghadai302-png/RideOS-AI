import 'package:flutter/foundation.dart';

enum SafetyCenterStatus {
  normal,
  warning,
  highRisk,
  emergency;

  String get label {
    switch (this) {
      case SafetyCenterStatus.normal:
        return 'NORMAL';
      case SafetyCenterStatus.warning:
        return 'WARNING';
      case SafetyCenterStatus.highRisk:
        return 'HIGH RISK';
      case SafetyCenterStatus.emergency:
        return 'EMERGENCY';
    }
  }
}

enum SafetyIncidentSeverity {
  info,
  normal,
  medium,
  high,
  critical;

  String get label {
    switch (this) {
      case SafetyIncidentSeverity.info:
        return 'INFO';
      case SafetyIncidentSeverity.normal:
        return 'NORMAL';
      case SafetyIncidentSeverity.medium:
        return 'MEDIUM';
      case SafetyIncidentSeverity.high:
        return 'HIGH';
      case SafetyIncidentSeverity.critical:
        return 'CRITICAL';
    }
  }
}

@immutable
class EmergencyContactItem {
  final String id;
  final String name;
  final String phone;
  final String relationship;
  final bool isPrimary;
  final bool notifyOnIncident;

  const EmergencyContactItem({
    required this.id,
    required this.name,
    required this.phone,
    required this.relationship,
    this.isPrimary = false,
    this.notifyOnIncident = true,
  });

  EmergencyContactItem copyWith({
    String? name,
    String? phone,
    String? relationship,
    bool? isPrimary,
    bool? notifyOnIncident,
  }) {
    return EmergencyContactItem(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      notifyOnIncident: notifyOnIncident ?? this.notifyOnIncident,
    );
  }
}

@immutable
class SafetyEventRecord {
  final String id;
  final String eventType;
  final SafetyIncidentSeverity severity;
  final String vehicleName;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final bool isLocationAvailable;
  final Map<String, dynamic> telemetryMetrics;
  final String resolutionStatus; // 'RESOLVED', 'CANCELLED_BY_RIDER', 'ACTIVE'
  final String description;

  const SafetyEventRecord({
    required this.id,
    required this.eventType,
    required this.severity,
    required this.vehicleName,
    required this.timestamp,
    this.latitude,
    this.longitude,
    required this.isLocationAvailable,
    required this.telemetryMetrics,
    required this.resolutionStatus,
    required this.description,
  });
}

@immutable
class RiderSafetySettings {
  final bool isIncidentDetectionEnabled;
  final int countdownDurationSeconds;
  final bool shareLiveGpsWithContacts;
  final bool sendEmergencySms;
  final bool lowBatteryWarningEnabled;
  final bool highTempWarningEnabled;

  const RiderSafetySettings({
    this.isIncidentDetectionEnabled = true,
    this.countdownDurationSeconds = 20,
    this.shareLiveGpsWithContacts = true,
    this.sendEmergencySms = true,
    this.lowBatteryWarningEnabled = true,
    this.highTempWarningEnabled = true,
  });
}
