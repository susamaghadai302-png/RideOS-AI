import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/widgets/rideos_3d_model_viewer.dart';
import '../../../../core/bluetooth/bluetooth_engine.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import '../../../../core/vehicle_resolution/services/vehicle_registry.dart';
import '../../../../core/device_providers/services/fleet_telematics_engine.dart';
import '../../../../core/device_providers/models/normalized_telemetry_models.dart';
import '../../../../core/vehicle_resolution/models/digital_twin_model.dart';
import '../../../fleet_analytics/services/fleet_analytics_engine.dart';
import '../../../vehicle_manager/presentation/screens/vehicle_catalog_screen.dart';
import 'vehicle_scanner_screen.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/graphics/global_3d_state_bridge.dart';

enum ShowroomLightingMode {
  studio('Studio Daylight', 1.15, Color(0xFF00F2FE)),
  cyberNight('Cyber Midnight', 0.92, Color(0xFF6366F1)),
  sunsetGlow('Sunset Ambiance', 1.35, Color(0xFFF59E0B));

  final String title;
  final double exposure;
  final Color ambientColor;
  const ShowroomLightingMode(this.title, this.exposure, this.ambientColor);
}

enum ShowroomHotspotType {
  powertrain('Engine & Powertrain', Icons.bolt_rounded, 'High-output liquid-cooled powerplant with ride-by-wire throttle and slipper clutch.'),
  chassis('Chassis & Braking', Icons.album_rounded, 'Radial 4-piston calipers, floating dual discs, lean-sensitive cornering ABS.'),
  cockpit('Smart HUD Cockpit', Icons.speed_rounded, 'Full TFT glass instrument cluster with Bluetooth GATT telemetry bridge.'),
  exhaust('Exhaust & Dynamics', Icons.air_rounded, 'Titanium tuned headers with active exhaust valve and dynamic backpressure tuning.');

  final String label;
  final IconData icon;
  final String description;
  const ShowroomHotspotType(this.label, this.icon, this.description);
}

class LuxuryGarageShowroomScreen extends ConsumerStatefulWidget {
  const LuxuryGarageShowroomScreen({super.key});

  @override
  ConsumerState<LuxuryGarageShowroomScreen> createState() => _LuxuryGarageShowroomScreenState();
}

class _LuxuryGarageShowroomScreenState extends ConsumerState<LuxuryGarageShowroomScreen> {
  final _telematicsEngine = FleetTelematicsEngine();
  final _analyticsEngine = FleetAnalyticsEngine();

  int _selectedVehicleIndex = 0;
  String _activeCameraOrbit = '35deg 75deg 100%';
  ShowroomLightingMode _lightingMode = ShowroomLightingMode.studio;
  bool _autoRotate = false;
  bool _showTelemetricsOverlay = false;
  bool _showHotspots = false;
  bool _isFullscreenShowcase = false;
  ShowroomHotspotType? _selectedHotspot;
  int _selectedColorIndex = 0;

  final List<Color> _paintColors = const [
    Color(0xFF00F2FE), // Cyber Cyan
    Color(0xFF0F172A), // Midnight Obsidian
    Color(0xFFE2E8F0), // Liquid Silver
    Color(0xFF10B981), // Apex Emerald
    Color(0xFFEF4444), // Crimson Pearl
  ];

