import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/widgets/rideos_3d_model_viewer.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import '../../../../core/vehicle_health/models/vehicle_health_state.dart';
import '../../../../core/vehicle_health/models/diagnostic_item.dart';
import '../../../../core/vehicle_health/services/vehicle_health_engine.dart';
import '../../../../core/vehicle_health/services/diagnostic_manager.dart';
import '../../../../core/graphics/global_3d_state_bridge.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  VEHICLE HEALTH DASHBOARD — 3D Diagnostic Bay & Subsystem Inspector
// ─────────────────────────────────────────────────────────────────────────────

class VehicleHealthDashboardScreen extends ConsumerStatefulWidget {
  const VehicleHealthDashboardScreen({super.key});

  @override
  ConsumerState<VehicleHealthDashboardScreen> createState() =>
      _VehicleHealthDashboardScreenState();
}

class _VehicleHealthDashboardScreenState
    extends ConsumerState<VehicleHealthDashboardScreen> {
  int _selectedSubsystemIndex = 0;

  final List<Map<String, dynamic>> _subsystems = [
    {
      'id': 'engine',
      'label': 'Engine & Powertrain',
      'icon': Icons.bolt_rounded,
      'color': RoadOSColors.cyberCyan,
      'status': 'Optimal (99%)',
      'temp': '88 degC',
      'preset': 'engine',
    },
    {
      'id': 'brakes',
      'label': 'Braking & ABS',
      'icon': Icons.album_rounded,
      'color': RoadOSColors.apexEmerald,
      'status': 'Pads 84% | Fluid OK',
      'temp': '42 degC',
      'preset': 'wheels',
    },
    {
      'id': 'battery',
      'label': 'Battery & Charging',
      'icon': Icons.battery_charging_full_rounded,
      'color': RoadOSColors.neonViolet,
      'status': '13.8V | Healthy',
      'temp': '29 degC',
      'preset': 'cockpit',
    },
    {
      'id': 'cooling',
      'label': 'Cooling & Radiator',
      'icon': Icons.thermostat_rounded,
      'color': RoadOSColors.roadCyan,
      'status': 'Flow Normal | 86 degC',
      'temp': '86 degC',
      'preset': 'engine',
    },
    {
      'id': 'exhaust',
      'label': 'Exhaust & Catalyst',
      'icon': Icons.air_rounded,
      'color': RoadOSColors.hyperOrange,
      'status': 'O2 Sensor Clean',
      'temp': '320 degC',
      'preset': 'exhaust',
    },
    {
      'id': 'transmission',
      'label': 'Drive Chain & Clutch',
      'icon': Icons.settings_input_component_rounded,
      'color': RoadOSColors.electricBlue,
      'status': 'Slack 28mm | Clean',
      'temp': '45 degC',
      'preset': 'wheels',
    },
  ];

  @override
  void initState() {
    super.initState();
    VehicleHealthEngine().initialize(ref);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Global3DStateBridge().setCameraPreset('engine');
    });
  }

  void _selectSubsystem(int index) {
    LuxAudioHapticsService.selectionClick();
    setState(() => _selectedSubsystemIndex = index);
    final sub = _subsystems[index];
    Global3DStateBridge().setCameraPreset(sub['preset'] as String);
    Global3DStateBridge().highlightComponent(sub['id'] as String);
  }

  Future<void> _handleClearDtc() async {
    LuxAudioHapticsService.heavyImpact();
    final result = await DiagnosticManager().clearDiagnosticFaults();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: result.isSuccess
            ? RoadOSColors.apexEmerald
            : RoadOSColors.errorCrimson,
        content: Text(
          result.isSuccess
              ? 'ECU fault codes cleared successfully'
              : result.message,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final healthState = ref.watch(vehicleHealthProvider);
    final dtcs = ref.watch(activeDiagnosticsProvider);
    final activeContext = ref.watch(activeVehicleContextProvider);
    final vehicle = activeContext.profile;

    final selectedSub = _subsystems[_selectedSubsystemIndex];

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
        title: const Text(
          '3D VEHICLE HEALTH DIAGNOSTICS',
          style: TextStyle(
            color: RoadOSColors.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 15,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.restart_alt_rounded,
              color: RoadOSColors.cyberCyan,
            ),
            tooltip: 'Clear DTC Faults',
            onPressed: _handleClearDtc,
          ),
        ],
      ),
      body: CinematicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Top Health Score Banner ──────────────────────────────
                _buildHealthScoreBanner(healthState),
                const SizedBox(height: 18),

                // ── 2. Interactive 3D Diagnostic Bay ────────────────────────
                _build3DDiagnosticBay(vehicle, selectedSub),
                const SizedBox(height: 18),

                // ── 3. Subsystem Selector Grid ──────────────────────────────
                const Text(
                  'SUBSYSTEM INSPECTION & CAMERA FOCUS',
                  style: TextStyle(
                    color: RoadOSColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSubsystemGrid(),
                const SizedBox(height: 18),

                // ── 4. Selected Subsystem Detailed Diagnostics Card ─────────
                _buildSubsystemDetailCard(selectedSub),
                const SizedBox(height: 18),

                // ── 5. DTC Fault Code Scanner ───────────────────────────────
                _buildDtcScannerSection(dtcs),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Top Health Score Banner
  Widget _buildHealthScoreBanner(VehicleHealthState health) {
    return RoadOSCard(
      borderColor: RoadOSColors.apexEmerald.withValues(alpha: 0.45),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
              border: Border.all(
                color: RoadOSColors.apexEmerald.withValues(alpha: 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: RoadOSColors.apexEmerald.withValues(alpha: 0.25),
                  blurRadius: 14,
                ),
              ],
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: RoadOSColors.apexEmerald,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OVERALL VEHICLE HEALTH: 98 / 100',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'All major telemetric telemetry nodes operating in optimal parameters.',
                  style: TextStyle(
                    color: RoadOSColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const RoadOSStatusPill(
            label: 'OPTIMAL',
            color: RoadOSColors.apexEmerald,
          ),
        ],
      ),
    );
  }

  /// 3D Diagnostic Bay
  Widget _build3DDiagnosticBay(
    dynamic vehicle,
    Map<String, dynamic> selectedSub,
  ) {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: RoadOSColors.borderTranslucent, width: 1.2),
        gradient: const LinearGradient(
          colors: [Color(0x35101A38), Color(0x1504060C)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            RideOS3DModelViewer(
              vehicleProfile: vehicle,
              cameraOrbit: '45deg 65deg 90%',
              autoRotate: false,
              exposure: 1.15,
            ),
            Positioned(
              top: 14,
              left: 14,
              child: FloatingHudBubble(
                icon: selectedSub['icon'] as IconData,
                label: 'Focused Subsystem',
                value: selectedSub['label'] as String,
                accentColor: selectedSub['color'] as Color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Subsystem Selector Grid
  Widget _buildSubsystemGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(_subsystems.length, (index) {
            final sub = _subsystems[index];
            final isSelected = index == _selectedSubsystemIndex;
            final color = sub['color'] as Color;

            return GestureDetector(
              onTap: () => _selectSubsystem(index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                  child: Container(
                    width: itemWidth,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.18)
                          : const Color(0x25101A38),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : RoadOSColors.borderSubtle,
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.25),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          sub['icon'] as IconData,
                          size: 20,
                          color: isSelected ? color : RoadOSColors.textMuted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sub['label'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : RoadOSColors.textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                sub['status'] as String,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Selected Subsystem Detail Card
  Widget _buildSubsystemDetailCard(Map<String, dynamic> sub) {
    final color = sub['color'] as Color;
    return RoadOSCard(
      borderColor: color.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${sub['label']} Telemetry Breakdown'.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                'TEMP: ${sub['temp']}',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Active live sensor streams verify all hydraulic line pressures, thermal sensors, and Hall effect sensors are within manufacturer tolerances.',
            style: TextStyle(
              color: RoadOSColors.textSecondary.withValues(alpha: 0.9),
              fontSize: 11,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// DTC Fault Code Scanner
  Widget _buildDtcScannerSection(List<DiagnosticItem> dtcs) {
    return RoadOSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ECU DIAGNOSTIC TROUBLE CODES (DTC)',
                style: TextStyle(
                  color: RoadOSColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  '0 ACTIVE FAULTS',
                  style: TextStyle(
                    color: RoadOSColors.apexEmerald,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'No pending or historical OBD-II diagnostic fault codes detected on ISO 15765-4 CAN gateway.',
            style: TextStyle(
              color: RoadOSColors.textMuted,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
