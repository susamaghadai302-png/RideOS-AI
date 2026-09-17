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
  // No simulator logic in production

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    VehicleHealthEngine().initialize(ref);
    NotificationCenterManager().initialize(ref);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..forward();
  }

  // Sim mode removed

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleState = ref.watch(bluetoothStateProvider);
    final isRealBleConnected =
        bleState == ble_state.BluetoothConnectionState.live ||
            bleState == ble_state.BluetoothConnectionState.connected;
    final isConnected = isRealBleConnected;

    final activeContext = ref.watch(activeVehicleContextProvider);
    final ownedVehicles = ref.watch(myVehiclesProvider);
    final aiIntel = ref.watch(vehicleIntelligenceProvider);

    final VehicleProfile? activeVehicle = activeContext.hasActiveVehicle
        ? activeContext.profile!
        : (ownedVehicles.isNotEmpty
            ? ownedVehicles.first
            : null);

    final telemetry = activeContext.telemetry;

    final speedVal = telemetry.speed.hasValue
        ? '${telemetry.speed.value!.round()}'
        : '--';

    final rpmVal = telemetry.rpm.hasValue
        ? '${telemetry.rpm.value}'
        : '--';

    final battVal = telemetry.batteryVoltage.hasValue
        ? telemetry.batteryVoltage.value!.toStringAsFixed(1)
        : '--';

    final tempVal = telemetry.engineTemperature.hasValue
        ? '${telemetry.engineTemperature.value}'
        : '--';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Global3DStateBridge().setCameraPreset('home');
      if (activeVehicle != null) {
        Global3DStateBridge().loadVehicle(activeVehicle);
      }
      Global3DStateBridge().updateTelemetry(
        speedKmh: telemetry.speed.value?.toDouble(),
        rpm: telemetry.rpm.value?.toDouble(),
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
                          children: [
                            // Left Wing
                            Expanded(
                              child: SpatialFloatingWidget(
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
                            ),
                            
                            // Right Wing
                            Expanded(
                              child: SpatialFloatingWidget(
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
    VehicleProfile? vehicle,
    bool isConnected,
  ) {
    final vehicleName = vehicle != null
        ? '${vehicle.manufacturer.toUpperCase()} ${vehicle.model.toUpperCase()}'
        : 'NO VEHICLE';
    final vehicleSubtitle = vehicle != null
        ? '${vehicle.category.toUpperCase()} | ${vehicle.engineType} | DIGITAL TWIN ACTIVE'
        : 'ADD A VEHICLE FROM GARAGE TO GET STARTED';
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
                      vehicleName,
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
                  vehicleSubtitle,
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
          // Simulator toggle removed from production header
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
