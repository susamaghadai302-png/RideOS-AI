enum DiagnosticSeverity {
  info,
  notice,
  warning,
  critical;

  String get label => name.toUpperCase();
}

class DiagnosticItem {
  final String id;
  final String vehicleId;
  final String code;
  final String source; // e.g. 'Vehicle ECU', 'OBD-II Mode 03', 'BMS'
  final DiagnosticSeverity severity;
  final String description;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final int occurrences;
  final bool active;
  final bool resolved;
  final Map<String, dynamic>? rawData;

  const DiagnosticItem({
    required this.id,
    required this.vehicleId,
    required this.code,
    required this.source,
    required this.severity,
    required this.description,
    required this.firstSeen,
    required this.lastSeen,
    this.occurrences = 1,
    this.active = true,
    this.resolved = false,
    this.rawData,
  });

  DiagnosticItem copyWith({
    String? id,
    String? vehicleId,
    String? code,
    String? source,
    DiagnosticSeverity? severity,
    String? description,
    DateTime? firstSeen,
    DateTime? lastSeen,
    int? occurrences,
    bool? active,
    bool? resolved,
    Map<String, dynamic>? rawData,
  }) {
    return DiagnosticItem(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      code: code ?? this.code,
      source: source ?? this.source,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      occurrences: occurrences ?? this.occurrences,
      active: active ?? this.active,
      resolved: resolved ?? this.resolved,
      rawData: rawData ?? this.rawData,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'code': code,
    'source': source,
    'severity': severity.name,
    'description': description,
    'firstSeen': firstSeen.toIso8601String(),
    'lastSeen': lastSeen.toIso8601String(),
    'occurrences': occurrences,
    'active': active,
    'resolved': resolved,
    'rawData': rawData,
  };

  factory DiagnosticItem.fromJson(Map<String, dynamic> json) => DiagnosticItem(
    id: json['id'] as String,
    vehicleId: json['vehicleId'] as String,
    code: json['code'] as String,
    source: json['source'] as String? ?? 'Vehicle ECU',
    severity: DiagnosticSeverity.values.firstWhere(
      (e) => e.name.toLowerCase() == (json['severity'] as String? ?? 'warning').toLowerCase(),
      orElse: () => DiagnosticSeverity.warning,
    ),
    description: json['description'] as String,
    firstSeen: DateTime.parse(json['firstSeen'] as String),
    lastSeen: DateTime.parse(json['lastSeen'] as String),
    occurrences: (json['occurrences'] as num? ?? 1).toInt(),
    active: json['active'] as bool? ?? true,
    resolved: json['resolved'] as bool? ?? false,
    rawData: json['rawData'] as Map<String, dynamic>?,
  );
}
