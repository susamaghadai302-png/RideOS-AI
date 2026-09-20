enum HealthCategory {
  engine('Engine'),
  battery('Battery System'),
  fuel('Fuel System'),
  brakes('Brakes'),
  tyres('Tyres & TPMS'),
  lights('Lighting & Aux'),
  electrical('Electrical Bus'),
  cooling('Cooling System'),
  suspension('Suspension'),
  transmission('Transmission & Gearbox'),
  general('General Diagnostics');

  final String label;
  const HealthCategory(this.label);
}

enum HealthSeverity {
  optimal,
  notice,
  warning,
  critical,
  insufficientData,
  userInspectionRequired;

  bool get isIssue => this == HealthSeverity.warning || this == HealthSeverity.critical;
}

class CategoryHealthState {
  final HealthCategory category;
  final HealthSeverity severity;
  final String statusText;
  final String detail;
  final bool hasLiveTelemetry;
  final DateTime timestamp;

  const CategoryHealthState({
    required this.category,
    required this.severity,
    required this.statusText,
    required this.detail,
    this.hasLiveTelemetry = false,
    required this.timestamp,
  });

  factory CategoryHealthState.insufficientData(HealthCategory category, {String? reason}) {
    return CategoryHealthState(
      category: category,
      severity: HealthSeverity.insufficientData,
      statusText: 'Insufficient Data',
      detail: reason ?? 'Telemetry sensor data unavailable on active bus',
      hasLiveTelemetry: false,
      timestamp: DateTime.now(),
    );
  }

  factory CategoryHealthState.userInspectionRequired(HealthCategory category, {String? reason}) {
    return CategoryHealthState(
      category: category,
      severity: HealthSeverity.userInspectionRequired,
      statusText: 'Manual Inspection Required',
      detail: reason ?? 'Electronic sensor unavailable; check physical wear periodically',
      hasLiveTelemetry: false,
      timestamp: DateTime.now(),
    );
  }
}

class VehicleHealthState {
  final Map<HealthCategory, CategoryHealthState> categories;
  final int activeDtcCount;
  final int activeAlertCount;
  final bool isConnected;
  final DateTime timestamp;

  const VehicleHealthState({
    required this.categories,
    required this.activeDtcCount,
    required this.activeAlertCount,
    required this.isConnected,
    required this.timestamp,
  });

  factory VehicleHealthState.empty() => VehicleHealthState(
    categories: {
      for (final cat in HealthCategory.values)
        cat: CategoryHealthState.insufficientData(cat, reason: 'Vehicle disconnected'),
    },
    activeDtcCount: 0,
    activeAlertCount: 0,
    isConnected: false,
    timestamp: DateTime.now(),
  );

  CategoryHealthState getCategory(HealthCategory category) {
    return categories[category] ?? CategoryHealthState.insufficientData(category);
  }

  int? get overallScore {
    if (!isConnected) return null;
    final penalty = (activeDtcCount * 15) + (activeAlertCount * 5);
    return (100 - penalty).clamp(10, 100);
  }
}

