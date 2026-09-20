import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../sos_safety/presentation/bloc/sos_bloc.dart';
import '../../../sos_safety/presentation/bloc/sos_event.dart';
import '../../../sos_safety/presentation/widgets/sos_countdown_modal.dart';
import '../../core/services/rider_safety_ai_engine.dart';
import '../../../../core/graphics/global_3d_state_bridge.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  RIDER SAFETY CENTER — Real-Time Safety Command Center & AI Copilot
// ─────────────────────────────────────────────────────────────────────────────

class RiderSafetyCenterScreen extends StatefulWidget {
  const RiderSafetyCenterScreen({super.key});

  @override
  State<RiderSafetyCenterScreen> createState() =>
      _RiderSafetyCenterScreenState();
}

class _RiderSafetyCenterScreenState extends State<RiderSafetyCenterScreen> {
  final RiderSafetyAiEngine safetyEngine = RiderSafetyAiEngine();
  final double simulatedSpeed = 84.0;
  final double _simulatedLeanAngle = 28.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Global3DStateBridge().setCameraPreset('home');
    });
  }

  void _triggerEmergencySos() {
    LuxAudioHapticsService.dangerAlert();
    Future<void>.delayed(const Duration(milliseconds: 120))
        .then((_) => LuxAudioHapticsService.alertVibrate());
    context.read<SosBloc>().add(
          const TriggerSosEvent(
            lat: 28.6139,
            lng: 77.2090,
            triggerType: 'MANUAL',
          ),
        );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SosCountdownModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          'RIDER SAFETY COMMAND CENTER',
          style: TextStyle(
            color: RoadOSColors.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 15,
          ),
        ),
        centerTitle: true,
      ),
      body: CinematicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Top Safety Score & Shield Header ───────────────────────
                _buildSafetyScoreHeader(),
                const SizedBox(height: 18),

                // ── 2. Live Lean Angle & Hazard Radar Stage ───────────────────
                _buildHazardRadarStage(),
                const SizedBox(height: 18),

                // ── 3. Active Safety Alerts Deck ──────────────────────────────
                const Text(
                  'ACTIVE ROUTE HAZARDS & ADVISORIES',
                  style: TextStyle(
                    color: RoadOSColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildHazardAlertsList(),
                const SizedBox(height: 18),

                // ── 4. Emergency SOS Trigger Button ───────────────────────────
                _buildEmergencySosButton(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSafetyScoreHeader() {
    return RoadOSCard(
      borderColor: RoadOSColors.apexEmerald.withValues(alpha: 0.5),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: RoadOSColors.apexEmerald.withValues(alpha: 0.18),
              border: Border.all(
                color: RoadOSColors.apexEmerald.withValues(alpha: 0.7),
                width: 1.5,
              ),
            ),
            child: const Icon(
              Icons.shield_rounded,
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
                  'RIDER SAFETY SCORE: 98 / 100',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'AI Collision Prevention Active | Emergency Telematics Online',
                  style: TextStyle(
                    color: RoadOSColors.apexEmerald,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHazardRadarStage() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RoadOSColors.borderTranslucent, width: 1.2),
        gradient: const LinearGradient(
          colors: [Color(0x35101A38), Color(0x18060C1C)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'ACTIVE LEAN ANGLE TELEMETRY',
                      style: TextStyle(
                        color: RoadOSColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_simulatedLeanAngle.round()} deg LEAN',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: RoadOSColors.cyberCyan,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Cornering grip equilibrium within 92% safety envelope.',
                      style: TextStyle(
                        color: RoadOSColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: RoadOSColors.cyberCyan.withValues(alpha: 0.1),
                  border: Border.all(
                    color: RoadOSColors.cyberCyan.withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.two_wheeler_rounded,
                    color: RoadOSColors.cyberCyan,
                    size: 42,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHazardAlertsList() {
    return Column(
      children: [
        _buildAlertItem(
          'Sharp Curve Ahead (200m)',
          'Recommended approach speed: 45 km/h.',
          Icons.turn_sharp_right_rounded,
          RoadOSColors.warningAmber,
        ),
        const SizedBox(height: 10),
        _buildAlertItem(
          'High Risk Intersection Zone',
          'Heavy cross-traffic reported on Ring Road.',
          Icons.traffic_rounded,
          RoadOSColors.cyberCyan,
        ),
      ],
    );
  }

  Widget _buildAlertItem(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0x20101A38),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: RoadOSColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencySosButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFF2244),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          shadowColor: const Color(0xFFFF2244).withValues(alpha: 0.5),
          elevation: 12,
        ),
        onPressed: _triggerEmergencySos,
        icon: const Icon(Icons.sos_rounded, size: 24),
        label: const Text(
          'TRIGGER EMERGENCY SOS BEACON',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
