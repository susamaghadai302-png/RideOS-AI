enum GpsHealthState {
  available,
  lowAccuracy,
  stale,
  unavailable,
  permissionDenied,
}

class GpsHealthReport {
  final GpsHealthState state;
  final double? accuracyMeters;
  final DateTime? lastFixTime;
  final bool hasPermission;
  final bool isServiceEnabled;
  final String statusDescription;

  const GpsHealthReport({
    required this.state,
    this.accuracyMeters,
    this.lastFixTime,
    required this.hasPermission,
    required this.isServiceEnabled,
    required this.statusDescription,
  });
}

class GpsHealthMonitor {
  static final GpsHealthMonitor _instance = GpsHealthMonitor._internal();
  factory GpsHealthMonitor() => _instance;
  GpsHealthMonitor._internal();

  /// Evaluates GNSS health from live fix parameters
  GpsHealthReport evaluate({
    required bool hasPermission,
    required bool isServiceEnabled,
    required double? accuracyMeters,
    required DateTime? lastFixTime,
  }) {
    if (!hasPermission) {
      return const GpsHealthReport(
        state: GpsHealthState.permissionDenied,
        hasPermission: false,
        isServiceEnabled: false,
        statusDescription: 'Location permission denied. GPS disabled.',
      );
    }

    if (!isServiceEnabled || lastFixTime == null) {
      return const GpsHealthReport(
        state: GpsHealthState.unavailable,
        hasPermission: true,
        isServiceEnabled: false,
        statusDescription: 'Location service is disabled or searching for satellites.',
      );
    }

    final age = DateTime.now().difference(lastFixTime);
    if (age > const Duration(seconds: 5)) {
      return GpsHealthReport(
        state: GpsHealthState.stale,
        accuracyMeters: accuracyMeters,
        lastFixTime: lastFixTime,
        hasPermission: true,
        isServiceEnabled: isServiceEnabled,
        statusDescription: 'GPS fix stale (>5s since last coordinate update).',
      );
    }

    if (accuracyMeters != null && accuracyMeters > 30.0) {
      return GpsHealthReport(
        state: GpsHealthState.lowAccuracy,
        accuracyMeters: accuracyMeters,
        lastFixTime: lastFixTime,
        hasPermission: true,
        isServiceEnabled: isServiceEnabled,
        statusDescription: 'Low GPS precision (+/-${accuracyMeters.toStringAsFixed(0)}m accuracy).',
      );
    }

    return GpsHealthReport(
      state: GpsHealthState.available,
      accuracyMeters: accuracyMeters,
      lastFixTime: lastFixTime,
      hasPermission: true,
      isServiceEnabled: isServiceEnabled,
      statusDescription: 'High-precision GNSS lock (+/-${(accuracyMeters ?? 5.0).toStringAsFixed(1)}m).',
    );
  }
}