  @override
  void initState() {
    super.initState();
    BluetoothEngine().initialize(ref);
    
    // Sync selected vehicle index with global active context if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeCtx = ref.read(activeVehicleContextProvider);
      if (activeCtx.profile != null) {
        final allProfiles = VehicleRegistry().verifiedProfiles;
        final idx = allProfiles.indexWhere((p) => p.id == activeCtx.profile!.id);
        if (idx != -1 && mounted) {
          setState(() {
            _selectedVehicleIndex = idx;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final allProfiles = VehicleRegistry().verifiedProfiles;
    final currentVehicle = allProfiles.isNotEmpty && _selectedVehicleIndex < allProfiles.length
        ? allProfiles[_selectedVehicleIndex]
        : VehicleRegistry().defaultProfile;

    final has3d = currentVehicle.has3DModel || currentVehicle.hasDigitalTwin;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Global3DStateBridge().setCameraPreset('garage');
      Global3DStateBridge().loadVehicle(currentVehicle);
      Global3DStateBridge().setLightingMode(_lightingMode == ShowroomLightingMode.cyberNight ? 'cyberpunk' : (_lightingMode == ShowroomLightingMode.sunsetGlow ? 'sunset' : 'studio'));
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CinematicBackground(
        child: Stack(
          children: [
            // 1. Showroom 3D Stage Viewport (Always active with realistic showroom floor & lighting)
            Positioned.fill(
              child: RideOS3DModelViewer(
                key: ValueKey('${currentVehicle.id}_${currentVehicle.model3DUrl}_$_activeCameraOrbit}_${_lightingMode.name}'),
                vehicleProfile: currentVehicle,
                autoRotate: _autoRotate,
                cameraControls: true,
                cameraOrbit: _activeCameraOrbit,
                exposure: _lightingMode.exposure,
                height: double.infinity,
                showPedestalGlow: true,
              ),
            ),

            // Elegant Holographic Scan Pending Banner (Non-blocking HUD)
            if (!has3d && !_isFullscreenShowcase)
              Positioned(
                top: MediaQuery.of(context).padding.top + 60,
                left: 20,
                right: 20,
                child: Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xCC070B18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: RoadOSColors.cyberCyan.withValues(alpha: 0.15),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: RoadOSColors.cyberCyan.withValues(alpha: 0.15),
                              ),
                              child: const Icon(Icons.view_in_ar_rounded, color: RoadOSColors.cyberCyan, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'REAL VEHICLE SCAN REQUIRED',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${currentVehicle.manufacturer.toUpperCase()} ${currentVehicle.model.toUpperCase()} | 3D CAD PENDING',
                                    style: const TextStyle(
                                      color: RoadOSColors.cyberCyan,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () async {
                                final twin = await Navigator.push<DigitalTwinModel>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => VehicleScannerScreen(
                                      vehicleId: currentVehicle.id,
                                      manufacturer: currentVehicle.manufacturer,
                                      modelName: currentVehicle.model,
                                      category: currentVehicle.category,
                                      year: currentVehicle.year,
                                    ),
                                  ),
                                );

                                if (twin != null && mounted) {
                                  final updated = currentVehicle.copyWith(
                                    model3DUrl: twin.modelGlbPath,
                                    thumbnailUrl: twin.thumbnailUrl,
                                    digitalTwinId: twin.twinId,
                                    isUserScannedTwin: true,
                                    scanDate: twin.scanDate,
                                    scanQuality: twin.quality.code,
                                  );
                                  ref.read(activeVehicleContextProvider.notifier).switchVehicle(updated);
                                  setState(() {});
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: RoadOSColors.cyberCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.6)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.camera_alt_rounded, color: RoadOSColors.cyberCyan, size: 13),
                                    SizedBox(width: 4),
                                    Text(
                                      'SCAN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

          // 2. Interactive Vehicle Component Hotspots Layer
          if (has3d && _showHotspots && !_isFullscreenShowcase) ...[
            _buildHotspotNode(0.35, 0.48, ShowroomHotspotType.powertrain),
            _buildHotspotNode(0.22, 0.62, ShowroomHotspotType.chassis),
            _buildHotspotNode(0.48, 0.36, ShowroomHotspotType.cockpit),
            _buildHotspotNode(0.70, 0.58, ShowroomHotspotType.exhaust),
          ],

          // 3. Hotspot Inspector Modal Card (if selected)
          if (_selectedHotspot != null && !_isFullscreenShowcase)
            Positioned(
              left: 24,
              right: 24,
              top: 110,
              child: _buildHotspotInspectorCard(currentVehicle),
            ),

          // 4. Top Header Overlay (Back, Title, Fullscreen Toggle, Catalog)
          if (!_isFullscreenShowcase)
            Positioned(
              top: 50,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RoadOSGradients.liquidWaterGlass,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: RoadOSColors.borderSubtle),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'SMART GARAGE 3D',
                        style: RoadOSTypography.screenTitle.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Fullscreen Showcase Mode Toggle
                      _buildHeaderIconBtn(
                        icon: Icons.fullscreen_rounded,
                        isActive: _isFullscreenShowcase,
                        tooltip: 'Fullscreen Showcase Mode',
                        onTap: () {
                          setState(() => _isFullscreenShowcase = true);
                        },
                      ),
                      const SizedBox(width: 8),
                      // Hotspots Inspection Toggle
                      _buildHeaderIconBtn(
                        icon: Icons.bubble_chart_rounded,
                        isActive: _showHotspots,
                        tooltip: 'Toggle Component Hotspots',
                        onTap: () {
                          setState(() {
                            _showHotspots = !_showHotspots;
                            if (!_showHotspots) _selectedHotspot = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      // Telemetrics HUD Toggle
                      _buildHeaderIconBtn(
                        icon: Icons.speed_rounded,
                        isActive: _showTelemetricsOverlay,
                        tooltip: 'Toggle Live Telemetrics & Health',
                        onTap: () {
                          setState(() => _showTelemetricsOverlay = !_showTelemetricsOverlay);
                        },
                      ),
                      const SizedBox(width: 8),
                      // Catalog Browser
                      _buildHeaderIconBtn(
                        icon: Icons.explore_rounded,
                        isActive: false,
                        tooltip: 'Browse Vehicle Catalog',
                        onTap: () {
                          Navigator.push(
                            context,
                            premiumRoute(const VehicleCatalogScreen()),
                          );
                        },
                      ),
                      const SizedBox(width: 8),
                      // 3D Auto-Rotate Animation Toggle
                      _buildHeaderIconBtn(
                        icon: _autoRotate ? Icons.play_arrow_rounded : Icons.pause_rounded,
                        isActive: _autoRotate,
                        tooltip: 'Toggle 3D Orbit Animation',
                        onTap: () {
                          setState(() => _autoRotate = !_autoRotate);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // 5. Left Vertical Camera & Studio Lighting Control Deck
          if (!_isFullscreenShowcase)
            Positioned(
              left: 20,
              top: 130,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: RoadOSGradients.liquidWaterGlass,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: RoadOSColors.borderSubtle),
                      boxShadow: RoadOSShadows.luxuryCard,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHudIconButton(
                          Icons.threesixty_rounded,
                          'Hero 3/4 View',
                          _activeCameraOrbit == '35deg 75deg 100%',
                          () => setState(() => _activeCameraOrbit = '35deg 75deg 100%'),
                        ),
                        _buildHudIconButton(
                          Icons.arrow_upward_rounded,
                          'Front View',
                          _activeCameraOrbit == '0deg 80deg 95%',
                          () => setState(() => _activeCameraOrbit = '0deg 80deg 95%'),
                        ),
                        _buildHudIconButton(
                          Icons.view_sidebar_rounded,
                          'Side Profile',
                          _activeCameraOrbit == '90deg 85deg 105%',
                          () => setState(() => _activeCameraOrbit = '90deg 85deg 105%'),
                        ),
                        _buildHudIconButton(
                          Icons.arrow_downward_rounded,
                          'Rear View',
                          _activeCameraOrbit == '180deg 80deg 100%',
                          () => setState(() => _activeCameraOrbit = '180deg 80deg 100%'),
                        ),
                        _buildHudIconButton(
                          Icons.flight_takeoff_rounded,
                          'Top Aero View',
                          _activeCameraOrbit == '0deg 15deg 120%',
                          () => setState(() => _activeCameraOrbit = '0deg 15deg 120%'),
                        ),
                        const Divider(color: RoadOSColors.borderTranslucent, height: 12),
                        // Studio Lighting Mode Presets
                        _buildHudIconButton(
                          Icons.wb_sunny_rounded,
                          'Studio Daylight (${_lightingMode.title})',
                          _lightingMode == ShowroomLightingMode.studio,
                          () {
                            setState(() {
                              _lightingMode = _lightingMode == ShowroomLightingMode.studio
                                  ? ShowroomLightingMode.cyberNight
                                  : (_lightingMode == ShowroomLightingMode.cyberNight
                                      ? ShowroomLightingMode.sunsetGlow
                                      : ShowroomLightingMode.studio);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // 6. Floating Telemetry HUD
          if (_showTelemetricsOverlay && !_isFullscreenShowcase)
            Positioned(
              right: 20,
              top: 120,
              width: 230,
              child: StreamBuilder<NormalizedTelemetrySnapshot>(
                stream: _telematicsEngine.telemetryStream,
                initialData: _telematicsEngine.latestSnapshot,
                builder: (context, snapshot) {
                  final tele = snapshot.data ?? _telematicsEngine.latestSnapshot;
                  final summary = _analyticsEngine.getSummary();
                  final isSimulated = tele?.dataSource == TelemetryDataSource.simulated;

                  return LiquidGlassCard(
                    padding: const EdgeInsets.all(14),
                    borderRadius: 18,
                    blurSigma: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'TELEMETRY HUD',
                              style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isSimulated ? 'SIM' : 'LIVE',
                                style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 8, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildTelemetricRow('RPM', '${tele?.engineRpm.value?.round() ?? 0} rpm', RoadOSColors.hyperOrange),
                        _buildTelemetricRow('SPEED', '${tele?.vehicleSpeedKmh.value?.toStringAsFixed(0) ?? "0"} km/h', RoadOSColors.cyberCyan),
                        _buildTelemetricRow('COOLANT', '${tele?.coolantTempC.value?.toStringAsFixed(0) ?? "--"}  degC', RoadOSColors.warningAmber),
                        _buildTelemetricRow('BATTERY', '${tele?.batteryVoltage.value?.toStringAsFixed(1) ?? "12.6"} V', RoadOSColors.apexEmerald),
                        _buildTelemetricRow('LEAN ANGLE', '${tele?.leanAngleDeg.value?.toStringAsFixed(1) ?? "0.0"} deg', Colors.white),
                        const Divider(color: RoadOSColors.borderTranslucent, height: 16),
                        const Text('NEXT SERVICE DUE', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 2),
                        Text(
                          summary.maintenanceRecords.isNotEmpty
                              ? '${summary.maintenanceRecords.first.taskType} at ${summary.maintenanceRecords.first.nextDueKm} km'
                              : 'All systems optimal',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

          // 7. Fullscreen Exit Floating Button
          if (_isFullscreenShowcase)
            Positioned(
              top: 40,
              right: 24,
              child: LiquidGlassButton(
                label: 'EXIT SHOWCASE',
                icon: Icons.fullscreen_exit_rounded,
                height: 42,
                onPressed: () => setState(() => _isFullscreenShowcase = false),
              ),
            ),

          // 8. Bottom Floating Specs Drawer & Model Carousel
          if (!_isFullscreenShowcase)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Vehicle Specs Bar
                  LiquidGlassCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    borderRadius: 20,
                    blurSigma: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentVehicle.fullName.toUpperCase(),
                                  style: RoadOSTypography.cardTitle.copyWith(fontSize: 15, letterSpacing: 1.2),
                                ),
                                if (currentVehicle.isUserScannedTwin) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    '3D DIGITAL TWIN | ${currentVehicle.scanQuality ?? "HIGH"} QUALITY',
                                    style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.8),
                                  ),
                                ],
                              ],
                            ),
                            Row(
                              children: [
                                // Paint Color Swatches
                                ...List.generate(_paintColors.length, (idx) {
                                  final isColorSel = idx == _selectedColorIndex;
                                  return GestureDetector(
                                    onTap: () {
                                      LuxAudioHapticsService.lightImpact();
                                      setState(() => _selectedColorIndex = idx);
                                    },
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      margin: const EdgeInsets.symmetric(horizontal: 3),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _paintColors[idx],
                                        border: Border.all(
                                          color: isColorSel ? Colors.white : Colors.transparent,
                                          width: 1.8,
                                        ),
                                        boxShadow: isColorSel
                                            ? [
                                                BoxShadow(
                                                  color: _paintColors[idx].withValues(alpha: 0.6),
                                                  blurRadius: 6,
                                                )
                                              ]
                                            : null,
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: RoadOSColors.midnightNavy.withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.5)),
                                  ),
                                  child: const Text(
                                    'SMART 3D GARAGE',
                                    style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 8.5, fontWeight: FontWeight.w900, letterSpacing: 1),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSpecMetric('${currentVehicle.displacementCc ?? 998} cc', 'ENGINE'),
                            _buildSpecMetric('${currentVehicle.powerBhp?.round() ?? 200} HP', 'POWER'),
                            _buildSpecMetric('${currentVehicle.curbWeightKg?.round() ?? 199} kg', 'WEIGHT'),
                            _buildSpecMetric('${currentVehicle.topSpeedKmh ?? 320} km/h', 'TOP SPEED'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // "SELECT MODEL" Carousel
                  Text('SELECT MODEL', style: RoadOSTypography.sectionHeader),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 72,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: allProfiles.length,
                      itemBuilder: (context, index) {
                        final v = allProfiles[index];
                        final isSelected = index == _selectedVehicleIndex;

                        return LiquidGlassCard(
                          margin: const EdgeInsets.only(right: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          borderRadius: 14,
                          blurSigma: 18,
                          onTap: () {
                            setState(() => _selectedVehicleIndex = index);
                            ref.read(activeVehicleContextProvider.notifier).switchVehicle(v);
                          },
                          child: SizedBox(
                            width: 120,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.two_wheeler_rounded,
                                      size: 16,
                                      color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.textMuted,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        v.manufacturer.toUpperCase(),
                                        style: TextStyle(
                                          color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.textMuted,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  v.model.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.6,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      ),
    );
  }

  Widget _buildHeaderIconBtn({
    required IconData icon,
    required bool isActive,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            gradient: isActive
                ? const LinearGradient(colors: [Color(0x4500F2FE), Color(0x200066FF)])
                : RoadOSGradients.liquidWaterGlass,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive ? RoadOSColors.cyberCyan : RoadOSColors.borderSubtle,
            ),
          ),
          child: IconButton(
            icon: Icon(
              icon,
              color: isActive ? RoadOSColors.cyberCyan : RoadOSColors.textSecondary,
              size: 20,
            ),
            tooltip: tooltip,
            onPressed: () {
              LuxAudioHapticsService.lightImpact();
              onTap();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHudIconButton(IconData icon, String tooltip, bool isActive, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: () {
          LuxAudioHapticsService.lightImpact();
          onTap();
        },
        child: Container(
          width: 38,
          height: 38,
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? RoadOSColors.neonViolet.withValues(alpha: 0.25) : Colors.transparent,
            border: isActive ? Border.all(color: RoadOSColors.neonViolet, width: 1.5) : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? RoadOSColors.cyberCyan : Colors.white70,
          ),
        ),
      ),
    );
  }

  Widget _buildHotspotNode(double leftFraction, double topFraction, ShowroomHotspotType type) {
    final isSel = _selectedHotspot == type;

    return Align(
      alignment: FractionalOffset(leftFraction, topFraction),
      child: GestureDetector(
        onTap: () {
          LuxAudioHapticsService.selectionClick();
          setState(() {
            _selectedHotspot = isSel ? null : type;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isSel ? RoadOSColors.cyberCyan : Colors.black).withValues(alpha: 0.65),
            border: Border.all(
              color: isSel ? Colors.white : RoadOSColors.cyberCyan,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: RoadOSColors.cyberCyan.withValues(alpha: 0.4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Icon(
            type.icon,
            size: 16,
            color: isSel ? Colors.black : RoadOSColors.cyberCyan,
          ),
        ),
      ),
    );
  }

  Widget _buildHotspotInspectorCard(dynamic vehicle) {
    return LiquidGlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 18,
      blurSigma: 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: RoadOSColors.cyberCyan.withValues(alpha: 0.15),
              border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.5)),
            ),
            child: Icon(_selectedHotspot!.icon, color: RoadOSColors.cyberCyan, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _selectedHotspot!.label.toUpperCase(),
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.8),
                ),
                const SizedBox(height: 4),
                Text(
                  _selectedHotspot!.description,
                  style: GoogleFonts.inter(color: RoadOSColors.textSecondary, fontSize: 11.5, height: 1.35),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: RoadOSColors.textMuted, size: 18),
            onPressed: () => setState(() => _selectedHotspot = null),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetricRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
          Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildSpecMetric(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: RoadOSTypography.metricValue.copyWith(fontSize: 14)),
        const SizedBox(height: 2),
        Text(label, style: RoadOSTypography.metricLabel.copyWith(fontSize: 9)),
      ],
    );
  }
}
