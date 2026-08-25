import '../domain/models/fleet_analytics_models.dart';

class FleetAnalyticsEngine {
  static final FleetAnalyticsEngine _instance = FleetAnalyticsEngine._internal();
  factory FleetAnalyticsEngine() => _instance;
  FleetAnalyticsEngine._internal();

  FleetAnalyticsSummary getSummary() {
    final now = DateTime.now();

    final rides = [
      HistoricalRideEntry(
        sessionId: 'sess_17868001',
        date: now.subtract(const Duration(hours: 3)),
        distanceKm: 28.4,
        durationMinutes: 35.0,
        maxSpeedKmh: 118.0,
        maxLeanAngleDeg: 41.2,
        maxRpm: 10400,
        isSynced: true,
      ),
      HistoricalRideEntry(
        sessionId: 'sess_17868002',
        date: now.subtract(const Duration(days: 1)),
        distanceKm: 64.2,
        durationMinutes: 78.0,
        maxSpeedKmh: 135.5,
        maxLeanAngleDeg: 44.5,
        maxRpm: 11200,
        isSynced: true,
      ),
      HistoricalRideEntry(
        sessionId: 'sess_17868003',
        date: now.subtract(const Duration(days: 3)),
        distanceKm: 42.0,
        durationMinutes: 52.0,
        maxSpeedKmh: 124.0,
        maxLeanAngleDeg: 39.0,
        maxRpm: 9800,
        isSynced: true,
      ),
    ];

    final maintenance = [
      MaintenanceServiceRecord(
        id: 'maint_01',
        bikeId: 'bike_yamaha_r1m',
        taskType: 'OIL_CHANGE',
        performedAtKm: 4000,
        performedAtDate: now.subtract(const Duration(days: 12)),
        nextDueKm: 8000,
        cost: 65.0,
        notes: 'Motul 300V 10W-40 + OEM Yamaha Filter',
      ),
      MaintenanceServiceRecord(
        id: 'maint_02',
        bikeId: 'bike_yamaha_r1m',
        taskType: 'CHAIN_LUBE',
        performedAtKm: 4600,
        performedAtDate: now.subtract(const Duration(days: 2)),
        nextDueKm: 5100,
        cost: 15.0,
        notes: 'Cleaned and tensioned to 25mm spec',
      ),
    ];

    return FleetAnalyticsSummary(
      totalRides: 42,
      totalDistanceKm: 1248.5,
      totalDurationMinutes: 1860.0,
      averageSpeedKmh: 48.6,
      topMaxSpeedKmh: 142.0,
      topMaxRpm: 11200,
      peakLeanAngleDeg: 44.5,
      batteryHealthScorePct: 98.5,
      coolantStabilityPct: 96.0,
      activeDtcCount: 0,
      fleetSafetyScore: 94,
      recentRides: rides,
      maintenanceRecords: maintenance,
    );
  }
}
