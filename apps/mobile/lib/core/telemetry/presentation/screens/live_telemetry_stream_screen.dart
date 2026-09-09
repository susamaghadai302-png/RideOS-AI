import 'package:flutter/material.dart';
import '../../../design_system/roados_tokens.dart';
import '../../models/metric_types.dart';
import '../../models/telemetry_metric.dart';
import '../../models/telemetry_snapshot.dart';
import '../../services/telemetry_pipeline.dart';

/// Phase 19: RoadOS Live Telemetry Stream Viewer.
///
/// Isolated diagnostic monitor for inspecting real-time normalized telemetry,
/// deadband filter performance, multi-ECU provenance, and freshness state transitions.
class LiveTelemetryStreamScreen extends StatefulWidget {
  const LiveTelemetryStreamScreen({super.key});

  @override
  State<LiveTelemetryStreamScreen> createState() => _LiveTelemetryStreamScreenState();
}

class _LiveTelemetryStreamScreenState extends State<LiveTelemetryStreamScreen>
    with SingleTickerProviderStateMixin {
  final TelemetryPipeline _pipeline = TelemetryPipeline.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoadOSColors.deepSpaceBlack,
      appBar: AppBar(
        backgroundColor: RoadOSColors.midnightNavy,
        title: const Text(
          'LIVE TELEMETRY STREAM',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: 1.5,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: RoadOSColors.roadCyan,
          labelColor: RoadOSColors.roadCyan,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0),
          tabs: const [
            Tab(icon: Icon(Icons.speed, size: 18), text: 'DYNAMICS'),
            Tab(icon: Icon(Icons.thermostat, size: 18), text: 'THERMAL'),
            Tab(icon: Icon(Icons.bolt, size: 18), text: 'ELECTRICAL'),
            Tab(icon: Icon(Icons.local_gas_station, size: 18), text: 'FUEL & ENERGY'),
          ],
        ),
      ),
      body: StreamBuilder<NormalizedTelemetrySnapshot>(
        stream: _pipeline.snapshotStream,
        initialData: _pipeline.currentSnapshot,
        builder: (context, snapshot) {
          final data = snapshot.data ?? NormalizedTelemetrySnapshot.initial();

          return Column(
            children: [
              _buildPipelineStatusBar(data),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCategoryGrid(data, TelemetryMetricCategory.dynamics),
                    _buildCategoryGrid(data, TelemetryMetricCategory.thermal),
                    _buildCategoryGrid(data, TelemetryMetricCategory.electrical),
                    _buildCategoryGrid(data, TelemetryMetricCategory.fuelAndEnergy),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPipelineStatusBar(NormalizedTelemetrySnapshot data) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: RoadOSColors.obsidianSurface,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: data.hasLivePowertrainStream ? RoadOSColors.apexEmerald : RoadOSColors.warningAmber,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'PIPELINE: ${data.hasLivePowertrainStream ? 'STREAMING LIVE' : 'AWAITING DATA'}',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            children: [
              Text('${data.liveMetricCount} LIVE',
                  style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 10, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('${data.staleMetricCount} STALE',
                  style: const TextStyle(color: RoadOSColors.warningAmber, fontSize: 10, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryGrid(NormalizedTelemetrySnapshot snapshot, TelemetryMetricCategory category) {
    final metrics = snapshot.metrics.values.where((m) => m.category == category).toList();

    if (metrics.isEmpty) {
      return const Center(
        child: Text('No metrics registered in this category.', style: TextStyle(color: Colors.white38)),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.3,
      ),
      itemCount: metrics.length,
      itemBuilder: (context, idx) {
        final metric = metrics[idx];
        return _buildMetricCard(metric);
      },
    );
  }

  Widget _buildMetricCard(NormalizedTelemetryMetric metric) {
    final freshnessColor = switch (metric.freshness) {
      TelemetryFreshness.fresh => RoadOSColors.apexEmerald,
      TelemetryFreshness.stale => RoadOSColors.warningAmber,
      TelemetryFreshness.unavailable => Colors.white24,
      TelemetryFreshness.invalid => RoadOSColors.errorCrimson,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: metric.isLive ? RoadOSColors.roadCyan.withValues(alpha: 0.3) : Colors.white10,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  metric.metricId.title,
                  style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: freshnessColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  metric.freshness.label,
                  style: TextStyle(color: freshnessColor, fontSize: 8, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          Text(
            metric.formattedDisplay,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ECU: ${metric.sourceEcu.name.split('_').last}',
                style: const TextStyle(color: Colors.white38, fontSize: 9, fontFamily: 'monospace'),
              ),
              Text(
                metric.unit.symbol,
                style: const TextStyle(color: RoadOSColors.roadCyan, fontSize: 10, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
