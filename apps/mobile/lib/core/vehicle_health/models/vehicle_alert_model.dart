enum AlertSeverity {
  critical,
  warning,
  notice,
  info;

  String get label => name.toUpperCase();
}

enum AlertStatus {
  newAlert,
  active,
  acknowledged,
  resolved;

  bool get isUnresolved => this != AlertStatus.resolved;
}

class VehicleAlertModel {
  final String id;
  final String vehicleId;
  final String alertKey;
  final String title;
  final String message;
  final String category;
  final AlertSeverity severity;
  final AlertStatus status;
  final DateTime firstTriggered;
  final DateTime lastTriggered;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;

  const VehicleAlertModel({
    required this.id,
    required this.vehicleId,
    required this.alertKey,
    required this.title,
    required this.message,
    this.category = 'GENERAL',
    this.severity = AlertSeverity.warning,
    this.status = AlertStatus.active,
    required this.firstTriggered,
    required this.lastTriggered,
    this.acknowledgedAt,
    this.resolvedAt,
  });

  VehicleAlertModel copyWith({
    String? id,
    String? vehicleId,
    String? alertKey,
    String? title,
    String? message,
    String? category,
    AlertSeverity? severity,
    AlertStatus? status,
    DateTime? firstTriggered,
    DateTime? lastTriggered,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
  }) {
    return VehicleAlertModel(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      alertKey: alertKey ?? this.alertKey,
      title: title ?? this.title,
      message: message ?? this.message,
      category: category ?? this.category,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      firstTriggered: firstTriggered ?? this.firstTriggered,
      lastTriggered: lastTriggered ?? this.lastTriggered,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'alertKey': alertKey,
    'title': title,
    'message': message,
    'category': category,
    'severity': severity.name,
    'status': status.name,
    'firstTriggered': firstTriggered.toIso8601String(),
    'lastTriggered': lastTriggered.toIso8601String(),
    'acknowledgedAt': acknowledgedAt?.toIso8601String(),
    'resolvedAt': resolvedAt?.toIso8601String(),
  };

  factory VehicleAlertModel.fromJson(Map<String, dynamic> json) => VehicleAlertModel(
    id: json['id'] as String,
    vehicleId: json['vehicleId'] as String,
    alertKey: json['alertKey'] as String,
    title: json['title'] as String,
    message: json['message'] as String,
    category: json['category'] as String? ?? 'GENERAL',
    severity: AlertSeverity.values.firstWhere(
      (e) => e.name.toLowerCase() == (json['severity'] as String? ?? 'warning').toLowerCase(),
      orElse: () => AlertSeverity.warning,
    ),
    status: AlertStatus.values.firstWhere(
      (e) => e.name.toLowerCase() == (json['status'] as String? ?? 'active').toLowerCase(),
      orElse: () => AlertStatus.active,
    ),
    firstTriggered: DateTime.parse(json['firstTriggered'] as String),
    lastTriggered: DateTime.parse(json['lastTriggered'] as String),
    acknowledgedAt: json['acknowledgedAt'] != null ? DateTime.parse(json['acknowledgedAt'] as String) : null,
    resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt'] as String) : null,
  );
}
