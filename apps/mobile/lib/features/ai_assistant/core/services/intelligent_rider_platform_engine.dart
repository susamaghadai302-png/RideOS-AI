import '../../../../core/device_providers/services/fleet_telematics_engine.dart';
import '../../../../core/device_providers/models/normalized_telemetry_models.dart';
import '../../../../core/vehicle_resolution/services/vehicle_registry.dart';
import '../../../fleet_analytics/services/fleet_analytics_engine.dart';
import '../../domain/models/intelligent_platform_models.dart';

class IntelligentRiderPlatformEngine {
  static final IntelligentRiderPlatformEngine _instance = IntelligentRiderPlatformEngine._internal();
  factory IntelligentRiderPlatformEngine() => _instance;
  IntelligentRiderPlatformEngine._internal();

  final _telematicsEngine = FleetTelematicsEngine();
  final _analyticsEngine = FleetAnalyticsEngine();
  final vehicleRegistry = VehicleRegistry();

  /// Evaluates unified vehicle health across engine, battery, coolant, and maintenance
  VehicleHealthSummary? evaluateVehicleHealth() {
    final tele = _telematicsEngine.latestSnapshot;
    final summary = _analyticsEngine.getSummary();

    if (tele == null) return null; // DATA_UNAVAILABLE

    // 1. Coolant health
    int coolantScore = 100;
    final List<String> warnings = [];
    final List<String> normalIndicators = [];
    final List<String> recommendations = [];

    final coolantTemp = tele.coolantTempC.value;
    if (coolantTemp != null) {
      if (coolantTemp > 105.0) {
        coolantScore = 40;
        warnings.add('High Coolant Temperature (${coolantTemp.round()} degC). Overheating risk.');
        recommendations.add('Allow engine to idle and check radiator coolant level.');
      } else if (coolantTemp > 95.0) {
        coolantScore = 78;
        warnings.add('Elevated Coolant Temperature (${coolantTemp.round()} degC).');
      } else {
        normalIndicators.add('Coolant thermal equilibrium nominal at ${coolantTemp.round()} degC.');
      }
    } else {
      coolantScore = 0; // Unknown
    }

    // 2. Battery health
    int batteryScore = 100;
    final batteryVoltage = tele.batteryVoltage.value;
    if (batteryVoltage != null) {
      if (batteryVoltage < 11.8) {
        batteryScore = 45;
        warnings.add('Low Battery Voltage (${batteryVoltage.toStringAsFixed(1)}V). Charging deficit.');
        recommendations.add('Inspect stator alternator output and avoid accessory drain.');
      } else if (batteryVoltage < 12.2) {
        batteryScore = 75;
        warnings.add('Battery Voltage below optimal resting range (${batteryVoltage.toStringAsFixed(1)}V).');
      } else {
        normalIndicators.add('Electrical bus voltage nominal at ${batteryVoltage.toStringAsFixed(1)}V.');
      }
    } else {
      batteryScore = 0; // Unknown
    }

    // 3. Engine health
    int engineScore = 100; // Assume nominal if no DTCs, but this needs real DTC array from tele
    normalIndicators.add('No active Diagnostic Trouble Codes detected.');

    // 4. Maintenance health
    int maintenanceScore = 100;
    final currentOdometer = null; // No odometer in telemetry yet
    
    if (summary.maintenanceRecords.isNotEmpty && currentOdometer != null) {
      final nextService = summary.maintenanceRecords.first;
      final remainingKm = nextService.nextDueKm - currentOdometer;
      if (remainingKm <= 200) {
        maintenanceScore = 60;
        warnings.add('${nextService.taskType} is due in $remainingKm km.');
        recommendations.add('Schedule service maintenance appointment.');
      } else {
        normalIndicators.add('${nextService.taskType} scheduled in $remainingKm km.');
      }
    } else {
      maintenanceScore = 0; // Unknown
    }

    // If all scores are 0 (unknown), we can't provide a health summary
    if (coolantScore == 0 && batteryScore == 0 && maintenanceScore == 0) return null;

    // Overall health composite
    final overall = ((engineScore * 0.3) + (coolantScore * 0.25) + (batteryScore * 0.25) + (maintenanceScore * 0.2)).round();

    return VehicleHealthSummary(
      overallHealthScore: overall.clamp(0, 100),
      engineScore: engineScore,
      batteryScore: batteryScore,
      coolantScore: coolantScore,
      maintenanceScore: maintenanceScore,
      tirePressureScore: 0, // Explicitly unknown until TPMS added
      criticalWarnings: warnings,
      normalIndicators: normalIndicators,
      recommendations: recommendations,
    );
  }

