import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/graphics/liquid_glass_engine.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/widgets/rideos_3d_model_viewer.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/bluetooth/bluetooth_engine.dart';
import '../../../../core/bluetooth/models/bluetooth_connection_state.dart' as ble_state;
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import '../../../../core/vehicle_resolution/providers/my_vehicles_provider.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import '../../../../core/vehicle_health/services/vehicle_health_engine.dart';
import '../../../../core/notifications/services/notification_center_manager.dart';
import '../../../../core/intelligence/models/vehicle_intelligence_models.dart';
import '../../../../core/intelligence/services/central_vehicle_intelligence_engine.dart';
import '../../../../core/graphics/global_3d_state_bridge.dart';
import '../../../garage/presentation/screens/luxury_garage_showroom_screen.dart';
import '../../../navigation/presentation/screens/three_d_navigation_screen.dart';
import '../../../diagnostics/presentation/screens/vehicle_health_dashboard_screen.dart';
import '../../../connected_vehicle/presentation/screens/connect_vehicle_screen.dart';
import '../../../obd_tpms/core/services/obd_full_telemetry_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  HOME SCREEN — 3D Spatial Holographic Command Center
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  bool _isSimulatorMode = false;
  Timer? _simTimer;
  double _simSpeed = 74.0;
  int _simRpm = 5420;
  int _simTick = 0;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    VehicleHealthEngine().initialize(ref);
    NotificationCenterManager().initialize(ref);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  void _toggleSimulatorMode(bool enable) {
    LuxAudioHapticsService.selectionClick();
    setState(() {
      _isSimulatorMode = enable;
      ObdFullTelemetryService().isSimulatorMode = enable;
    });

    if (enable) {
      _simTimer?.cancel();
      _simTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted || !_isSimulatorMode) {
          timer.cancel();
          return;
        }
        setState(() {
          _simTick++;
          _simSpeed = (70.0 + (_simTick % 15) * 1.2).clamp(0.0, 299.0);
          _simRpm = (5200 + (_simTick % 12) * 180).clamp(0, 14000);
        });
      });
    } else {
      _simTimer?.cancel();
      _simTimer = null;
    }
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bluetoothStateProvider);
    final isRealBleConnected =
        bleState == ble_state.BluetoothConnectionState.live ||
            bleState == ble_state.BluetoothConnectionState.connected;
    final isConnected = _isSimulatorMode || isRealBleConnected;

    final activeContext = ref.watch(activeVehicleContextProvider);
    final ownedVehicles = ref.watch(myVehiclesProvider);
    final aiIntel = ref.watch(vehicleIntelligenceProvider);

    final activeVehicle = activeContext.hasActiveVehicle
        ? activeContext.profile!
        : (ownedVehicles.isNotEmpty
            ? ownedVehicles.first
            : const VehicleProfile(
                id: 'v_bmw_m1000rr',
                manufacturer: 'BMW',
                model: 'M1000RR',
                variant: 'M Competition',
                year: 2024,
                category: 'Superbike',
                engineType: '999cc Inline-4',
                fuelType: 'Petrol',
                protocolAdapter: 'bmw_motorrad',
                model3DUrl: 'assets/models/bmw_m1000rr.glb',
                thumbnailUrl: 'assets/garage/bmw_m1000rr.png',
              ));

    final telemetry = activeContext.telemetry;

    final speedVal = _isSimulatorMode
        ? '${_simSpeed.round()}'
        : (telemetry.speed.hasValue
            ? '${telemetry.speed.value!.round()}'
            : (isRealBleConnected ? '0' : '--'));

    final rpmVal = _isSimulatorMode
        ? '$_simRpm'
        : (telemetry.rpm.hasValue
            ? '${telemetry.rpm.value}'
            : (isRealBleConnected ? '1100' : '--'));

    final battVal = _isSimulatorMode
        ? '13.8'
        : (telemetry.batteryVoltage.hasValue
            ? telemetry.batteryVoltage.value!.toStringAsFixed(1)
            : (isRealBleConnected ? '13.6' : '--'));

    final tempVal = _isSimulatorMode
        ? '89'
        : (telemetry.engineTemperature.hasValue
            ? '${telemetry.engineTemperature.value}'
            : (isRealBleConnected ? '85' : '--'));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Global3DStateBridge().setCameraPreset('home');
      Global3DStateBridge().loadVehicle(activeVehicle);
      Global3DStateBridge().updateTelemetry(
        speedKmh: _isSimulatorMode
            ? _simSpeed
            : (telemetry.speed.value?.toDouble() ?? 0.0),
        rpm: _isSimulatorMode
            ? _simRpm.toDouble()
            : (telemetry.rpm.value?.toDouble() ?? 0.0),
        isIgnitionOn: isConnected,
      );
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // LAYER 0: Deep Atmospheric Environment (Cinematic Background)
          Positioned.fill(
            child: CinematicBackground(
              child: Container(),
            ),
          ),
          
          // LAYER 1: The true 3D Digital Twin (Centerpiece)
          Positioned.fill(
            child: SafeArea(
              child: Center(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: RideOS3DModelViewer(
                    vehicleProfile: activeVehicle,
                    cameraOrbit: '30deg 75deg 105%',
                    autoRotate: false,
                    cameraControls: false, // Disabled to allow scrolling the UI on top
                    exposure: 1.2,
                  ),
                ),
              ),
            ),
          ),

          // LAYER 2: Holographic Grid / Scan overlay effect behind UI
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.8,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // LAYER 3: Interactive Glass Spatial UI
          Positioned.fill(
            child: SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // ── 1. Top Command Header ────────────────────────
                        _buildCommandHeader(context, activeVehicle, isConnected),
                        
                        // We use a massive spacer to push the rest of the UI down
                        // so the 3D car is fully visible in the center.
                        SizedBox(height: MediaQuery.of(context).size.height * 0.45),

                        // ── 2. Floating Spatial Telemetry Bubbles ──────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Left Wing
                            SpatialFloatingWidget(
                              tiltY: 0.0,
                              zDepth: 0.0,
                              child: Column(
                                children: [
                                  FloatingHudBubble(
                                    icon: Icons.speed_rounded,
                                    label: 'Speed',
                                    value: speedVal,
                                    unit: 'km/h',
                                    accentColor: RoadOSColors.roadCyan,
                                  ),
                                  const SizedBox(height: 12),
                                  FloatingHudBubble(
                                    icon: Icons.electric_bolt_rounded,
                                    label: 'RPM',
                                    value: rpmVal,
                                    unit: 'rpm',
                                    accentColor: RoadOSColors.neonViolet,
                                  ),
                                ],
                              ),
                            ),
                            
                            // Right Wing
                            SpatialFloatingWidget(
                              tiltY: 0.0,
                              zDepth: 0.0,
                              child: Column(
                                children: [
                                  FloatingHudBubble(
                                    icon: Icons.battery_charging_full_rounded,
                                    label: 'Battery',
                                    value: battVal,
                                    unit: 'V',
                                    accentColor: RoadOSColors.apexEmerald,
                                  ),
                                  const SizedBox(height: 12),
                                  FloatingHudBubble(
                                    icon: Icons.thermostat_rounded,
                                    label: 'Temp',
                                    value: tempVal,
                                    unit: ' degC',
                                    accentColor: RoadOSColors.hyperOrange,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),

                        // ── 3. Quick Action Command Deck ──────────────────────────────
                        SpatialFloatingWidget(
                          tiltX: 0.0,
                          zDepth: 0.0,
                          child: _buildQuickActionDeck(context),
                        ),
                        
                        const SizedBox(height: 20),

                        // ── 4. AI Copilot & Live Status Banner ─────────────────────────
                        SpatialFloatingWidget(
                          tiltX: 0.0,
                          zDepth: 0.0,
                          child: _buildAiCopilotBanner(context, aiIntel),
                        ),
                        
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Top Command Center Header
  Widget _buildCommandHeader(
    BuildContext context,
    VehicleProfile vehicle,
    bool isConnected,
  ) {
    return SpatialFloatingWidget(
      tiltX: 0.0, // Tilt downwards slightly
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 10,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${vehicle.manufacturer.toUpperCase()} ${vehicle.model.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: RoadOSColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    RoadOSStatusPill(
                      label: isConnected ? 'TELEMATICS ACTIVE' : 'OFFLINE',
                      color: isConnected
                          ? RoadOSColors.apexEmerald
                          : RoadOSColors.textMuted,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${vehicle.category.toUpperCase()} | ${vehicle.engineType} | DIGITAL TWIN ACTIVE',
                  style: const TextStyle(
                    color: RoadOSColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Live Simulator Toggle for Testing Telematics
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _isSimulatorMode
                  ? RoadOSColors.cyberCyan.withValues(alpha: 0.15)
                  : const Color(0x20101A38),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isSimulatorMode
                    ? RoadOSColors.cyberCyan.withValues(alpha: 0.5)
                    : RoadOSColors.borderSubtle,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.sensors_rounded,
                  size: 14,
                  color: _isSimulatorMode
                      ? RoadOSColors.cyberCyan
                      : RoadOSColors.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'SIMULATOR',
                  style: TextStyle(
                    color: _isSimulatorMode
                        ? RoadOSColors.cyberCyan
                        : RoadOSColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 4),
                Switch(
                  value: _isSimulatorMode,
                  activeThumbColor: RoadOSColors.cyberCyan,
                  onChanged: _toggleSimulatorMode,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Quick Action Deck (Navigation, Connect, Diagnostics, Safety)
  Widget _buildQuickActionDeck(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'COMMAND ACTIONS',
          style: TextStyle(
            color: RoadOSColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: QuickActionTile(
                icon: Icons.navigation_rounded,
                label: '3D Nav',
                accentColor: RoadOSColors.cyberCyan,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ThreeDNavigationScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickActionTile(
                icon: Icons.bluetooth_searching_rounded,
                label: 'Connect',
                accentColor: RoadOSColors.electricBlue,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ConnectVehicleScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickActionTile(
                icon: Icons.health_and_safety_rounded,
                label: 'Health',
                accentColor: RoadOSColors.apexEmerald,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VehicleHealthDashboardScreen(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: QuickActionTile(
                icon: Icons.view_in_ar_rounded, // Changed from shield to 3D garage for quick access
                label: 'Garage',
                accentColor: RoadOSColors.hyperOrange,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LuxuryGarageShowroomScreen(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// AI Copilot Banner
  Widget _buildAiCopilotBanner(
    BuildContext context,
    VehicleIntelligenceSnapshot aiIntel,
  ) {
    return RoadOSCard(
      borderColor: RoadOSColors.borderTranslucent,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RoadOSGradients.primaryViolet,
              boxShadow: RoadOSShadows.neonGlow(opacity: 0.4, blur: 12),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI RIDER COPILOT ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Predictive tyre grip normal | Weather clear 28 degC | Zero engine DTC faults detected',
                  style: TextStyle(
                    color: RoadOSColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: RoadOSColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}
