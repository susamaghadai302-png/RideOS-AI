import 'package:flutter/foundation.dart';

enum AlertSeverity {
  info,
  warning,
  critical,
}

enum AlertSource {
  telemetryEngine,
  ecuCanBus,
  tpmsSensor,
  helmetLink,
  safetySos,
  navigationEngine,
}

@immutable
class AiVehicleAlertEntity {
  final String id;
  final String title;
  final String description;
  final AlertSeverity severity;
  final AlertSource source;
  final DateTime timestamp;
  final bool isAcknowledged;
  final String? recommendedAction;

  const AiVehicleAlertEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.source,
    required this.timestamp,
    this.isAcknowledged = false,
    this.recommendedAction,
  });

  AiVehicleAlertEntity copyWith({
    String? id,
    String? title,
    String? description,
    AlertSeverity? severity,
    AlertSource? source,
    DateTime? timestamp,
    bool? isAcknowledged,
    String? recommendedAction,
  }) {
    return AiVehicleAlertEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      source: source ?? this.source,
      timestamp: timestamp ?? this.timestamp,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      recommendedAction: recommendedAction ?? this.recommendedAction,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity.name,
      'source': source.name,
      'timestamp': timestamp.toIso8601String(),
      'isAcknowledged': isAcknowledged,
      'recommendedAction': recommendedAction,
    };
  }

  factory AiVehicleAlertEntity.fromJson(Map<String, dynamic> json) {
    return AiVehicleAlertEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: AlertSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AlertSeverity.info,
      ),
      source: AlertSource.values.firstWhere(
        (e) => e.name == json['source'],
        orElse: () => AlertSource.telemetryEngine,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isAcknowledged: json['isAcknowledged'] as bool? ?? false,
      recommendedAction: json['recommendedAction'] as String?,
    );
  }
}
