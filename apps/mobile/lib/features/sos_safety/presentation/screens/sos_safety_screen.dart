import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../crash_detection/core/services/crash_detection_engine.dart';
import '../../../obd_tpms/presentation/widgets/connected_platform_widgets.dart';
import '../../../../core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

class SosSafetyScreen extends StatefulWidget {
  const SosSafetyScreen({super.key});

  @override
  State<SosSafetyScreen> createState() => _SosSafetyScreenState();
}

class _SosSafetyScreenState extends State<SosSafetyScreen> {
  final CrashDetectionEngine _crashEngine = CrashDetectionEngine();
  bool _showCountdownOverlay = false;

  void _triggerSimulatedCrash() {
    LuxAudioHapticsService.alertVibrate();
    _crashEngine.triggerSimulatedImpact(forceG: 7.4);
    setState(() => _showCountdownOverlay = true);
  }

  @override
  void dispose() {
    _crashEngine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EMERGENCY SOS & CRASH GUARD',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: RoadOSColors.errorCrimson, letterSpacing: -0.5),
            ),
            Row(
              children: [
                Icon(Icons.sensors_rounded, color: RoadOSColors.apexEmerald, size: 12),
                SizedBox(width: 4),
                Text(
                  '6-Axis IMU & Satellite Telematics Monitoring',
                  style: TextStyle(fontSize: 9, color: RoadOSColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: LuxResponsiveContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_showCountdownOverlay) ...[
                  CrashDetectionOverlayWidget(
                    engine: _crashEngine,
                    onCancel: () {
                      setState(() => _showCountdownOverlay = false);
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Emergency SOS Panic Panel
                const EmergencySosPanelWidget(),
                const SizedBox(height: 16),

                // Crash Test Simulation Button
                RoadOSCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SIMULATE ACCELEROMETER IMPACT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                          Text('Tests 30-sec emergency countdown & contacts alert', style: TextStyle(fontSize: 9, color: RoadOSColors.textMuted)),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _triggerSimulatedCrash,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: RoadOSColors.errorCrimson.withValues(alpha: 0.2),
                          foregroundColor: RoadOSColors.errorCrimson,
                          side: const BorderSide(color: RoadOSColors.errorCrimson),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        ),
                        child: const Text('TEST IMPACT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ICE Medical Profile Card
                RoadOSCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.medical_services_rounded, color: RoadOSColors.hyperOrange, size: 20),
                              SizedBox(width: 8),
                              Text('ICE MEDICAL PROFILE CARD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                            ],
                          ),
                          Text('Blood Group Not configured', style: TextStyle(fontSize: 10, color: RoadOSColors.hyperOrange, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildMedicalRow('RIDER NAME', 'Not configured'),
                      const Divider(color: Color(0xFF334155), height: 12),
                      _buildMedicalRow('ALLERGIES', 'Not configured'),
                      const Divider(color: Color(0xFF334155), height: 12),
                      _buildMedicalRow('PRIMARY ICE CONTACT', 'Not configured'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 9, color: RoadOSColors.textMuted, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 11, color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
