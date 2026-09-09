import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';

/// DIGITAL WALLET WIDGET
class DigitalWalletWidget extends StatelessWidget {
  const DigitalWalletWidget({super.key});

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
                  Icon(Icons.account_balance_wallet_rounded, color: RoadOSColors.apexEmerald, size: 20),
                  SizedBox(width: 8),
                  Text('RIDEOS DIGITAL WALLET', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RoadOSColors.apexEmerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RoadOSColors.apexEmerald),
                ),
                child: const Text('BALANCE: \$480.50', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: RoadOSColors.apexEmerald)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildWalletAction('Fuel Pay', Icons.local_gas_station_rounded, RoadOSColors.hyperOrange)),
              const SizedBox(width: 8),
              Expanded(child: _buildWalletAction('FASTag Toll', Icons.toll_rounded, RoadOSColors.cyberCyan)),
              const SizedBox(width: 8),
              Expanded(child: _buildWalletAction('Service Pay', Icons.build_rounded, RoadOSColors.solarGold)),
              const SizedBox(width: 8),
              Expanded(child: _buildWalletAction('Insurance', Icons.verified_user_rounded, const Color(0xFF8B5CF6))),
            ],
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Monthly Ride Budget: \$600.00', style: TextStyle(fontSize: 10, color: RoadOSColors.textMuted)),
              Text('72% Used', style: TextStyle(fontSize: 10, color: RoadOSColors.solarGold, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletAction(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
        ],
      ),
    );
  }
}

/// SMART MARKETPLACE GRID WIDGET
class SmartMarketplaceGridWidget extends StatelessWidget {
  const SmartMarketplaceGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {'title': 'Akrapovic Titanium Exhaust', 'category': 'Exhaust System', 'price': '\$1,450', 'icon': Icons.flash_on_rounded, 'color': RoadOSColors.hyperOrange},
      {'title': 'Pirelli Diablo Rosso IV', 'category': 'Dual Compound Tyres', 'price': '\$340', 'icon': Icons.tire_repair_rounded, 'color': RoadOSColors.cyberCyan},
      {'title': 'Brembo Stylema Calipers', 'category': 'Brake Systems', 'price': '\$890', 'icon': Icons.security_rounded, 'color': RoadOSColors.errorCrimson},
      {'title': 'Dainese Misano D-Air Suit', 'category': 'Rider Gear', 'price': '\$2,100', 'icon': Icons.checkroom_rounded, 'color': RoadOSColors.solarGold},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.storefront_rounded, color: RoadOSColors.hyperOrange, size: 20),
                SizedBox(width: 8),
                Text('SMART MOTORCYCLE MARKETPLACE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
              ],
            ),
            Text('Official Partners', style: TextStyle(fontSize: 10, color: RoadOSColors.textMuted, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.35,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final color = item['color'] as Color;

            return RoadOSCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(item['icon'] as IconData, color: color, size: 18),
                      Text(item['price'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite), overflow: TextOverflow.ellipsis),
                      Text(item['category'] as String, style: const TextStyle(fontSize: 9, color: RoadOSColors.textMuted)),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

/// SERVICE NETWORK WIDGET
class ServiceNetworkWidget extends StatelessWidget {
  const ServiceNetworkWidget({super.key});

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
                  Icon(Icons.build_circle_rounded, color: RoadOSColors.cyberCyan, size: 20),
                  SizedBox(width: 8),
                  Text('AUTHORIZED SERVICE NETWORK', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RoadOSColors.apexEmerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RoadOSColors.apexEmerald),
                ),
                child: const Text('3 NEARBY WORKSHOPS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: RoadOSColors.apexEmerald)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildWorkshopRow('Ducati Official Service Center', '1.8 km', '4.9 ★ (128 reviews)', 'Book Slot (Today 4:00 PM)'),
          const SizedBox(height: 8),
          _buildWorkshopRow('Apex Moto Performance Garage', '3.4 km', '4.8 ★ (94 reviews)', 'Book Slot (Tomorrow 10:00 AM)'),
        ],
      ),
    );
  }

  Widget _buildWorkshopRow(String name, String dist, String rating, String slot) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
              Text('$dist | $rating', style: const TextStyle(fontSize: 9, color: RoadOSColors.textMuted)),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              LuxAudioHapticsService.selectionClick();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RoadOSColors.cyberCyan.withValues(alpha: 0.2),
              foregroundColor: RoadOSColors.cyberCyan,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
            child: Text(slot, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
