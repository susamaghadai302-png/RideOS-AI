import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/widgets/rideos_3d_model_viewer.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/vehicle_protocols/models/normalized_telemetry.dart';
import '../../../../core/bluetooth/bluetooth_engine.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import '../../../../core/graphics/global_3d_state_bridge.dart';
import '../../../connected_vehicle/presentation/screens/connect_vehicle_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  TELEMETRY DASHBOARD — Futuristic 3D Digital Cockpit
// ─────────────────────────────────────────────────────────────────────────────

class TelemetryDashboardScreen extends ConsumerStatefulWidget {
  const TelemetryDashboardScreen({super.key});

  @override
  ConsumerState<TelemetryDashboardScreen> createState() =>
      _TelemetryDashboardScreenState();
}

class _TelemetryDashboardScreenState
    extends ConsumerState<TelemetryDashboardScreen> {
  bool _headlightOn = true;
  bool _hazardOn = false;
  bool _tractionControl = true;
  bool _absActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Global3DStateBridge().setCameraPreset('dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bluetoothStateProvider);
    final activeAdapter = ref.watch(activeAdapterProvider);
    final activeContext = ref.watch(activeVehicleContextProvider);
    final isLiveConnected = state.isConnected && activeAdapter != null;

    final vehicle = activeContext.profile;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'DIGITAL COCKPIT',
              style: TextStyle(
                color: RoadOSColors.textPrimary,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 10),
            RoadOSStatusPill(
              label: isLiveConnected ? 'LIVE STREAMING' : 'OFFLINE MODE',
              color: isLiveConnected
                  ? RoadOSColors.apexEmerald
                  : RoadOSColors.warningAmber,
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: CinematicBackground(
        child: SafeArea(
          child: StreamBuilder<NormalizedTelemetry>(
            stream: activeAdapter?.telemetryStream,
            builder: (context, snapshot) {
              final telemetry =
                  snapshot.data ?? activeContext.telemetry;

              final speed = telemetry.speed.hasValue
                  ? telemetry.speed.value!.toDouble()
                  : 0.0;
              final rpm = telemetry.rpm.hasValue
                  ? telemetry.rpm.value!.toDouble()
                  : 0.0;
              final temp = telemetry.engineTemperature.hasValue
                  ? telemetry.engineTemperature.value!.toDouble()
                  : 85.0;
              final battery = telemetry.batteryVoltage.hasValue
                  ? telemetry.batteryVoltage.value!.toDouble()
                  : 13.6;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // ── 1. Top Central Speed & Tachometer Gauge HUD ───────────
                    _buildCockpitHeroGauge(speed, rpm, isLiveConnected),
                    const SizedBox(height: 18),

                    // ── 2. Center 3D Vehicle Interactive Inspection Bay ──────
                    if (vehicle != null)
                      _build3DVehicleCockpitBay(vehicle, speed, rpm)
                    else
                      _buildConnectVehicleBanner(context),
                    const SizedBox(height: 18),

                    // ── 3. Floating Telemetry Pods (4 Grid) ──────────────────
                    _buildTelemetryPods(battery, temp, speed, rpm),
                    const SizedBox(height: 18),

                    // ── 4. Actuators & Ride Mode Controls ────────────────────
                    _buildActuatorsControlPanel(),
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Top Cockpit Speed & RPM Holographic Arc Gauge
  Widget _buildCockpitHeroGauge(double speed, double rpm, bool isLive) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RoadOSColors.borderTranslucent, width: 1.2),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x35101A38), Color(0x20060A18)],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Speed Digital Output
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'SPEED',
                    style: TextStyle(
                      color: RoadOSColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        isLive ? '${speed.round()}' : '--',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'KM/H',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: RoadOSColors.cyberCyan,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // RPM Digital Output
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'ENGINE RPM',
                    style: TextStyle(
                      color: RoadOSColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        isLive ? '${rpm.round()}' : '--',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          color: RoadOSColors.neonViolet,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'RPM',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: RoadOSColors.neonViolet,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Tachometer Visual Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (rpm / 12000.0).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0x30101A38),
              valueColor: AlwaysStoppedAnimation<Color>(
                rpm > 9000
                    ? RoadOSColors.errorCrimson
                    : (rpm > 6000
                        ? RoadOSColors.hyperOrange
                        : RoadOSColors.roadCyan),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3D Vehicle Bay for Cockpit View
  Widget _build3DVehicleCockpitBay(
    dynamic vehicle,
    double speed,
    double rpm,
  ) {
    return Container(
      height: 240,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RoadOSColors.borderSubtle, width: 1.0),
        gradient: const LinearGradient(
          colors: [Color(0x25101A38), Color(0x1004060C)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            RideOS3DModelViewer(
              vehicleProfile: vehicle,
              cameraOrbit: '0deg 75deg 90%',
              autoRotate: false,
              exposure: 1.1,
            ),
            Positioned(
              bottom: 10,
              left: 14,
              child: Text(
                '${vehicle.manufacturer} ${vehicle.model} | COCKPIT VIEW'.toUpperCase(),
                style: const TextStyle(
                  color: RoadOSColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Disconnected Callout Card
  Widget _buildConnectVehicleBanner(BuildContext context) {
    return RoadOSCard(
      child: Row(
        children: [
          const Icon(
            Icons.bluetooth_searching_rounded,
            color: RoadOSColors.cyberCyan,
            size: 28,
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONNECT VEHICLE FOR LIVE TELEMETRY',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Pair with OBD-II / BLE CCU to stream full engine diagnostics.',
                  style: TextStyle(
                    color: RoadOSColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RoadOSColors.cyberCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ConnectVehicleScreen(),
              ),
            ),
            child: const Text('CONNECT', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  /// 4 Floating Telemetry Pods
  Widget _buildTelemetryPods(
    double battery,
    double temp,
    double speed,
    double rpm,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final podWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: podWidth,
              child: FloatingHudBubble(
                icon: Icons.battery_charging_full_rounded,
                label: 'Battery Voltage',
                value: battery.toStringAsFixed(1),
                unit: 'V',
                accentColor: RoadOSColors.apexEmerald,
              ),
            ),
            SizedBox(
              width: podWidth,
              child: FloatingHudBubble(
                icon: Icons.thermostat_rounded,
                label: 'Engine Temp',
                value: '${temp.round()}',
                unit: ' degC',
                accentColor: RoadOSColors.hyperOrange,
              ),
            ),
            SizedBox(
              width: podWidth,
              child: FloatingHudBubble(
                icon: Icons.air_rounded,
                label: 'Engine Load',
                value: '42',
                unit: '%',
                accentColor: RoadOSColors.cyberCyan,
              ),
            ),
            SizedBox(
              width: podWidth,
              child: FloatingHudBubble(
                icon: Icons.compress_rounded,
                label: 'Oil Pressure',
                value: '4.2',
                unit: 'BAR',
                accentColor: RoadOSColors.neonViolet,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Actuators & Ride Mode Controls
  Widget _buildActuatorsControlPanel() {
    return RoadOSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ACTUATORS & RIDE ASSIST TOGGLES',
            style: TextStyle(
              color: RoadOSColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildToggleItem(
                  'Headlights',
                  Icons.lightbulb_rounded,
                  _headlightOn,
                  RoadOSColors.roadCyan,
                  (val) => setState(() => _headlightOn = val),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToggleItem(
                  'Hazard Lights',
                  Icons.warning_amber_rounded,
                  _hazardOn,
                  RoadOSColors.hyperOrange,
                  (val) => setState(() => _hazardOn = val),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildToggleItem(
                  'Traction Control',
                  Icons.all_inclusive_rounded,
                  _tractionControl,
                  RoadOSColors.apexEmerald,
                  (val) => setState(() => _tractionControl = val),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildToggleItem(
                  'Cornering ABS',
                  Icons.shield_rounded,
                  _absActive,
                  RoadOSColors.neonViolet,
                  (val) => setState(() => _absActive = val),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildToggleItem(
    String label,
    IconData icon,
    bool isActive,
    Color activeColor,
    ValueChanged<bool> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isActive
            ? activeColor.withValues(alpha: 0.12)
            : const Color(0x20101A38),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive
              ? activeColor.withValues(alpha: 0.5)
              : RoadOSColors.borderSubtle,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: isActive ? activeColor : RoadOSColors.textMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : RoadOSColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Switch(
            value: isActive,
            activeColor: activeColor,
            onChanged: (val) {
              LuxAudioHapticsService.selectionClick();
              onChanged(val);
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
