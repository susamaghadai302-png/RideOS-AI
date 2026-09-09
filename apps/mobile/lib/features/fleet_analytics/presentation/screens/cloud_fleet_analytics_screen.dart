import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/cloud_sync/models/sync_state_models.dart';
import '../../../../core/cloud_sync/services/cloud_sync_manager.dart';
import '../../domain/models/fleet_analytics_models.dart';
import '../../services/fleet_analytics_engine.dart';
import '../../../../core/widgets/cinematic_background.dart';

class CloudFleetAnalyticsScreen extends StatefulWidget {
  const CloudFleetAnalyticsScreen({super.key});

  @override
  State<CloudFleetAnalyticsScreen> createState() => _CloudFleetAnalyticsScreenState();
}

class _CloudFleetAnalyticsScreenState extends State<CloudFleetAnalyticsScreen> {
  final _syncManager = CloudSyncManager();
  final _analyticsEngine = FleetAnalyticsEngine();

  @override
  Widget build(BuildContext context) {
    final summary = _analyticsEngine.getSummary();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF060912),
        title: const Text(
          'CLOUD SYNC & FLEET ANALYTICS',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
        ),
      ),
      body: CinematicBackground(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Cloud Sync Status Card
          StreamBuilder<SyncStatusState>(
            stream: _syncManager.stateStream,
            initialData: _syncManager.state,
            builder: (context, snapshot) {
              final syncState = snapshot.data ?? SyncStatusState.synced;
              final isSynced = syncState == SyncStatusState.synced;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSynced ? RoadOSColors.apexEmerald.withValues(alpha: 0.12) : RoadOSColors.cardSurface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isSynced ? RoadOSColors.apexEmerald : RoadOSColors.borderTranslucent),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isSynced ? Icons.cloud_done_rounded : Icons.cloud_sync_rounded,
                          color: isSynced ? RoadOSColors.apexEmerald : RoadOSColors.electricBlue,
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(syncState.label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            Text('${_syncManager.offlineQueue.length} records in local queue', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RoadOSColors.electricBlue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(80, 32),
                      ),
                      onPressed: () => _syncManager.synchronizeAll(),
                      child: const Text('SYNC', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // 2. Fleet Overview Metrics
          const Text('FLEET LIFETIME OVERVIEW', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(child: _buildMetricCard('TOTAL DISTANCE', summary.totalDistanceKm.toStringAsFixed(1), 'KM', RoadOSColors.electricBlue)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard('TOTAL RIDES', '${summary.totalRides}', 'RIDES', RoadOSColors.cyberCyan)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMetricCard('PEAK SPEED', summary.topMaxSpeedKmh.toStringAsFixed(0), 'KM/H', RoadOSColors.hyperOrange)),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricCard('MAX LEAN', summary.peakLeanAngleDeg.toStringAsFixed(1), ' deg', RoadOSColors.warningAmber)),
            ],
          ),
          const SizedBox(height: 18),

          // 3. Health & Anomaly Indicators
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF080C1A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF1A2035)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('VEHICLE HEALTH & ANOMALY INDEX', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                _buildHealthBar('Battery Charging Health', summary.batteryHealthScorePct, RoadOSColors.apexEmerald),
                const SizedBox(height: 8),
                _buildHealthBar('Coolant Thermal Stability', summary.coolantStabilityPct, RoadOSColors.cyberCyan),
                const SizedBox(height: 8),
                _buildHealthBar('Fleet Safety Score', summary.fleetSafetyScore.toDouble(), RoadOSColors.electricBlue),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // 4. Recent Ride History
          const Text('RECENT RIDE SESSIONS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          ...summary.recentRides.map((r) => _buildRideHistoryTile(r)),

          const SizedBox(height: 18),

          // 5. Maintenance History
          const Text('MAINTENANCE & SERVICE LOG', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 10),
          ...summary.maintenanceRecords.map((m) => _buildMaintenanceTile(m)),
        ],
      )),
    );
  }

  Widget _buildMetricCard(String label, String value, String unit, Color accent) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(color: accent, fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthBar(String label, double percentage, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11)),
            Text('${percentage.toStringAsFixed(1)}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage / 100.0,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildRideHistoryTile(HistoricalRideEntry ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF070B18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${ride.distanceKm.toStringAsFixed(1)} km | ${ride.durationMinutes.toStringAsFixed(0)} mins', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('Top: ${ride.maxSpeedKmh.toStringAsFixed(0)} km/h | Lean: ${ride.maxLeanAngleDeg.toStringAsFixed(1)} deg', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
            ],
          ),
          const Icon(Icons.cloud_done_rounded, color: RoadOSColors.apexEmerald, size: 16),
        ],
      ),
    );
  }

  Widget _buildMaintenanceTile(MaintenanceServiceRecord record) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF070B18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(record.taskType, style: const TextStyle(color: RoadOSColors.electricBlue, fontSize: 11, fontWeight: FontWeight.bold)),
              Text('\$${record.cost.toStringAsFixed(0)}', style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 2),
          Text('${record.performedAtKm} km | Next due at ${record.nextDueKm} km', style: const TextStyle(color: Colors.white70, fontSize: 11)),
          if (record.notes.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(record.notes, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
          ],
        ],
      ),
    );
  }
}
