import 'package:flutter/material.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';

class DigitalTwin3dViewerCard extends StatelessWidget {
  const DigitalTwin3dViewerCard({super.key});

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
                  Icon(Icons.view_in_ar_rounded, color: RoadOSColors.cyberCyan, size: 20),
                  SizedBox(width: 8),
                  Text('3D MOTORCYCLE DIGITAL TWIN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('Health: 98.4%', style: TextStyle(fontSize: 10, color: RoadOSColors.apexEmerald, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.3)),
            ),
            child: Stack(
              children: [
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.two_wheeler_rounded, color: RoadOSColors.cyberCyan, size: 54),
                      SizedBox(height: 4),
                      Text('DUCATI PANIGALE V4 R (DIGITAL TWIN ACTIVE)', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 8,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: RoadOSColors.apexEmerald.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
                    child: const Text('Live Telematics Stream Linked', style: TextStyle(fontSize: 8, color: RoadOSColors.apexEmerald, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TwinMetric('BATTERY', '94%', RoadOSColors.solarGold),
              _TwinMetric('FUEL', '78%', RoadOSColors.apexEmerald),
              _TwinMetric('TIRE PSI', '36 / 42', RoadOSColors.cyberCyan),
              _TwinMetric('OIL LIFE', '88%', RoadOSColors.hyperOrange),
            ],
          ),
        ],
      ),
    );
  }
}

class _TwinMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TwinMetric(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 8, color: RoadOSColors.textMuted)),
      ],
    );
  }
}

class ArHelmetHudWidget extends StatelessWidget {
  const ArHelmetHudWidget({super.key});

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
                  Icon(Icons.camera_outdoor_rounded, color: RoadOSColors.hyperOrange, size: 20),
                  SizedBox(width: 8),
                  Text('AR HELMET HUD & XR OVERLAY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('Bat: 92%', style: TextStyle(fontSize: 10, color: RoadOSColors.hyperOrange, fontWeight: FontWeight.bold)),
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
                    Text('Helmet Camera 1080P | Mesh Intercom Connected', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                    Text('Turn arrows, speed & hazard overlays active', style: TextStyle(fontSize: 8, color: RoadOSColors.textMuted)),
                  ],
                ),
                Icon(Icons.bluetooth_connected_rounded, color: RoadOSColors.apexEmerald, size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AiSafetyEngineCard extends StatelessWidget {
  const AiSafetyEngineCard({super.key});

  @override
  Widget build(BuildContext context) {
    final hazards = [
      {'title': 'Pothole Alert', 'dist': '45m ahead', 'color': RoadOSColors.warningAmber, 'icon': Icons.warning_amber_rounded},
      {'title': 'Water Logging', 'dist': '120m ahead', 'color': RoadOSColors.cyberCyan, 'icon': Icons.water_drop_rounded},
      {'title': 'Pedestrian Crossing', 'dist': '80m ahead', 'color': RoadOSColors.hyperOrange, 'icon': Icons.directions_walk_rounded},
    ];

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
                  Icon(Icons.shield_rounded, color: RoadOSColors.errorCrimson, size: 20),
                  SizedBox(width: 8),
                  Text('AI ROAD SAFETY HAZARD DETECTOR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('3 Warnings', style: TextStyle(fontSize: 10, color: RoadOSColors.errorCrimson, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          ...hazards.map((h) => Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: (h['color'] as Color).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(h['icon'] as IconData, color: h['color'] as Color, size: 14),
                        const SizedBox(width: 8),
                        Text(h['title'] as String, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                      ],
                    ),
                    Text(h['dist'] as String, style: TextStyle(fontSize: 9, color: h['color'] as Color, fontWeight: FontWeight.bold)),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

class GlobalCommunityMarketplaceCard extends StatelessWidget {
  const GlobalCommunityMarketplaceCard({super.key});

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
                  Icon(Icons.storefront_rounded, color: RoadOSColors.solarGold, size: 20),
                  SizedBox(width: 8),
                  Text('RIDER COMMUNITY & MARKETPLACE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('Offers Active', style: TextStyle(fontSize: 10, color: RoadOSColors.solarGold, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildItem('Accessories', '15% Off Helmet', Icons.headset_mic_rounded, RoadOSColors.cyberCyan)),
              const SizedBox(width: 8),
              Expanded(child: _buildItem('Insurance', 'Instant Quote', Icons.verified_user_rounded, RoadOSColors.apexEmerald)),
              const SizedBox(width: 8),
              Expanded(child: _buildItem('Service', 'Book Slot', Icons.build_rounded, RoadOSColors.hyperOrange)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItem(String title, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
          Text(sub, style: TextStyle(fontSize: 8, color: color)),
        ],
      ),
    );
  }
}

class SmartServicesValuationWidget extends StatelessWidget {
  const SmartServicesValuationWidget({super.key});

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
                  Icon(Icons.calculate_rounded, color: const Color(0xFF8B5CF6), size: 20),
                  SizedBox(width: 8),
                  Text('BIKE RESALE VALUATION & LOAN EMI', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('Est: \$24,500', style: TextStyle(fontSize: 10, color: const Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Text('RC & PUC Reminders | Insurance Renewal Countdown: 42 Days', style: TextStyle(fontSize: 9, color: RoadOSColors.textMuted)),
        ],
      ),
    );
  }
}

class WearablesConnectivityWidget extends StatelessWidget {
  const WearablesConnectivityWidget({super.key});

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
                  Icon(Icons.watch_rounded, color: RoadOSColors.cyberCyan, size: 20),
                  SizedBox(width: 8),
                  Text('WEARABLES & VEHICLE CONNECTIVITY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('Apple Watch Active', style: TextStyle(fontSize: 10, color: RoadOSColors.apexEmerald, fontWeight: FontWeight.bold)),
            ],
          ),
          SizedBox(height: 8),
          Text('Android Auto | Apple CarPlay | Smart Ring Sync Linked', style: TextStyle(fontSize: 9, color: RoadOSColors.textMuted)),
        ],
      ),
    );
  }
}

class AdminFleetSubscriptionsWidget extends StatefulWidget {
  const AdminFleetSubscriptionsWidget({super.key});

  @override
  State<AdminFleetSubscriptionsWidget> createState() => _AdminFleetSubscriptionsWidgetState();
}

class _AdminFleetSubscriptionsWidgetState extends State<AdminFleetSubscriptionsWidget> {
  String _selectedTier = 'PRO';

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
                  Icon(Icons.admin_panel_settings_rounded, color: RoadOSColors.hyperOrange, size: 20),
                  SizedBox(width: 8),
                  Text('ADMIN FLEET & SUBSCRIPTION TIER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('Tier: $_selectedTier', style: const TextStyle(fontSize: 10, color: RoadOSColors.hyperOrange, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: ['FREE', 'PRO', 'ENTERPRISE'].map((tier) {
              final isSel = _selectedTier == tier;
              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: ElevatedButton(
                    onPressed: () {
                      LuxAudioHapticsService.selectionClick();
                      setState(() => _selectedTier = tier);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSel ? RoadOSColors.hyperOrange : Colors.black26,
                      foregroundColor: isSel ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                    ),
                    child: Text(tier, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
