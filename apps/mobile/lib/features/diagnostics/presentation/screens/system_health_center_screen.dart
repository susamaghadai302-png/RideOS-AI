import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/reliability/services/system_health_center_service.dart';
import '../../../../core/reliability/services/observability_logger.dart';
import '../../../../core/widgets/cinematic_background.dart';

class SystemHealthCenterScreen extends StatefulWidget {
  const SystemHealthCenterScreen({super.key});

  @override
  State<SystemHealthCenterScreen> createState() => _SystemHealthCenterScreenState();
}

class _SystemHealthCenterScreenState extends State<SystemHealthCenterScreen> {
  final _healthService = SystemHealthCenterService();
  final _logger = ObservabilityLogger();

  List<SubsystemHealthReport> _reports = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshHealth();
  }

  Future<void> _refreshHealth() async {
    setState(() => _isLoading = true);
    final results = await _healthService.runFullSystemAudit();
    if (mounted) {
      setState(() {
        _reports = results;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.health_and_safety_rounded, color: RoadOSColors.apexEmerald, size: 20),
            SizedBox(width: 8),
            Text(
              'HEALTH CENTER',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: RoadOSColors.textSecondary),
            onPressed: _refreshHealth,
          ),
        ],
      ),
      body: CinematicBackground(child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: RoadOSColors.electricBlue))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildOverviewHeader(),
                const SizedBox(height: 16),
                const Text(
                  'SUBSYSTEM DIAGNOSTICS',
                  style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
                const SizedBox(height: 10),
                ..._reports.map((r) => _buildSubsystemCard(r)),
                const SizedBox(height: 20),
                _buildObservabilityLogsCard(),
              ],
            ),
      ),
    );
  }

  Widget _buildOverviewHeader() {
    final healthyCount = _reports.where((r) => r.status == SubsystemHealthStatus.healthy).length;
    final total = _reports.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SYSTEM INTEGRITY', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5)),
              const SizedBox(height: 4),
              Text(
                '$healthyCount of $total Services Healthy',
                style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: RoadOSColors.apexEmerald.withValues(alpha: 0.4)),
            ),
            child: const Text('OPERATIONAL', style: TextStyle(color: RoadOSColors.apexEmerald, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSubsystemCard(SubsystemHealthReport report) {
    Color color;
    IconData icon;
    String statusText;

    switch (report.status) {
      case SubsystemHealthStatus.healthy:
        color = RoadOSColors.apexEmerald;
        icon = Icons.check_circle_rounded;
        statusText = 'HEALTHY';
        break;
      case SubsystemHealthStatus.degraded:
        color = RoadOSColors.warningAmber;
        icon = Icons.warning_rounded;
        statusText = 'DEGRADED';
        break;
      case SubsystemHealthStatus.unavailable:
        color = Colors.redAccent;
        icon = Icons.cancel_rounded;
        statusText = 'UNAVAILABLE';
        break;
      case SubsystemHealthStatus.notConfigured:
        color = RoadOSColors.textMuted;
        icon = Icons.settings_rounded;
        statusText = 'NOT CONFIGURED';
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.subsystemName, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(report.statusDescription, style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(statusText, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildObservabilityLogsCard() {
    final logs = _logger.recentLogs;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('REDACTED AUDIT LOGS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              Icon(Icons.lock_rounded, color: RoadOSColors.textMuted, size: 14),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            height: 120,
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: logs.isEmpty
                ? const Center(child: Text('No system incidents recorded', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11)))
                : ListView.builder(
                    itemCount: logs.length,
                    itemBuilder: (context, idx) {
                      return Text(
                        logs[logs.length - 1 - idx],
                        style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 9, fontFamily: 'monospace'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
