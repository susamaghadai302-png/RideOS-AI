import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';

class HardwareSimulationSettingsScreen extends StatefulWidget {
  const HardwareSimulationSettingsScreen({super.key});

  @override
  State<HardwareSimulationSettingsScreen> createState() => _HardwareSimulationSettingsScreenState();
}

class _HardwareSimulationSettingsScreenState extends State<HardwareSimulationSettingsScreen> {
  bool _useObdSimulation = true;
  bool _useTpmsSimulation = true;
  bool _useHelmetSimulation = true;
  bool _useDashcamSimulation = true;
  bool _useImuCrashSimulation = true;
  bool _useSquadRadioSimulation = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RoadOSColors.platinumWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'HARDWARE VS SIMULATION MATRIX',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: RoadOSColors.cyberCyan),
        ),
      ),
      body: LuxAuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Header Card
              RoadOSCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: RoadOSColors.cyberCyan,
                      ),
                      child: const Icon(Icons.tune_rounded, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CONNECTED VEHICLE FRAMEWORK', style: TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('Toggle real BLE hardware endpoints or high-fidelity telemetry simulation providers.', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('HARDWARE MODULE PROVIDERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: RoadOSColors.textMuted)),
              const SizedBox(height: 10),

              // OBD-II Switch Card
              _buildModuleCard(
                title: 'OBD-II CAN-BUS LINK',
                subtitle: _useObdSimulation ? 'Provider: Synthetic ISO 15765 PID Stream' : 'Provider: ELM327 Bluetooth BLE Hardware',
                icon: Icons.speed_rounded,
                value: _useObdSimulation,
                onChanged: (val) {
                  LuxAudioHapticsService.mediumImpact();
                  setState(() => _useObdSimulation = val);
                },
              ),
              const SizedBox(height: 12),

              // TPMS Switch Card
              _buildModuleCard(
                title: 'TIRE PRESSURE (TPMS)',
                subtitle: _useTpmsSimulation ? 'Provider: Simulated 36/42 PSI Thermal Drift' : 'Provider: Direct BLE Valve Cap Sensors',
                icon: Icons.tire_repair_rounded,
                value: _useTpmsSimulation,
                onChanged: (val) {
                  LuxAudioHapticsService.mediumImpact();
                  setState(() => _useTpmsSimulation = val);
                },
              ),
              const SizedBox(height: 12),

              // Smart Helmet Switch Card
              _buildModuleCard(
                title: 'SMART HELMET MESH',
                subtitle: _useHelmetSimulation ? 'Provider: Virtual Audio Loop & ICE Trigger' : 'Provider: Cardo / Sena Bluetooth Intercom',
                icon: Icons.headset_mic_rounded,
                value: _useHelmetSimulation,
                onChanged: (val) {
                  LuxAudioHapticsService.mediumImpact();
                  setState(() => _useHelmetSimulation = val);
                },
              ),
              const SizedBox(height: 12),

              // Dashcam Switch Card
              _buildModuleCard(
                title: '4K DASHCAM RECODER',
                subtitle: _useDashcamSimulation ? 'Provider: Simulated 60FPS Camera Feed' : 'Provider: On-Bike USB/WiFi Cam Feed',
                icon: Icons.videocam_rounded,
                value: _useDashcamSimulation,
                onChanged: (val) {
                  LuxAudioHapticsService.mediumImpact();
                  setState(() => _useDashcamSimulation = val);
                },
              ),
              const SizedBox(height: 12),

              // Crash IMU Sensor Switch Card
              _buildModuleCard(
                title: 'CRASH SENSOR IMU',
                subtitle: _useImuCrashSimulation ? 'Provider: 6-Axis Motion Test Suite' : 'Provider: Device Hardware Gyroscope & Accelerometer',
                icon: Icons.warning_amber_rounded,
                value: _useImuCrashSimulation,
                onChanged: (val) {
                  LuxAudioHapticsService.mediumImpact();
                  setState(() => _useImuCrashSimulation = val);
                },
              ),
              const SizedBox(height: 12),

              // Squad Mesh Radio Switch Card
              _buildModuleCard(
                title: 'SQUAD MESH RADIO',
                subtitle: _useSquadRadioSimulation ? 'Provider: Peer-to-Peer Relay Simulator' : 'Provider: High-Bandwidth Mesh Transceiver',
                icon: Icons.groups_rounded,
                value: _useSquadRadioSimulation,
                onChanged: (val) {
                  LuxAudioHapticsService.mediumImpact();
                  setState(() => _useSquadRadioSimulation = val);
                },
              ),
              const SizedBox(height: 24),

              RoadOSButton(
                label: 'APPLY HARDWARE CONFIGURATION',
                icon: Icons.check_circle_rounded,
                gradient: LuxGradients.quantumCyan,
                onPressed: () {
                  LuxAudioHapticsService.heavyImpact();
                  showLuxSnack(context, 'Hardware and simulation provider mappings updated.', variant: LuxSnackVariant.info);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return RoadOSCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 28, color: value ? RoadOSColors.cyberCyan : RoadOSColors.hyperOrange),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeTrackColor: RoadOSColors.cyberCyan,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
