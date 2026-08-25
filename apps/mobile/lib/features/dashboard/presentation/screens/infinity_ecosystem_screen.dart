import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../widgets/infinity_ecosystem_widgets.dart';

class InfinityEcosystemScreen extends StatefulWidget {
  const InfinityEcosystemScreen({super.key});

  @override
  State<InfinityEcosystemScreen> createState() => _InfinityEcosystemScreenState();
}

class _InfinityEcosystemScreenState extends State<InfinityEcosystemScreen> {
  final String _selectedLang = 'English (US)';

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
              'RIDEOS INFINITY ECOSYSTEM',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: RoadOSColors.cyberCyan, letterSpacing: -0.5),
            ),
            Row(
              children: [
                const Icon(Icons.language_rounded, color: RoadOSColors.apexEmerald, size: 12),
                const SizedBox(width: 4),
                Text(
                  '100+ Languages Active | $_selectedLang',
                  style: const TextStyle(fontSize: 9, color: RoadOSColors.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.translate_rounded, color: RoadOSColors.cyberCyan),
            onPressed: () {
              LuxAudioHapticsService.selectionClick();
              showLuxSnack(context, 'Language switched to English (US). 100+ Languages supported.', variant: LuxSnackVariant.info);
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
              // 3D Digital Twin Viewer
              DigitalTwin3dViewerCard(),
              SizedBox(height: 14),

              // AR Helmet HUD Widget
              ArHelmetHudWidget(),
              SizedBox(height: 14),

              // AI Road Safety Hazard Detector
              AiSafetyEngineCard(),
              SizedBox(height: 14),

              // Global Community & Marketplace
              GlobalCommunityMarketplaceCard(),
              SizedBox(height: 14),

              // Smart Services & Valuation
              SmartServicesValuationWidget(),
              SizedBox(height: 14),

              // Wearables & Vehicle Connectivity
              WearablesConnectivityWidget(),
              SizedBox(height: 14),

              // Admin Fleet & Subscription Tiers
              AdminFleetSubscriptionsWidget(),
            ],
          ),
        ),
      ),
    );
  }
}
