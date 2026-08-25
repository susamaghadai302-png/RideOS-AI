import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';

class AiAutonomousAssistanceCard extends StatelessWidget {
  const AiAutonomousAssistanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoadOSCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome_rounded, color: RoadOSColors.cyberCyan, size: 20),
                  SizedBox(width: 8),
                  Text('AI AUTONOMOUS RIDE ASSISTANCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('ACTIVE', style: TextStyle(fontSize: 10, color: RoadOSColors.apexEmerald, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AutoItem('LANE CENTERING', 'ON', RoadOSColors.apexEmerald),
              _AutoItem('SPEED ADVISORY', '60 KM/H', RoadOSColors.hyperOrange),
              _AutoItem('AUTO BRAKE ASSIST', 'READY', RoadOSColors.cyberCyan),
            ],
          ),
        ],
      ),
    );
  }
}

class _AutoItem extends StatelessWidget {
  final String label;
  final String val;
  final Color color;

  const _AutoItem(this.label, this.val, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 8, color: RoadOSColors.textMuted)),
      ],
    );
  }
}

class V2vMeshRadarCard extends StatelessWidget {
  const V2vMeshRadarCard({super.key});

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.cell_tower_rounded, color: RoadOSColors.hyperOrange, size: 20),
                  SizedBox(width: 8),
                  Text('5G & DSRC V2V COMMUNICATION MESH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('3 Nodes', style: TextStyle(fontSize: 10, color: RoadOSColors.hyperOrange, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF334155)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tesla Model S (85m ahead) | HARD BRAKING ALERT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RoadOSColors.errorCrimson)),
                    Text('BMW S1000RR (45m ahead) | Trajectory Matched', style: TextStyle(fontSize: 8, color: RoadOSColors.textMuted)),
                  ],
                ),
                Icon(Icons.warning_amber_rounded, color: RoadOSColors.errorCrimson, size: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SmartCityGlosaCard extends StatelessWidget {
  const SmartCityGlosaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoadOSCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.traffic_rounded, color: RoadOSColors.apexEmerald, size: 20),
                  SizedBox(width: 8),
                  Text('SMART CITY GLOSA GREEN-WAVE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('18s GREEN', style: TextStyle(fontSize: 10, color: RoadOSColors.apexEmerald, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Text('Optimal Speed: 45 KM/H to pass 3 traffic signals on green wave.', style: TextStyle(fontSize: 9, color: RoadOSColors.textMuted)),
        ],
      ),
    );
  }
}

class P2pAiSafetyNetworkCard extends StatelessWidget {
  const P2pAiSafetyNetworkCard({super.key});

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.hub_rounded, color: RoadOSColors.solarGold, size: 20),
                  SizedBox(width: 8),
                  Text('DECENTRALIZED P2P AI SAFETY NETWORK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.add_alert_rounded, color: RoadOSColors.solarGold, size: 18),
                onPressed: () {
                  LuxAudioHapticsService.mediumImpact();
                  showLuxSnack(context, 'P2P Oil Spill hazard broadcasted to 142 nearby riders!', variant: LuxSnackVariant.info);
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text('Oil Spill Reported 1.2 km Ahead | Broadcasted by Rider node #482', style: TextStyle(fontSize: 9, color: RoadOSColors.textMuted)),
        ],
      ),
    );
  }
}

class RoadIntelligencePlatformCard extends StatelessWidget {
  const RoadIntelligencePlatformCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoadOSCard(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.analytics_rounded, color: const Color(0xFF8B5CF6), size: 20),
                  SizedBox(width: 8),
                  Text('ROAD INTELLIGENCE PLATFORM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('Grip: 0.85 μ', style: TextStyle(fontSize: 10, color: RoadOSColors.apexEmerald, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Text('Asphalt Quality: High Friction | Elevation Curvature Risk: Low', style: TextStyle(fontSize: 9, color: RoadOSColors.textMuted)),
        ],
      ),
    );
  }
}
