import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../domain/models/advanced_dashboard_models.dart';
import '../../core/services/realtime_dashboard_telemetry_engine.dart';
import '../../../../core/graphics/global_3d_state_bridge.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import '../../../../core/device_providers/models/normalized_telemetry_models.dart';
import '../../domain/models/vehicle_capabilities_extension.dart';

enum DashboardMode {
  driving,
  diagnostic,
  health,
  trip,
}

class AdvancedRealtimeDashboardScreen extends ConsumerStatefulWidget {
  const AdvancedRealtimeDashboardScreen({super.key});

  @override
  ConsumerState<AdvancedRealtimeDashboardScreen> createState() => _AdvancedRealtimeDashboardScreenState();
}

class _AdvancedRealtimeDashboardScreenState extends ConsumerState<AdvancedRealtimeDashboardScreen> {
  final _engine = RealtimeDashboardTelemetryEngine();
  DashboardMode _currentMode = DashboardMode.driving;
  String aiOutput = '';
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

  void sendQuery(String prompt) {
    if (prompt.trim().isEmpty) return;
    final res = _engine.processDashboardAiQuery(prompt.trim());
    setState(() {
      aiOutput = res;
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
      case TelemetryConnectionStatus.disconnected:
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
    final activeContext = ref.watch(activeVehicleContextProvider);
    final profile = activeContext.profile;

    // Capability deduction — use VehicleCategory.fromString() since profile.category is String
    final cat = profile != null ? VehicleCategory.fromString(profile.category) : VehicleCategory.other;
    final bool isEv = cat == VehicleCategory.electricCar || cat == VehicleCategory.electricMotorcycle || cat == VehicleCategory.electricScooter;
    final bool isCar = cat == VehicleCategory.car || cat == VehicleCategory.electricCar;

    final vehicleName = profile != null ? '${profile.manufacturer} ${profile.model}'.toUpperCase() : 'UNKNOWN VEHICLE';

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
        initialData: _engine.getLiveMetrics(vehicleId: profile?.id),
        builder: (context, snapshot) {
          final metrics = snapshot.data!;
          final state = _engine.rideState;

          return CinematicBackground(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: MediaQuery.paddingOf(context).top + kToolbarHeight + 16),

                    // Display Mode Selector
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildModeTab('DRIVING VIEW', DashboardMode.driving),
                          _buildModeTab('DIAGNOSTIC VIEW', DashboardMode.diagnostic),
                          _buildModeTab('HEALTH VIEW', DashboardMode.health),
                          _buildModeTab('TRIP VIEW', DashboardMode.trip),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _buildCurrentMode(metrics, state, vehicleName, isEv, isCar, activeContext.maxRpm),
                      ),
                    ),
                  ],
                );
              }
            ),
          );
        },
      ),
    );
  }

  Widget _buildModeTab(String label, DashboardMode mode) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _currentMode = mode),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? RoadOSColors.cyberCyan.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? RoadOSColors.cyberCyan : Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentMode(LiveRideMetrics metrics, RideState state, String vehicleName, bool isEv, bool isCar, double? maxRpm) {
    switch (_currentMode) {
      case DashboardMode.driving:
        return _buildDrivingView(metrics, state, vehicleName, isEv, isCar, maxRpm);
      case DashboardMode.diagnostic:
        return _buildDiagnosticView();
      case DashboardMode.health:
        return _buildHealthView(metrics);
      case DashboardMode.trip:
        return _buildTripView(metrics);
    }
  }

  Widget _buildDrivingView(LiveRideMetrics metrics, RideState state, String vehicleName, bool isEv, bool isCar, double? maxRpm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                  Text('$vehicleName | ${state.label}', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
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
              if (!isEv || metrics.rpm != null) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('ENGINE: ${metrics.rpm ?? "--"} RPM', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
                        if (maxRpm == null)
                          const Text('UNAVAILABLE (CONFIGURATION REQUIRED)', style: TextStyle(color: RoadOSColors.hyperOrange, fontSize: 8, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (maxRpm != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: metrics.rpm != null ? (metrics.rpm! / maxRpm).clamp(0.0, 1.0) : 0.0,
                          backgroundColor: RoadOSColors.cardSurface,
                          valueColor: AlwaysStoppedAnimation<Color>(metrics.rpm != null ? RoadOSColors.cyberCyan : Colors.grey),
                          minHeight: 6,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Telemetry Grid Cards
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            if (!isEv) SizedBox(width: 150, child: _buildTelemetryCard('GEAR', metrics.gear != null ? '${metrics.gear}' : 'N', RoadOSColors.hyperOrange)),
            if (!isEv) SizedBox(width: 150, child: _buildTelemetryCard('COOLANT', metrics.coolantTempC != null ? '${metrics.coolantTempC!.round()} degC' : 'UNAVAILABLE', RoadOSColors.hyperOrange)),
            SizedBox(width: 150, child: _buildTelemetryCard('BATTERY', metrics.batteryVoltage != null ? '${metrics.batteryVoltage!.toStringAsFixed(1)}V' : 'UNAVAILABLE', RoadOSColors.apexEmerald)),
            if (!isCar) SizedBox(width: 150, child: _buildTelemetryCard('LEAN', metrics.leanAngleDeg != null ? '${metrics.leanAngleDeg!.round()} deg' : 'UNAVAILABLE', RoadOSColors.cyberCyan)),
            if (metrics.engineLoadPct != null) SizedBox(width: 150, child: _buildTelemetryCard('LOAD', '${metrics.engineLoadPct!.round()}%', RoadOSColors.cyberCyan)),
          ],
        ),
        const SizedBox(height: 14),
        _buildRideControls(state),
      ],
    );
  }

  Widget _buildRideControls(RideState state) {
    return Container(
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
    );
  }

  Widget _buildDiagnosticView() {
    return StreamBuilder<List<DiagnosticTroubleCode>>(
      stream: _engine.diagnosticCodesStream,
      initialData: _engine.latestDtcs,
      builder: (context, snapshot) {
        final dtcs = snapshot.data ?? [];
        if (_engine.getConnectionStatus() != TelemetryConnectionStatus.connected) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('UNAVAILABLE / DISCONNECTED', style: TextStyle(color: RoadOSColors.errorCrimson, fontWeight: FontWeight.bold)),
            ),
          );
        }
        if (dtcs.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Text('NO ACTIVE DIAGNOSTICS', style: TextStyle(color: RoadOSColors.apexEmerald, fontWeight: FontWeight.bold)),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: dtcs.map((dtc) {
            Color sevColor;
            switch (dtc.severity) {
              case DtcSeverity.info: sevColor = Colors.blueAccent; break;
              case DtcSeverity.caution: sevColor = Colors.yellowAccent; break;
              case DtcSeverity.warning: sevColor = RoadOSColors.hyperOrange; break;
              case DtcSeverity.critical: sevColor = RoadOSColors.errorCrimson; break;
            }

            return RoadOSCard(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dtc.code, style: TextStyle(color: sevColor, fontSize: 16, fontWeight: FontWeight.bold)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: sevColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                        child: Text(dtc.severity.name.toUpperCase(), style: TextStyle(color: sevColor, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(dtc.subsystem, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 12)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: dtc.isActive ? RoadOSColors.errorCrimson.withValues(alpha: 0.2) : RoadOSColors.apexEmerald.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(dtc.isActive ? 'ACTIVE' : 'INACTIVE', style: TextStyle(color: dtc.isActive ? RoadOSColors.errorCrimson : RoadOSColors.apexEmerald, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(dtc.description, style: const TextStyle(color: Colors.white, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('First Detected: ${dtc.firstDetectedAt.toLocal().toString().split('.').first}', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
                  Text('Last Detected: ${dtc.lastDetectedAt.toLocal().toString().split('.').first}', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildHealthView(LiveRideMetrics metrics) {
    return Column(
      children: [
        RoadOSCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('VEHICLE HEALTH', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHealthIndicator('BATTERY', metrics.batteryVoltage != null ? '${metrics.batteryVoltage!.toStringAsFixed(1)}V' : 'UNAVAILABLE', RoadOSColors.apexEmerald),
                  _buildHealthIndicator('COOLANT', metrics.coolantTempC != null ? '${metrics.coolantTempC!.round()}°C' : 'UNAVAILABLE', RoadOSColors.hyperOrange),
                  _buildHealthIndicator('FUEL', metrics.fuelLevelPercent != null ? '${metrics.fuelLevelPercent!.round()}%' : 'UNAVAILABLE', RoadOSColors.cyberCyan),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthIndicator(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
      ],
    );
  }

  Widget _buildTripView(LiveRideMetrics metrics) {
    final charts = _engine.getHistoricalChartPoints();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RoadOSCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Text('TRIP SUMMARY', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildHealthIndicator('DISTANCE', '${metrics.distanceKm.toStringAsFixed(1)} KM', Colors.white),
                  _buildHealthIndicator('DURATION', '${metrics.durationSeconds} s', Colors.white),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text('HISTORICAL TELEMETRY PROFILE', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        Container(
          height: 200,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF080C1A),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1A2035)),
          ),
          child: charts.isEmpty
              ? const Center(child: Text('NO HISTORY RECORDED', style: TextStyle(color: RoadOSColors.textMuted)))
              : CustomPaint(
                  painter: TruthfulHistoricalChartPainter(points: charts),
                  size: Size.infinite,
                ),
        ),
      ],
    );
  }

  Widget _buildTelemetryCard(String label, String value, Color color) {
    return RoadOSCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class TruthfulHistoricalChartPainter extends CustomPainter {
  final List<HistoricalChartPoint> points;

  TruthfulHistoricalChartPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = RoadOSColors.cyberCyan
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    final sortedPoints = List<HistoricalChartPoint>.from(points)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    final firstTime = sortedPoints.first.timestamp.millisecondsSinceEpoch;
    final lastTime = sortedPoints.last.timestamp.millisecondsSinceEpoch;
    final timeRange = (lastTime - firstTime).toDouble();

    // Find max speed for scaling
    double maxSpeed = 1.0;
    for (var p in sortedPoints) {
      if (p.speedKmh != null && p.speedKmh! > maxSpeed) {
        maxSpeed = p.speedKmh!;
      }
    }

    bool isFirst = true;

    for (int i = 0; i < sortedPoints.length; i++) {
      final p = sortedPoints[i];
      if (p.speedKmh == null) {
        isFirst = true; // Break the line
        continue;
      }

      double x = timeRange == 0 ? size.width / 2 : ((p.timestamp.millisecondsSinceEpoch - firstTime) / timeRange) * size.width;
      double y = size.height - ((p.speedKmh! / maxSpeed) * size.height);

      if (isFirst) {
        path.moveTo(x, y);
        isFirst = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
