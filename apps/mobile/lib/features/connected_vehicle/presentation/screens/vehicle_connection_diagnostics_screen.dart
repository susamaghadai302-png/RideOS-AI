import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_connectivity/models/vehicle_connection_lifecycle.dart';
import '../../../../core/vehicle_connectivity/services/production_vehicle_connection_manager.dart';

class VehicleConnectionDiagnosticsScreen extends StatefulWidget {
  const VehicleConnectionDiagnosticsScreen({super.key});

  @override
  State<VehicleConnectionDiagnosticsScreen> createState() => _VehicleConnectionDiagnosticsScreenState();
}

class _VehicleConnectionDiagnosticsScreenState extends State<VehicleConnectionDiagnosticsScreen> {
  final _connectionManager = ProductionVehicleConnectionManager();
  bool _isRunningDiagnostic = false;

  Future<void> _runDiagnostics() async {
    setState(() => _isRunningDiagnostic = true);
    await _connectionManager.startConnectionPipeline(
      deviceName: 'Y-Connect_CCU_98A2',
      advertisedServices: ['0000fee0-0000-1000-8000-00805f9b34fb'],
      macAddress: 'AA:BB:CC:DD:EE:FF',
      isSimulated: true,
    );
    if (mounted) {
      setState(() => _isRunningDiagnostic = false);
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
            Icon(Icons.network_check_rounded, color: RoadOSColors.electricBlue, size: 20),
            SizedBox(width: 8),
            Text(
              'CONNECTION DIAGNOSTICS',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: CinematicBackground(child: StreamBuilder<ConnectionDiagnosticsSession>(
        stream: _connectionManager.diagnosticsStream,
        initialData: _connectionManager.currentSession,
        builder: (context, snapshot) {
          final session = snapshot.data ?? const ConnectionDiagnosticsSession(state: ConnectionLifecycleState.idle));

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildLifecycleStatusCard(session),
              const SizedBox(height: 16),
              _buildConnectionMetricsCard(session),
              const SizedBox(height: 16),
              _buildProtocolDetailsCard(session),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: Icon(_isRunningDiagnostic ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded),
                label: Text(_isRunningDiagnostic ? 'RUNNING DIAGNOSTIC PIPELINE...' : 'RUN CONNECTION DIAGNOSTIC', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RoadOSColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isRunningDiagnostic ? null : _runDiagnostics,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLifecycleStatusCard(ConnectionDiagnosticsSession session) {
    Color stateColor;
    switch (session.state) {
      case ConnectionLifecycleState.connected:
      case ConnectionLifecycleState.telemetryActive:
        stateColor = RoadOSColors.apexEmerald;
        break;
      case ConnectionLifecycleState.scanning:
      case ConnectionLifecycleState.connecting:
      case ConnectionLifecycleState.pairing:
      case ConnectionLifecycleState.authenticating:
      case ConnectionLifecycleState.capabilityDiscovery:
        stateColor = RoadOSColors.electricBlue;
        break;
      case ConnectionLifecycleState.idle:
        stateColor = RoadOSColors.textMuted;
        break;
      default:
        stateColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: stateColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('LIFECYCLE STATE', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  session.state.name.toUpperCase(),
                  style: TextStyle(color: stateColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            session.deviceName ?? 'Awaiting device selection',
            style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          if (session.failureReason != null) ...[
            const SizedBox(height: 6),
            Text(session.failureReason!, style: const TextStyle(color: Colors.redAccent, fontSize: 11)),
          ],
        ],
      ),
    );
  }

  Widget _buildConnectionMetricsCard(ConnectionDiagnosticsSession session) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoadOSColors.borderTranslucent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('REAL-TIME LINK METRICS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildMetricRow('Signal Strength (RSSI)', '${session.rssi} dBm', Icons.signal_cellular_alt_rounded),
          _buildMetricRow('Round-Trip Latency', '${session.latencyMs} ms', Icons.timer_rounded),
          _buildMetricRow('Packets Received', '${session.packetsReceived}', Icons.data_usage_rounded),
          _buildMetricRow('Reconnect Attempts', '${session.reconnectAttempts}', Icons.replay_rounded),
        ],
      ),
    );
  }

  Widget _buildProtocolDetailsCard(ConnectionDiagnosticsSession session) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoadOSColors.borderTranslucent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROTOCOL & GATT DESCRIPTOR', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildMetricRow('Detected Protocol', session.protocolName, Icons.security_rounded),
          _buildMetricRow('Target Variant', session.resolvedVariant?.variantName ?? 'Universal Diagnostic Stream', Icons.two_wheeler_rounded),
          _buildMetricRow('Display Mirroring', session.resolvedVariant?.display.supportsNavigationArrows == true ? 'Supported (TFT)' : 'Unsupported', Icons.tv_rounded),
          _buildMetricRow('Sandbox Environment', session.isWebSandbox ? 'Chrome Web (Simulated Bench)' : 'Native Mobile Direct', Icons.devices_rounded),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: RoadOSColors.electricBlue, size: 14),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
