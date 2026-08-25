import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../widgets/version8_future_widgets.dart';

class RideOsFutureScreen extends StatefulWidget {
  const RideOsFutureScreen({super.key});

  @override
  State<RideOsFutureScreen> createState() => _RideOsFutureScreenState();
}

class _RideOsFutureScreenState extends State<RideOsFutureScreen> {
  bool _autonomousActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'RIDEOS FUTURE | VERSION 8.0',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: RoadOSColors.hyperOrange, letterSpacing: -0.5),
            ),
            Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _autonomousActive ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  _autonomousActive ? '5G V2V Mesh & Autonomous AI Online' : 'Manual Override Engaged',
                  style: const TextStyle(fontSize: 9, color: RoadOSColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(_autonomousActive ? Icons.electric_bolt_rounded : Icons.flash_off_rounded, color: RoadOSColors.hyperOrange),
            onPressed: () {
              LuxAudioHapticsService.selectionClick();
              setState(() => _autonomousActive = !_autonomousActive);
              showLuxSnack(
                context,
                _autonomousActive ? '5G V2V Mesh & Autonomous AI Online' : 'Manual Override Engaged',
                variant: _autonomousActive ? LuxSnackVariant.success : LuxSnackVariant.warning,
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              // AI Autonomous Assistance Card
              AiAutonomousAssistanceCard(),
              SizedBox(height: 14),

              // 5G & DSRC V2V Communication Mesh
              V2vMeshRadarCard(),
              SizedBox(height: 14),

              // Smart City GLOSA Traffic Controller
              SmartCityGlosaCard(),
              SizedBox(height: 14),

              // Decentralized P2P AI Safety Network
              P2pAiSafetyNetworkCard(),
              SizedBox(height: 14),

              // Road Intelligence Platform
              RoadIntelligencePlatformCard(),
            ],
          ),
        ),
      ),
    );
  }
}