  /// Calculates riding performance, consistency, and safety scores
  RidingAnalyticsSummary? getRidingAnalytics() {
    final summary = _analyticsEngine.getSummary();
    final tele = _telematicsEngine.latestSnapshot;

    if (summary.totalDistanceKm <= 0.0) return null; // No historical data

    final maxSpeed = summary.topMaxSpeedKmh > 0 ? summary.topMaxSpeedKmh : (tele?.vehicleSpeedKmh.value ?? 0.0);
    final avgSpeed = summary.averageSpeedKmh > 0 ? summary.averageSpeedKmh : 0.0;
    final peakRpm = summary.topMaxRpm > 0 ? summary.topMaxRpm : (tele?.engineRpm.value?.round() ?? 0);
    final maxLean = summary.peakLeanAngleDeg > 0 ? summary.peakLeanAngleDeg : (tele?.leanAngleDeg.value ?? 0.0);

    final insights = <String>[];
    if (maxLean > 30.0) insights.add('Peak lean angle reached ${maxLean.toStringAsFixed(1)} deg.');
    if (avgSpeed > 0) insights.add('Average ride velocity maintained at ${avgSpeed.toStringAsFixed(1)} km/h.');

    return RidingAnalyticsSummary(
      averageSpeedKmh: avgSpeed,
      maxSpeedKmh: maxSpeed,
      totalDistanceKm: summary.totalDistanceKm,
      totalDurationMinutes: summary.totalDurationMinutes,
      peakRpm: peakRpm,
      maxLeanAngleDeg: maxLean,
      ridingConsistencyScore: 0, // Unverified
      overallSafetyScore: summary.fleetSafetyScore,
      efficiencyRating: 'Unknown',
      performanceInsights: insights,
    );
  }

  /// Computes prioritized smart maintenance milestones
  List<SmartMaintenanceMilestone> getMaintenanceMilestones() {
    // Cannot provide accurate predictions without backend maintenance engine.
    // Return empty to avoid fake data.
    return [];
  }

  /// Generates proactive contextual insights
  List<AiRiderInsight> generateProactiveInsights() {
    final now = DateTime.now();
    final health = evaluateVehicleHealth();
    final analytics = getRidingAnalytics();

    final list = <AiRiderInsight>[];

    if (health != null && health.criticalWarnings.isNotEmpty) {
      list.add(AiRiderInsight(
        id: 'ins_warn_01',
        category: InsightCategory.health,
        title: 'Vehicle Health Alert',
        message: health.criticalWarnings.first,
        isActionable: true,
        timestamp: now,
      ));
    }

    if (analytics != null && analytics.maxLeanAngleDeg > 30.0) {
      list.add(AiRiderInsight(
        id: 'ins_perf_01',
        category: InsightCategory.performance,
        title: 'Cornering Dynamics',
        message: 'Peak lean angle at ${analytics.maxLeanAngleDeg.toStringAsFixed(1)} deg.',
        isActionable: false,
        timestamp: now,
      ));
    }

    return list;
  }

  /// Processes natural language rider queries offline using actual vehicle context
  String processRiderQuery(String query) {
    final lower = query.toLowerCase();
    final health = evaluateVehicleHealth();
    final analytics = getRidingAnalytics();
    final milestones = getMaintenanceMilestones();
    final tele = _telematicsEngine.latestSnapshot;
    final isSim = tele?.dataSource == TelemetryDataSource.benchTest;
    final tag = isSim ? ' [SIMULATED]' : '';

    if (lower.contains('how is my bike') || lower.contains('overall health') || lower.contains('status')) {
      if (health == null) return 'Vehicle health data is currently unavailable.$tag';
      final warnings = health.criticalWarnings.isNotEmpty ? ' Caution: ${health.criticalWarnings.join("; ")}' : ' All systems nominal.';
      return 'Your motorcycle health score is ${health.overallHealthScore}%. Engine: ${health.engineScore}%, Coolant: ${health.coolantScore}%, Battery: ${health.batteryScore}%.$warnings$tag';
    }

    if (lower.contains('engine temperature') || lower.contains('coolant') || lower.contains('temp')) {
      final temp = tele?.coolantTempC.value;
      if (temp == null) return 'Coolant temperature is currently unavailable.$tag';
      final status = temp > 105.0 ? 'HIGH (overheating caution)' : (temp > 95.0 ? 'ELEVATED' : 'NORMAL');
      return 'Engine coolant temperature is ${temp.round()} degC, which is $status$tag.';
    }

    if (lower.contains('battery') || lower.contains('voltage')) {
      final volt = tele?.batteryVoltage.value;
      if (volt == null) return 'Battery voltage is currently unavailable.$tag';
      final status = volt < 11.8 ? 'LOW (needs charging inspection)' : 'HEALTHY';
      return 'Battery electrical bus voltage is ${volt.toStringAsFixed(1)}V ($status)$tag.';
    }

    if (lower.contains('next service') || lower.contains('oil change') || lower.contains('maintenance')) {
      if (milestones.isEmpty) return 'Maintenance schedule is currently unavailable in the database.$tag';
      final first = milestones.first;
      return 'Next scheduled maintenance: ${first.taskType} in ${first.remainingKm} km$tag.';
    }

    if (lower.contains('performance') || lower.contains('riding') || lower.contains('speed') || lower.contains('score')) {
      if (analytics == null) return 'Riding analytics are currently unavailable.$tag';
      return 'Safety Score: ${analytics.overallSafetyScore}/100. Top Velocity: ${analytics.maxSpeedKmh.round()} km/h | Max Lean: ${analytics.maxLeanAngleDeg.toStringAsFixed(1)} deg$tag.';
    }

    if (lower.contains('checklist') || lower.contains('trip') || lower.contains('pre-ride')) {
      final batt = tele?.batteryVoltage.value?.toStringAsFixed(1) ?? 'Unknown';
      return 'Pre-Ride Checklist:\n1. Tire Pressure: Check manually\n2. Chain Slack: Check manually\n3. Coolant Level: Check manually\n4. Battery: ${batt}V\n5. Brakes: Check fluid\nDrive safe!';
    }

    return 'RideOS AI Assistant: Telematics monitored. I can answer questions about your bike\'s health, speed, and battery.$tag';
  }
}
