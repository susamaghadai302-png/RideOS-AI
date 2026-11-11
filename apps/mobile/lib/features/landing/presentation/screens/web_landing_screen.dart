import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/network/api_config.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/dialogs/backend_diagnostics_dialog.dart';

class WebLandingScreen extends StatefulWidget {
  const WebLandingScreen({super.key});

  @override
  State<WebLandingScreen> createState() => _WebLandingScreenState();
}

class _WebLandingScreenState extends State<WebLandingScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _pulseController;
  Timer? _healthTimer;
  HealthCheckResult? _healthStatus;
  bool _isCheckingHealth = false;

  // Simulator State
  double _simSpeed = 74.0;
  int _simRpm = 6400;
  int _simGear = 4;
  double _simLeanAngle = 18.5;
  String _selectedSimMode = 'Sport';

  final GlobalKey _featuresKey = GlobalKey();
  final GlobalKey _cockpitKey = GlobalKey();
  final GlobalKey _safetyKey = GlobalKey();
  final GlobalKey _techKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _checkBackendHealth();
    _healthTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _checkBackendHealth();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    _healthTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkBackendHealth() async {
    if (_isCheckingHealth) return;
    setState(() => _isCheckingHealth = true);
    try {
      final res = await ApiConfig.testHealth(ApiConfig.activeBaseUrl);
      if (mounted) {
        setState(() {
          _healthStatus = res;
          _isCheckingHealth = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isCheckingHealth = false);
      }
    }
  }

  void _scrollTo(GlobalKey key) {
    LuxAudioHapticsService.selectionClick();
    final context = key.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _setSimMode(String mode) {
    LuxAudioHapticsService.lightImpact();
    setState(() {
      _selectedSimMode = mode;
      switch (mode) {
        case 'Rain':
          _simSpeed = 48.0;
          _simRpm = 4200;
          _simGear = 3;
          _simLeanAngle = 8.0;
          break;
        case 'Cruising':
          _simSpeed = 62.0;
          _simRpm = 5100;
          _simGear = 5;
          _simLeanAngle = 12.0;
          break;
        case 'Sport':
        default:
          _simSpeed = 86.0;
          _simRpm = 7800;
          _simGear = 4;
          _simLeanAngle = 28.5;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 640 && screenWidth < 1024;

    return Scaffold(
      backgroundColor: const Color(0xFF03050A),
      body: CinematicBackground(
        child: Stack(
          children: [
            // Scrollable Content
            Positioned.fill(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 74), // Space for fixed top navbar
                    _buildHeroSection(context, isDesktop: isDesktop, isTablet: isTablet),
                    const SizedBox(height: 48),
                    _buildInteractiveCockpitSection(context, isDesktop: isDesktop),
                    const SizedBox(height: 64),
                    _buildFeaturesSection(context, isDesktop: isDesktop, isTablet: isTablet),
                    const SizedBox(height: 64),
                    _buildSafetySection(context, isDesktop: isDesktop, isTablet: isTablet),
                    const SizedBox(height: 64),
                    _buildTechArchitectureSection(context, isDesktop: isDesktop),
                    const SizedBox(height: 64),
                    _buildCallToActionBanner(context),
                    const SizedBox(height: 64),
                    _buildFooter(context, isDesktop: isDesktop),
                  ],
                ),
              ),
            ),

            // Top Glassmorphic Navigation Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildTopNavbar(context, isDesktop: isDesktop),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TOP NAVBAR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTopNavbar(BuildContext context, {required bool isDesktop}) {
    final screenWidth = MediaQuery.of(context).size.width;
    final showNavLinks = screenWidth >= 1100;

    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xCC050814),
        border: const Border(
          bottom: BorderSide(color: Color(0x3300F2FE), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo & Brand
          const SizedBox(
            width: 175,
            child: RoadOSLogo(size: 26, showWordmark: true),
          ),
          const SizedBox(width: 10),

          // Live Backend Status Pill
          if (screenWidth >= 600)
            _buildBackendStatusPill(context),

          const Spacer(),

          // Desktop Navigation Links
          if (showNavLinks) ...[
            _buildNavLink('Cockpit', () => _scrollTo(_cockpitKey)),
            _buildNavLink('Features', () => _scrollTo(_featuresKey)),
            _buildNavLink('Safety', () => _scrollTo(_safetyKey)),
            _buildNavLink('Architecture', () => _scrollTo(_techKey)),
            const SizedBox(width: 8),
          ],

          // Auth / Launch Actions
          BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              final isAuthenticated = state is AuthenticatedState;
              if (isAuthenticated) {
                return RoadOSButton(
                  isFullWidth: false,
                  width: 140,
                  label: 'Open Cockpit',
                  icon: Icons.dashboard_rounded,
                  height: 38,
                  gradient: RoadOSGradients.anodizedCyan,
                  onPressed: () {
                    LuxAudioHapticsService.selectionClick();
                    Navigator.of(context).pushNamed(AppRouter.dashboard);
                  },
                );
              }

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () {
                      LuxAudioHapticsService.selectionClick();
                      Navigator.of(context).pushNamed(AppRouter.login);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        color: RoadOSColors.cyberCyan,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RoadOSButton(
                    isFullWidth: false,
                    width: 135,
                    label: isDesktop ? 'Launch Cockpit' : 'Start',
                    icon: Icons.speed_rounded,
                    height: 38,
                    gradient: RoadOSGradients.primaryViolet,
                    onPressed: () {
                      LuxAudioHapticsService.selectionClick();
                      Navigator.of(context).pushNamed(AppRouter.login);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Text(
          label,
          style: const TextStyle(
            color: RoadOSColors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildBackendStatusPill(BuildContext context) {
    final isOnline = _healthStatus?.isReachable ?? false;
    final statusColor = isOnline ? RoadOSColors.apexEmerald : RoadOSColors.hyperOrange;
    final label = isOnline
        ? 'Online (${_healthStatus?.latencyMs ?? 0}ms)'
        : (_isCheckingHealth ? 'Pinging...' : 'Offline');

    return InkWell(
      onTap: () {
        LuxAudioHapticsService.lightImpact();
        showDialog(
          context: context,
          builder: (context) => const BackendDiagnosticsDialog(),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: statusColor.withValues(alpha: 0.4), width: 1.0),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: statusColor.withValues(alpha: 0.6), blurRadius: 4),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // HERO SECTION
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildHeroSection(
    BuildContext context, {
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1200),
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 20,
        vertical: isDesktop ? 48 : 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Version badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: RoadOSColors.cyberCyan.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.35), width: 1.0),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.two_wheeler_rounded, color: RoadOSColors.cyberCyan, size: 16),
                SizedBox(width: 8),
                Text(
                  'ENTERPRISE CONNECTED COCKPIT • PRODUCTION v2.4.0',
                  style: TextStyle(
                    color: RoadOSColors.cyberCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Main Headline
          Text(
            'The Connected Motorcycle Operating System',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 46 : (isTablet ? 36 : 28),
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 16),

          // Subheadline
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 780),
            child: Text(
              'Real-time ECU Telemetry, Two-Wheeler Turn-by-Turn 3D Navigation, AI Edge Co-Pilot, and Smart Helmet Mesh Connectivity — Engineered for Next-Gen Riders.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isDesktop ? 16 : 14,
                color: const Color(0xFF94A3B8),
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // CTA Action Buttons
          Wrap(
            spacing: 14,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              RoadOSButton(
                isFullWidth: false,
                width: 220,
                label: 'Launch Web Cockpit',
                icon: Icons.rocket_launch_rounded,
                height: 48,
                gradient: RoadOSGradients.primaryViolet,
                onPressed: () {
                  LuxAudioHapticsService.selectionClick();
                  final state = context.read<AuthBloc>().state;
                  if (state is AuthenticatedState) {
                    Navigator.of(context).pushNamed(AppRouter.dashboard);
                  } else {
                    Navigator.of(context).pushNamed(AppRouter.login);
                  }
                },
              ),
              OutlinedButton.icon(
                onPressed: () {
                  LuxAudioHapticsService.selectionClick();
                  Navigator.of(context).pushNamed(AppRouter.register);
                },
                icon: const Icon(Icons.person_add_rounded, color: Colors.white, size: 18),
                label: const Text(
                  'Create Free Account',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(180, 48),
                  side: const BorderSide(color: Color(0x6600F2FE), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  backgroundColor: const Color(0x1A00F2FE),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  LuxAudioHapticsService.lightImpact();
                  showDialog(
                    context: context,
                    builder: (context) => const BackendDiagnosticsDialog(),
                  );
                },
                icon: const Icon(Icons.network_check_rounded, color: RoadOSColors.cyberCyan, size: 18),
                label: const Text(
                  'Network Diagnostics',
                  style: TextStyle(color: RoadOSColors.cyberCyan, fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(180, 48),
                  side: const BorderSide(color: Color(0x4400F2FE), width: 1.0),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // INTERACTIVE COCKPIT SIMULATOR
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildInteractiveCockpitSection(BuildContext context, {required bool isDesktop}) {
    return Container(
      key: _cockpitKey,
      constraints: const BoxConstraints(maxWidth: 1100),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF070B19),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x4400F2FE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F2FE).withValues(alpha: 0.12),
            blurRadius: 36,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with simulator badge & mode switcher
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.speed_rounded, color: RoadOSColors.cyberCyan, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'LIVE COCKPIT TELEMETRY SIMULATOR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              // Simulator Mode Switcher
              Row(
                mainAxisSize: MainAxisSize.min,
                children: ['Cruising', 'Sport', 'Rain'].map((mode) {
                  final isSelected = _selectedSimMode == mode;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: ChoiceChip(
                      label: Text(mode),
                      selected: isSelected,
                      selectedColor: RoadOSColors.cyberCyan.withValues(alpha: 0.25),
                      backgroundColor: const Color(0xFF0F172A),
                      labelStyle: TextStyle(
                        color: isSelected ? RoadOSColors.cyberCyan : const Color(0xFF94A3B8),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: isSelected ? RoadOSColors.cyberCyan : Colors.transparent,
                        width: 1.0,
                      ),
                      onSelected: (_) => _setSimMode(mode),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Main Digital Instrument Cluster
          isDesktop
              ? Row(
                  children: [
                    Expanded(flex: 3, child: _buildSpeedometerCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 2, child: _buildLeanAngleCard()),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _buildEcuTelemetryCard()),
                  ],
                )
              : Column(
                  children: [
                    _buildSpeedometerCard(),
                    const SizedBox(height: 16),
                    _buildLeanAngleCard(),
                    const SizedBox(height: 16),
                    _buildEcuTelemetryCard(),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildSpeedometerCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x3300F2FE), width: 1.0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('SPEED', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: RoadOSColors.cyberCyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('GEAR $_simGear', style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 11, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _simSpeed.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1.0,
            ),
          ),
          const Text('KM / H', style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          // RPM Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (_simRpm / 12000).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: const Color(0xFF1E293B),
              valueColor: AlwaysStoppedAnimation(
                _simRpm > 9000 ? RoadOSColors.errorCrimson : RoadOSColors.hyperOrange,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0 RPM', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
              Text('$_simRpm RPM', style: const TextStyle(color: RoadOSColors.hyperOrange, fontSize: 10, fontWeight: FontWeight.bold)),
              const Text('12K REDLINE', style: TextStyle(color: Color(0xFF64748B), fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLeanAngleCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x3300F2FE), width: 1.0),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('LEAN ANGLE', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
              Icon(Icons.rotate_right_rounded, color: RoadOSColors.neonViolet, size: 16),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '${_simLeanAngle.toStringAsFixed(1)}°',
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.w900,
              color: RoadOSColors.neonViolet,
            ),
          ),
          const Text('CORNERING LOAD', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RoadOSColors.apexEmerald.withValues(alpha: 0.4), width: 0.8),
            ),
            child: const Text('TIRE GRIP: 94% OPTIMAL', style: TextStyle(color: RoadOSColors.apexEmerald, fontSize: 10, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Widget _buildEcuTelemetryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x3300F2FE), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ECU TELEMETRY (ELM327)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildEcuMetricRow('Battery Voltage', '14.2 V', RoadOSColors.apexEmerald, Icons.battery_charging_full_rounded),
          const Divider(color: Color(0x22FFFFFF), height: 16),
          _buildEcuMetricRow('Coolant Temp', '88 °C', RoadOSColors.hyperOrange, Icons.thermostat_rounded),
          const Divider(color: Color(0x22FFFFFF), height: 16),
          _buildEcuMetricRow('Throttle Position', '42 %', RoadOSColors.cyberCyan, Icons.tune_rounded),
          const Divider(color: Color(0x22FFFFFF), height: 16),
          _buildEcuMetricRow('DTC Fault Codes', '0 Active', RoadOSColors.apexEmerald, Icons.check_circle_rounded),
        ],
      ),
    );
  }

  Widget _buildEcuMetricRow(String label, String value, Color color, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12)),
        const Spacer(),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
      ],
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FEATURES GRID
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFeaturesSection(
    BuildContext context, {
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Container(
      key: _featuresKey,
      constraints: const BoxConstraints(maxWidth: 1200),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          const Text(
            'ENGINEERED FOR TWO WHEELS',
            style: TextStyle(
              color: RoadOSColors.cyberCyan,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete Connected Cockpit Capabilities',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isDesktop ? 32 : 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 36),

          // Feature Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);
              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 18,
                crossAxisSpacing: 18,
                childAspectRatio: isDesktop ? 1.35 : 1.5,
                children: [
                  _buildFeatureCard(
                    icon: Icons.navigation_rounded,
                    title: 'Two-Wheeler 3D Navigation',
                    description: 'Google Routes API v2 motorcycle engine using TWO_WHEELER mode, motorcycle-safe roads, 3D perspective camera, and offline vector replay.',
                    accent: RoadOSColors.cyberCyan,
                    route: AppRouter.navigation,
                  ),
                  _buildFeatureCard(
                    icon: Icons.bluetooth_audio_rounded,
                    title: 'Real-Time OBD-II Diagnostics',
                    description: 'Direct ELM327 Bluetooth/BLE protocol integration, live RPM, speed, coolant, throttle position, and real-time DTC fault code scanning.',
                    accent: RoadOSColors.hyperOrange,
                    route: AppRouter.diagnostics,
                  ),
                  _buildFeatureCard(
                    icon: Icons.psychology_rounded,
                    title: 'AI Co-Pilot & Voice Assistant',
                    description: 'Intelligent on-device edge NLP, hands-free conversational queries, contextual vehicle maintenance diagnosis, and speech synthesis.',
                    accent: RoadOSColors.neonViolet,
                    route: AppRouter.aiAssistant,
                  ),
                  _buildFeatureCard(
                    icon: Icons.groups_rounded,
                    title: 'Squad Ride Mesh Network',
                    description: 'Real-time group GPS location sharing, proximity radar, low-latency rider intercom audio, and instant road hazard warnings.',
                    accent: RoadOSColors.cyberCyan,
                    route: AppRouter.squad,
                  ),
                  _buildFeatureCard(
                    icon: Icons.shield_rounded,
                    title: '360° Safety & Crash SOS',
                    description: 'Autonomous multi-axis gyroscope impact detection, 30s emergency cancellation countdown, and automated cellular SOS dispatch.',
                    accent: const Color(0xFFFF4444),
                    route: AppRouter.safety,
                  ),
                  _buildFeatureCard(
                    icon: Icons.view_in_ar_rounded,
                    title: '3D Garage & Digital Vault',
                    description: 'Multi-vehicle profile showroom, maintenance schedules, tire health tracking, and encrypted document storage vault.',
                    accent: RoadOSColors.electricBlue,
                    route: AppRouter.garage,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color accent,
    required String route,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF090E22),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF94A3B8),
                height: 1.45,
              ),
            ),
          ),
          InkWell(
            onTap: () {
              LuxAudioHapticsService.selectionClick();
              Navigator.of(context).pushNamed(route);
            },
            borderRadius: BorderRadius.circular(6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Explore Module',
                  style: TextStyle(
                    color: accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward_rounded, color: accent, size: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // SAFETY SECTION
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildSafetySection(
    BuildContext context, {
    required bool isDesktop,
    required bool isTablet,
  }) {
    return Container(
      key: _safetyKey,
      constraints: const BoxConstraints(maxWidth: 1100),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF140810),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x55FF4444), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4444).withValues(alpha: 0.08),
            blurRadius: 32,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xFFFF4444), size: 24),
              SizedBox(width: 10),
              Text(
                '360° RIDER SAFETY & CRASH DETECTION',
                style: TextStyle(
                  color: Color(0xFFFF4444),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Autonomous High-G Fall Detection & Emergency SOS',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Using multi-axis gyroscope and accelerometer sensor fusion, RideOS continuously monitors for high-G deceleration and violent lateral tilt. If a severe crash is identified, the app triggers a 30-second audible cancellation countdown before dispatching SMS alerts and exact GPS coordinates to designated emergency contacts.',
            style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1), height: 1.5),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: [
              _buildSafetyBadge('Multi-Axis Sensor Fusion'),
              _buildSafetyBadge('30s False-Alarm Countdown'),
              _buildSafetyBadge('Automated GPS Location Dispatch'),
              _buildSafetyBadge('Cellular SMS / Twilio Fallback'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0x33FF4444),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x66FF4444), width: 0.9),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Color(0xFFFF8888), fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // TECH ARCHITECTURE SECTION
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildTechArchitectureSection(BuildContext context, {required bool isDesktop}) {
    return Container(
      key: _techKey,
      constraints: const BoxConstraints(maxWidth: 1100),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF070B18),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x3300F2FE), width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENTERPRISE ARCHITECTURE',
            style: TextStyle(
              color: RoadOSColors.cyberCyan,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Zero-Trust Microservices & Resilient Edge Architecture',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildArchBlock('Frontend Engine', 'Flutter WebAssembly & Android Native with Riverpod + BLoC state management and offline SQLite cache.', Icons.devices_rounded),
              _buildArchBlock('Backend Core', 'NestJS Enterprise Microservices with non-blocking Mongoose, TimescaleDB time-series, and Redis session broker.', Icons.dns_rounded),
              _buildArchBlock('Security & Auth', 'Zero-Trust JWT authentication with strict rider data isolation, Bcrypt encryption, and GDPR right-to-be-forgotten.', Icons.lock_rounded),
              _buildArchBlock('Vehicle Protocols', 'ELM327 OBD-II CAN-Bus diagnostics, BLE 5.2 Smart Helmet HUD streaming, and dual-mode USB/LAN bridge.', Icons.hub_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildArchBlock(String title, String desc, IconData icon) {
    return Container(
      width: 480,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x22FFFFFF), width: 1.0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RoadOSColors.cyberCyan.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: RoadOSColors.cyberCyan, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // CALL TO ACTION
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildCallToActionBanner(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 1000),
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E1065), Color(0xFF0C4A6E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0x6600F2FE), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00F2FE).withValues(alpha: 0.15),
            blurRadius: 36,
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Ready to Experience the Future of Two-Wheeler Intelligence?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Connect your motorcycle via Bluetooth or explore the cloud cockpit right from your web browser.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Color(0xFFE2E8F0)),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              RoadOSButton(
                isFullWidth: false,
                width: 200,
                label: 'Sign In to Cockpit',
                icon: Icons.login_rounded,
                height: 48,
                gradient: RoadOSGradients.anodizedCyan,
                onPressed: () {
                  LuxAudioHapticsService.selectionClick();
                  Navigator.of(context).pushNamed(AppRouter.login);
                },
              ),
              OutlinedButton(
                onPressed: () {
                  LuxAudioHapticsService.selectionClick();
                  Navigator.of(context).pushNamed(AppRouter.register);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(160, 48),
                  side: const BorderSide(color: Colors.white, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Create Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // FOOTER
  // ───────────────────────────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context, {required bool isDesktop}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF020408),
        border: Border(top: BorderSide(color: Color(0x2200F2FE), width: 1.0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const RoadOSLogo(size: 24, showWordmark: true),
              Wrap(
                spacing: 16,
                children: [
                  _buildFooterLink('Privacy Policy', () => _showLegalDialog(context, 'Privacy Policy', 'RideOS AI respects rider data privacy. High-precision GPS is used solely for navigation and crash verification. Telemetry data is account-isolated and never sold to third parties.')),
                  _buildFooterLink('Terms of Service', () => _showLegalDialog(context, 'Terms of Service', 'RideOS AI is designed for motorcycle and two-wheeler intelligence. Riders must exercise independent caution and adhere to local traffic regulations.')),
                  _buildFooterLink('Diagnostics', () {
                    showDialog(context: context, builder: (_) => const BackendDiagnosticsDialog());
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: Color(0x14FFFFFF)),
          const SizedBox(height: 12),
          const Text(
            'RideOS AI Enterprise Connected Cockpit • Production v2.4.0 • Built for Next-Gen Two-Wheelers.',
            style: TextStyle(color: Color(0xFF64748B), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Text(
        label,
        style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  void _showLegalDialog(BuildContext context, String title, String content) {
    LuxAudioHapticsService.lightImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0B132B),
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 13, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: RoadOSColors.cyberCyan)),
          ),
        ],
      ),
    );
  }
}
