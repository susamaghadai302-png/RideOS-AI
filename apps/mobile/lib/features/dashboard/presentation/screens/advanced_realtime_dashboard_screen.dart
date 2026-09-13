import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../domain/models/advanced_dashboard_models.dart';
import '../../core/services/realtime_dashboard_telemetry_engine.dart';
import '../../../../core/graphics/global_3d_state_bridge.dart';
import '../../../../core/widgets/cinematic_background.dart';

class AdvancedRealtimeDashboardScreen extends StatefulWidget {
  const AdvancedRealtimeDashboardScreen({super.key});

  @override
  State<AdvancedRealtimeDashboardScreen> createState() => _AdvancedRealtimeDashboardScreenState();
}

class _AdvancedRealtimeDashboardScreenState extends State<AdvancedRealtimeDashboardScreen> {
  final _engine = RealtimeDashboardTelemetryEngine();
  String _aiOutput = '';
  final TextEditingController _queryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Global3DStateBridge().setCameraPreset('dashboard');
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  void _sendQuery(String prompt) {
    if (prompt.trim().isEmpty) return;
    final res = _engine.processDashboardAiQuery(prompt.trim());
    setState(() {
      _aiOutput = res;
      _queryController.clear();
    });
  }

  Color _connColor(TelemetryConnectionStatus status) {
    switch (status) {
      case TelemetryConnectionStatus.connected:
        return RoadOSColors.apexEmerald;
      case TelemetryConnectionStatus.connecting:
        return const Color(0xFFFFAB00);
      case TelemetryConnectionStatus.error:
        return RoadOSColors.errorCrimson;
      default:
        return RoadOSColors.errorCrimson;
    }
  }

  IconData _connIcon(TelemetryConnectionStatus status) {
    switch (status) {
      case TelemetryConnectionStatus.connected:
        return Icons.bluetooth_connected;
      case TelemetryConnectionStatus.connecting:
        return Icons.bluetooth_searching;
      default:
        return Icons.bluetooth_disabled;
    }
  }

