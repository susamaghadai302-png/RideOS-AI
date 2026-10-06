import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import '../../domain/models/vehicle_capabilities_extension.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/widgets/garage_motorcycle_hero.dart';
import '../../../../core/widgets/roados_visual_environment.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../cockpit/presentation/screens/cockpit_command_center_screen.dart';
import '../../../navigation/presentation/screens/destination_search_screen.dart';
import '../../../navigation/presentation/screens/three_d_navigation_screen.dart';
import '../../../garage/presentation/screens/luxury_garage_showroom_screen.dart';
import '../../../obd_tpms/presentation/screens/obd_diagnostics_screen.dart';
import '../../../safety/presentation/screens/rider_safety_center_screen.dart';
import '../../../sos_safety/presentation/bloc/sos_bloc.dart';
import '../../../sos_safety/presentation/bloc/sos_event.dart';
import '../../../voice_assistant/presentation/screens/voice_assistant_hud_screen.dart';
import '../widgets/dashboard_dock_weather_widgets.dart';
import '../widgets/live_telemetry_widgets.dart';
import '../widgets/tpms_obd_health_widgets.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../domain/models/advanced_dashboard_models.dart';
import '../../core/services/realtime_dashboard_telemetry_engine.dart';
import '../../../../core/device_providers/models/normalized_telemetry_models.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with TickerProviderStateMixin {
  late AnimationController _staggerController;

  // Stagger Intervals
  late Animation<Offset> _heroSlideAnim;
  late Animation<Offset> _quickActionsSlideAnim;
  late Animation<Offset> _mobilityCardSlideAnim;
  late Animation<Offset> _stageSlideAnim;
  late Animation<Offset> _gaugesSlideAnim;
  late Animation<Offset> _aiCardSlideAnim;

  String _speedUnit = 'KM/H';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    // Stagger Intervals
    _heroSlideAnim = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
      CurvedAnimation(parent: _staggerController, curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic)),
    );

    _quickActionsSlideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(parent: _staggerController, curve: const Interval(0.1, 0.45, curve: Curves.easeOutCubic)),
    );

    _mobilityCardSlideAnim = Tween<Offset>(begin: const Offset(0, 0.20), end: Offset.zero).animate(
      CurvedAnimation(parent: _staggerController, curve: const Interval(0.2, 0.55, curve: Curves.easeOutCubic)),
    );

    _stageSlideAnim = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero).animate(
      CurvedAnimation(parent: _staggerController, curve: const Interval(0.3, 0.65, curve: Curves.easeOutCubic)),
    );

    _gaugesSlideAnim = Tween<Offset>(begin: const Offset(0, 0.30), end: Offset.zero).animate(
      CurvedAnimation(parent: _staggerController, curve: const Interval(0.4, 0.75, curve: Curves.easeOutCubic)),
    );

    _aiCardSlideAnim = Tween<Offset>(begin: const Offset(0, 0.35), end: Offset.zero).animate(
      CurvedAnimation(parent: _staggerController, curve: const Interval(0.5, 0.85, curve: Curves.easeOutCubic)),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  void _toggleSpeedUnit() {
    setState(() {
      _speedUnit = _speedUnit == 'KM/H' ? 'MPH' : 'KM/H';
    });
  }

  /// Triggers SOS with the rider's real GPS position.
  /// Always fires the SOS event even if GPS is unavailable — a safety action
  /// must never be silently blocked by a location failure.
  Future<void> _triggerSos() async {
    LuxAudioHapticsService.heavyImpact();
    double lat = 0.0;
    double lng = 0.0;

    try {
      // Try last-known position first (instant)
      Position? pos = await Geolocator.getLastKnownPosition();
      pos ??= await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
        timeLimit: const Duration(seconds: 6),
      );
      lat = pos.latitude;
      lng = pos.longitude;
    } catch (_) {
      // GPS unavailable — fire SOS anyway with (0, 0) so the backend
      // still receives the alert and can ask the rider for their location.
    }

    if (mounted) {
      context.read<SosBloc>().add(
        TriggerSosEvent(lat: lat, lng: lng, triggerType: 'MANUAL'),
      );
    }
  }

  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final activeVehicle = ref.watch(activeVehicleContextProvider);
    final dashEngine = RealtimeDashboardTelemetryEngine();
    final conn = dashEngine.getConnectionStatus();

    return Scaffold(
      backgroundColor: RoadOSColors.deepSpaceBlack,
      body: Stack(
        children: [
          RoadOSVisualEnvironment(
        environmentType: RoadOSEnvironmentType.dashboard,
        child: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = LuxResponsiveContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Greeting & Hero Destination Search Card
                  SlideTransition(
                    position: _heroSlideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final name = state is AuthenticatedState ? state.rider.fullName : 'Rider';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getTimeBasedGreeting()}, $name',
                                  style: RoadOSTypography.titleLarge(),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Where do you want to go today?',
                                  style: RoadOSTypography.bodyMedium(),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),

                        // Destination Search & Voice Input Card
                        RoadOSCard(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  LuxAudioHapticsService.selectionClick();
                                  Navigator.push(context, premiumRoute(const DestinationSearchScreen()));
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: RoadOSColors.roadCyan.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.search_rounded, color: RoadOSColors.roadCyan, size: 20),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    LuxAudioHapticsService.selectionClick();
                                    Navigator.push(context, premiumRoute(const DestinationSearchScreen()));
                                  },
                                  behavior: HitTestBehavior.opaque,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                                    child: Text(
                                      'Search destination or waypoint...',
                                      style: RoadOSTypography.bodyMedium(color: RoadOSColors.textMuted),
                                    ),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.mic_rounded, color: RoadOSColors.roadCyan, size: 22),
                                tooltip: 'Voice AI Copilot',
                                onPressed: () {
                                  LuxAudioHapticsService.mediumImpact();
                                  showLuxSheet(
                context: context,
                title: '',
                                    builder: (_) => const _VoiceHudBottomSheet(),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Quick Actions Grid
                  SlideTransition(
                    position: _quickActionsSlideAnim,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('QUICK ACTIONS', style: RoadOSTypography.caption(color: RoadOSColors.textCyan)),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _buildQuickActionTile(
                              icon: Icons.navigation_rounded,
                              label: 'Navigate',
                              color: RoadOSColors.roadCyan,
                              onTap: () => Navigator.push(context, premiumRoute(const ThreeDNavigationScreen())),
                            ),
                            const SizedBox(width: 10),
                            _buildQuickActionTile(
                              icon: Icons.shield_rounded,
                              label: 'Safety',
                              color: const Color(0xFF69F0AE),
                              onTap: () => Navigator.push(context, premiumRoute(const RiderSafetyCenterScreen())),
                            ),
                            const SizedBox(width: 10),
                            _buildQuickActionTile(
                              icon: Icons.emergency_rounded,
                              label: 'SOS',
                              color: RoadOSColors.errorCrimson,
                              onTap: _triggerSos,
                            ),
                            const SizedBox(width: 10),
                            _buildQuickActionTile(
                              icon: Icons.cable_rounded,
                              label: 'OBD-II',
                              color: RoadOSColors.apexEmerald,
                              onTap: () => Navigator.push(context, premiumRoute(const ObdDiagnosticsScreen())),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Live Mobility & Environmental Status Card
                  SlideTransition(
                    position: _mobilityCardSlideAnim,
                    child: RoadOSCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Pulsing live indicator
                              Container(
                                width: 8, height: 8,
                                decoration: const BoxDecoration(
                                  color: RoadOSColors.apexEmerald,
                                  shape: BoxShape.circle,
                                  boxShadow: [BoxShadow(color: RoadOSColors.apexEmerald, blurRadius: 6)],
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text('LIVE MOBILITY STATUS',
                                style: TextStyle(color: RoadOSColors.apexEmerald, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: RoadOSColors.apexEmerald.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: RoadOSColors.apexEmerald.withValues(alpha: 0.4)),
                                ),
                                child: const Text('LOCATION UNAVAILABLE',
                                  style: TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.w800)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(height: 1, color: Color(0xFF111827)),
                          const SizedBox(height: 12),
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              _buildMobilityStatItem('RANGE', '-- km', Icons.battery_charging_full_rounded, RoadOSColors.textMuted),
                              _buildMobilityStatItem('TRAFFIC', 'NO DATA', Icons.traffic_rounded, RoadOSColors.textMuted),
                              _buildMobilityStatItem('TEMP', '-- degC', Icons.thermostat_rounded, RoadOSColors.textMuted),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Photorealistic 3D Motorcycle Stage Viewer
                  SlideTransition(
                    position: _stageSlideAnim,
                    child: GarageMotorcycleHero(
                      motorcycle: GarageMotorcycles.primary,
                      height: 260,
                      showSpec: true,
                      showGlowOverlay: true,
                      onTap: () => Navigator.push(
                        context,
                        premiumRoute(const LuxuryGarageShowroomScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Fighter Jet HUD Command Center Banner
                  GestureDetector(
                    onTap: () {
                      LuxAudioHapticsService.heavyImpact();
                      Navigator.push(
                        context,
                        premiumRoute(const CockpitCommandCenterScreen()),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF07192C), Color(0xFF0D253A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.5), width: 1.2),
                        boxShadow: LuxShadows.glassGlow(RoadOSColors.cyberCyan),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: RoadOSColors.cyberCyan.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.flight_takeoff_rounded, color: RoadOSColors.cyberCyan, size: 22),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'FIGHTER JET AI COCKPIT V2.0',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: RoadOSColors.cyberCyan,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Pitch/Roll Horizon | G-Force Telemetry | Apex Lean',
                                  style: TextStyle(fontSize: 10, color: RoadOSColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, color: RoadOSColors.cyberCyan, size: 14),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 5. Staggered Live Gauges & Digital Twin Cards
                  StreamBuilder<LiveRideMetrics>(
                    stream: RealtimeDashboardTelemetryEngine().metricsStream,
                    initialData: RealtimeDashboardTelemetryEngine().getLiveMetrics(),
                    builder: (context, snapshot) {
                      final metrics = snapshot.data;
                      final isStale = metrics?.isStale ?? true;

                      final speedVal = metrics?.speedKmh;
                      final rpmVal = metrics?.rpm?.toDouble();
                      final leanVal = metrics?.leanAngleDeg;
                      final gearVal = metrics?.gear?.toString();
                      final fuelVal = metrics?.fuelLevelPercent;
                      final batVal = metrics?.batteryVoltage;
                      final coolantVal = metrics?.coolantTempC;

                      final displaySpeed = speedVal != null ? (_speedUnit == 'MPH' ? speedVal * 0.621371 : speedVal) : null;

                      return SlideTransition(
                        position: _gaugesSlideAnim,
                        child: Column(
                          children: [
                            if (isStale)
                              Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: RoadOSColors.errorCrimson.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: RoadOSColors.errorCrimson.withValues(alpha: 0.5)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded, color: RoadOSColors.errorCrimson, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      conn != TelemetryConnectionStatus.connected 
                                          ? 'TELEMETRY DISCONNECTED' 
                                          : 'STALE TELEMETRY', 
                                      style: const TextStyle(color: RoadOSColors.errorCrimson, fontWeight: FontWeight.bold, fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              SpeedometerArcWidget(
                                currentSpeed: displaySpeed,
                                maxSpeed: activeVehicle.maxSpeedKmh,
                                leanAngle: activeVehicle.hasLeanAngle ? leanVal : null,
                                unit: _speedUnit,
                                onUnitToggle: _toggleSpeedUnit,
                              ),
                              const SizedBox(height: 16),
                              if (activeVehicle.hasRpm) ...[
                                LiveTachometerWidget(
                                  currentRpm: rpmVal,
                                  maxRpm: activeVehicle.maxRpm,
                                  redlineRpm: activeVehicle.redlineRpm,
                                ),
                                const SizedBox(height: 12),
                              ],
                              GearIndicatorWidget(currentGear: gearVal),
                              const SizedBox(height: 16),
                              if (activeVehicle.hasFuel) ...[
                                FuelBatteryGaugeWidget(
                                  fuelPercent: fuelVal,
                                  batteryPercent: batVal != null ? (batVal / 14.4 * 100.0).clamp(0.0, 100.0) : null
                                ),
                                const SizedBox(height: 12),
                              ] else ...[
                                FuelBatteryGaugeWidget(
                                  fuelPercent: null, // No fuel for EV
                                  batteryPercent: batVal != null ? (batVal / 14.4 * 100.0).clamp(0.0, 100.0) : null
                                ),
                                const SizedBox(height: 12),
                              ],
                              EngineTemperatureWidget(engineTempCelsius: coolantVal),
                              // TPMS: Adapt to vehicle profile
                              TpmsCardWidget(
                                tirePressures: List.generate(activeVehicle.tpmsSensorCount, (_) => null), // Telemetry stream doesn't yet support TPMS, so pass null
                                tireLabels: activeVehicle.tpmsSensorLabels,
                                targetPressure: activeVehicle.optimalTirePressureFront,
                              ),
                            const SizedBox(height: 16),
                            StreamBuilder<List<DiagnosticTroubleCode>>(
                              stream: dashEngine.diagnosticCodesStream,
                              initialData: dashEngine.latestDtcs,
                              builder: (context, dtcSnapshot) {
                                final dtcs = dtcSnapshot.data ?? [];
                                return ObdStatusCardWidget(
                                  isConnected: !isStale && metrics != null,
                                  faultCodeCount: dtcs.length,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            // AI Health Score: Not available from real telemetry stream — show UNAVAILABLE
                            const AiHealthScoreWidget(healthScore: null),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // 6. AI Mobility Assistant Card ("Ask RoadOS AI")
                  SlideTransition(
                    position: _aiCardSlideAnim,
                    child: RoadOSCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: RoadOSGradients.brandCyan,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.auto_awesome, color: Colors.black, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Ask Rideo Pro Copilot', style: RoadOSTypography.titleMedium()),
                                    Text('Real-time mobility & trajectory intelligence', style: RoadOSTypography.caption()),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildAiPromptChip('Find fastest route', () {
                                Navigator.push(context, premiumRoute(const ThreeDNavigationScreen()));
                              }),
                              _buildAiPromptChip('Check traffic & hazards', () {
                                Navigator.push(context, premiumRoute(const ThreeDNavigationScreen()));
                              }),
                              _buildAiPromptChip('Plan canyon tour', () {
                                Navigator.push(context, premiumRoute(const AiAssistantScreen()));
                              }),
                              _buildAiPromptChip('Diagnose CAN-BUS', () {
                                Navigator.push(context, premiumRoute(const ObdDiagnosticsScreen()));
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 7. Staggered Weather Radar & Summary
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth < 450 ? 450.0 : constraints.maxWidth;
                      return SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        child: SizedBox(
                          width: width,
                          child: Column(
                            children: [
                              WeatherWidget(
                                weatherCondition: null,
                                tempCelsius: null,
                                rainChance: null,
                                windSpeedKmh: null,
                                onWeatherModeChanged: (mode) {
                                  LuxAudioHapticsService.selectionClick();
                                  showLuxSnack(context, 'Weather simulation: ${mode.name.toUpperCase()}', variant: LuxSnackVariant.info);
                                },
                              ),
                              const SizedBox(height: 20),
                              const LastRideSummaryWidget(),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: content,
          );
        },
      ),
    ),
  ),
  ],
),
);
}

  Widget _buildQuickActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          LuxAudioHapticsService.selectionClick();
          onTap();
        },
        child: RoadOSCard(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.14),
                  boxShadow: [BoxShadow(color: color.withValues(alpha: 0.22), blurRadius: 8, spreadRadius: -2)],
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 7),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobilityStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: RoadOSTypography.caption(color: RoadOSColors.textMuted)),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAiPromptChip(String prompt, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        LuxAudioHapticsService.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: RoadOSColors.cyberCyan.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.32)),
        ),
        child: Text(
          prompt,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: RoadOSColors.cyberCyan,
          ),
        ),
      ),
    );
  }
}

/// Lightweight bottom-sheet host for Voice AI HUD,
/// opened from the dashboard mic button.
class _VoiceHudBottomSheet extends StatelessWidget {
  const _VoiceHudBottomSheet();

  @override
  Widget build(BuildContext context) {
    final h = MediaQuery.of(context).size.height;
    return Container(
      height: h * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF070B18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0x3300E5FF), width: 1.2),
          left: BorderSide(color: Color(0x1A00E5FF), width: 0.8),
          right: BorderSide(color: Color(0x1A00E5FF), width: 0.8),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 4),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0x5500E5FF),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.mic_rounded, color: Color(0xFF00E5FF), size: 20),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'VOICE AI COPILOT',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF00E5FF),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF8899AA), size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0x1500E5FF)),
          const Expanded(child: VoiceAssistantHudScreen()),
        ],
      ),
    );
  }
}
