import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../core/map_abstraction/map_engine_interface.dart';
import '../../core/services/ai_route_optimizer_service.dart';
import '../../../../core/widgets/cinematic_background.dart';

class AiRouteOptimizerScreen extends StatefulWidget {
  const AiRouteOptimizerScreen({super.key});

  @override
  State<AiRouteOptimizerScreen> createState() => _AiRouteOptimizerScreenState();
}

class _AiRouteOptimizerScreenState extends State<AiRouteOptimizerScreen> {
  final AiRouteOptimizerService _optimizer = AiRouteOptimizerService();
  List<AiRouteRecommendation> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAiRoutes();
  }

  Future<void> _loadAiRoutes() async {
    final routes = await _optimizer.generateOptimizedRoutes(
      origin: const MapCoordinates(latitude: 36.5785, longitude: -118.2920),
      destination: const MapCoordinates(latitude: 36.6000, longitude: -118.3000),
    );
    if (mounted) {
      setState(() {
        _recommendations = routes;
        _isLoading = false;
      });
    }
  }

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
          'AI ROUTE OPTIMIZATION ENGINE',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: RoadOSColors.cyberCyan),
        ),
      ),
      body: CinematicBackground(child: LuxAuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // AI Intelligence Header Card
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
                      child: const Icon(Icons.psychology_rounded, color: Colors.black, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('JARVIS AI LEARNING ENGINE', style: TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('Learned from 42 past rides | Average lean preference: 24.5 deg', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Hazard Avoidance Toggles Card
              RoadOSCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ACTIVE HAZARD AVOIDANCE FILTERS', style: TextStyle(color: RoadOSColors.hyperOrange, fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    _buildSwitchTile('Avoid Flood Areas', _optimizer.avoidFloodAreas, (val) {
                      LuxAudioHapticsService.lightImpact();
                      setState(() => _optimizer.avoidFloodAreas = val);
                    }),
                    _buildSwitchTile('Avoid Construction Sites', _optimizer.avoidConstruction, (val) {
                      LuxAudioHapticsService.lightImpact();
                      setState(() => _optimizer.avoidConstruction = val);
                    }),
                    _buildSwitchTile('Avoid Bad / Pothole Roads', _optimizer.avoidBadPotholeRoads, (val) {
                      LuxAudioHapticsService.lightImpact();
                      setState(() => _optimizer.avoidBadPotholeRoads = val);
                    }),
                    _buildSwitchTile('Avoid Heavy Traffic Congestion', _optimizer.avoidTrafficCongestion, (val) {
                      LuxAudioHapticsService.lightImpact();
                      setState(() => _optimizer.avoidTrafficCongestion = val);
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text('AI RECOMMENDED ROUTES', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: RoadOSColors.textMuted)),
              const SizedBox(height: 12),

              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: RoadOSColors.cyberCyan))
              else
                ..._recommendations.map((rec) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: RoadOSCard(
                      padding: const EdgeInsets.all(16),
                      onTap: () {
                        LuxAudioHapticsService.heavyImpact();
                        Navigator.pop(context, rec);
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(rec.title, style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: RoadOSColors.cyberCyan.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('Thrill: ${rec.thrillScore.toInt()}%', style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${rec.distanceKm} km | ${rec.durationMinutes} mins | Saved ${rec.fuelSavedLiters}L Fuel', style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(rec.description, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            children: rec.avoidedHazards.map((h) {
                              return Chip(
                                label: Text('✓ $h', style: const TextStyle(fontSize: 9, color: RoadOSColors.platinumWhite)),
                                backgroundColor: Colors.transparent,
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: RoadOSColors.platinumWhite, fontSize: 12, fontWeight: FontWeight.bold)),
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