  @override
  Widget build(BuildContext context) {
    final conn = _engine.getConnectionStatus();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'REAL-TIME RIDING DASHBOARD',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _connColor(conn).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: _connColor(conn).withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(_connIcon(conn), color: _connColor(conn), size: 14),
                const SizedBox(width: 4),
                Text(conn.label, style: TextStyle(color: _connColor(conn), fontSize: 8, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
      body: StreamBuilder<LiveRideMetrics>(
        stream: _engine.metricsStream,
        initialData: _engine.getLiveMetrics(),
        builder: (context, snapshot) {
          final metrics = snapshot.data!;
          final state = _engine.rideState;
          final charts = _engine.getHistoricalChartPoints();

          return CinematicBackground(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final content = Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Digital Speedometer & RPM Display
                    RoadOSCard(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      child: Column(
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text('YAMAHA YZF-R1M | ${state.label}', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                              Text('${metrics.distanceKm.toStringAsFixed(1)} KM | ${metrics.durationSeconds}s', style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                metrics.speedKmh != null ? '${metrics.speedKmh!.round()}' : '--',
                                style: const TextStyle(color: Colors.white, fontSize: 64, fontWeight: FontWeight.w900, letterSpacing: -2),
                              ),
                              const SizedBox(width: 8),
                              const Text('KM/H', style: TextStyle(color: RoadOSColors.hyperOrange, fontSize: 14, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // RPM Bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('ENGINE: ${metrics.rpm ?? 0} RPM', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
                                  const Text('REDLINE: 14,500 RPM', style: TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (metrics.rpm ?? 0) / 14500.0,
                                  backgroundColor: RoadOSColors.cardSurface,
                                  valueColor: const AlwaysStoppedAnimation<Color>(RoadOSColors.cyberCyan),
                                  minHeight: 6,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. Telemetry Grid Cards
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        SizedBox(width: 150, child: _buildTelemetryCard('GEAR', metrics.gear != null ? '${metrics.gear}' : 'N', RoadOSColors.hyperOrange)),
                        SizedBox(width: 150, child: _buildTelemetryCard('COOLANT', metrics.coolantTempC != null ? '${metrics.coolantTempC!.round()} degC' : '--', RoadOSColors.hyperOrange)),
                        SizedBox(width: 150, child: _buildTelemetryCard('BATTERY', metrics.batteryVoltage != null ? '${metrics.batteryVoltage!.toStringAsFixed(1)}V' : '--', RoadOSColors.apexEmerald)),
                        SizedBox(width: 150, child: _buildTelemetryCard('LEAN', metrics.leanAngleDeg != null ? '${metrics.leanAngleDeg!.round()} deg' : '--', RoadOSColors.cyberCyan)),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 3. Ride Controls
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF070B18),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF1A2035)),
                      ),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: [
                          if (state == RideState.ready || state == RideState.idle)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: RoadOSColors.apexEmerald, foregroundColor: Colors.black),
                              icon: const Icon(Icons.play_arrow_rounded, size: 18),
                              label: const Text('START RIDE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              onPressed: () => setState(() => _engine.startRide()),
                            ),
                          if (state == RideState.riding) ...[
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: RoadOSColors.hyperOrange, foregroundColor: Colors.black),
                              icon: const Icon(Icons.pause_rounded, size: 18),
                              label: const Text('PAUSE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              onPressed: () => setState(() => _engine.pauseRide()),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                              icon: const Icon(Icons.stop_rounded, size: 18),
                              label: const Text('END RIDE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              onPressed: () => setState(() => _engine.endRide()),
                            ),
                          ],
                          if (state == RideState.paused) ...[
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: RoadOSColors.apexEmerald, foregroundColor: Colors.black),
                              icon: const Icon(Icons.play_arrow_rounded, size: 18),
                              label: const Text('RESUME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              onPressed: () => setState(() => _engine.resumeRide()),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                              icon: const Icon(Icons.stop_rounded, size: 18),
                              label: const Text('END RIDE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              onPressed: () => setState(() => _engine.endRide()),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 4. Historical Telemetry Chart Summary
                    const Text('HISTORICAL TELEMETRY PROFILE', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF080C1A),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF1A2035)),
                      ),
                      child: Column(
                        children: charts.map((c) => _buildChartRow(c)).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 5. Dashboard AI Assistant
                    const Text('DASHBOARD AI ASSISTANT', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                    const SizedBox(height: 8),

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPromptChip('What is my current engine speed?'),
                          _buildPromptChip('How is my tire pressure?'),
                          _buildPromptChip('Summarize my ride statistics.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    if (_aiOutput.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF070B18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.smart_toy_rounded, color: RoadOSColors.cyberCyan, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(_aiOutput, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3)),
                            ),
                          ],
                        ),
                      ),

                    // Query Input
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _queryController,
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Ask about live drivetrain, temperature, ride state...',
                              hintStyle: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11),
                              filled: true,
                              fillColor: const Color(0xFF080C1A),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: RoadOSColors.borderTranslucent),
                              ),
                            ),
                            onSubmitted: _sendQuery,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          style: IconButton.styleFrom(
                            backgroundColor: RoadOSColors.electricBlue,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.send_rounded, size: 18),
                          onPressed: () => _sendQuery(_queryController.text),
                        ),
                      ],
                    ),
                  ],
                );
                
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [content],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTelemetryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF070B18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildChartRow(HistoricalChartPoint c) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        runSpacing: 4,
        children: [
          Text(c.speedKmh != null ? '${c.speedKmh!.round()} km/h' : '— km/h', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          Text(c.rpm != null ? '${c.rpm} RPM' : '— RPM', style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10)),
          Text(c.coolantTempC != null ? '${c.coolantTempC!.round()} degC' : '— degC', style: const TextStyle(color: RoadOSColors.hyperOrange, fontSize: 10)),
          Text(c.batteryVoltage != null ? '${c.batteryVoltage}V' : '— V', style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String prompt) {
    return GestureDetector(
      onTap: () => _sendQuery(prompt),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF080C1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1A2035)),
        ),
        child: Text(prompt, style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
