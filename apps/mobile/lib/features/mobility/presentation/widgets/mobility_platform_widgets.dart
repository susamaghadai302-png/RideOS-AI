import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';

enum MobilityVehicleCategory {
  superbike,
  scooter,
  adventureTourer,
  electricBike,
  cruiser,
}

/// VEHICLE CATEGORY SELECTOR PLUGIN WIDGET
class VehicleCategorySelectorWidget extends StatefulWidget {
  const VehicleCategorySelectorWidget({super.key});

  @override
  State<VehicleCategorySelectorWidget> createState() => _VehicleCategorySelectorWidgetState();
}

class _VehicleCategorySelectorWidgetState extends State<VehicleCategorySelectorWidget> {
  MobilityVehicleCategory _selectedCategory = MobilityVehicleCategory.superbike;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AI MOBILITY VEHICLE PLATFORM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
        const SizedBox(height: 10),
        SizedBox(
          height: 85,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildCategoryTile(MobilityVehicleCategory.superbike, 'Superbike', Icons.two_wheeler_rounded, RoadOSColors.hyperOrange),
              _buildCategoryTile(MobilityVehicleCategory.adventureTourer, 'Adventure Tourer', Icons.explore_rounded, RoadOSColors.cyberCyan),
              _buildCategoryTile(MobilityVehicleCategory.electricBike, 'EV Motorcycle', Icons.electric_bolt_rounded, RoadOSColors.apexEmerald),
              _buildCategoryTile(MobilityVehicleCategory.scooter, 'Maxi Scooter', Icons.moped_rounded, RoadOSColors.solarGold),
              _buildCategoryTile(MobilityVehicleCategory.cruiser, 'Urban Cruiser', Icons.motorcycle_rounded, const Color(0xFF8B5CF6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryTile(MobilityVehicleCategory cat, String name, IconData icon, Color color) {
    final isSelected = _selectedCategory == cat;

    return GestureDetector(
      onTap: () {
        LuxAudioHapticsService.selectionClick();
        setState(() => _selectedCategory = cat);
      },
      child: Container(
        width: 120,
        margin: const EdgeInsets.only(right: 10),
        child: RoadOSCard(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? color : RoadOSColors.textMuted, size: 22),
              const SizedBox(height: 6),
              Text(
                name,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.normal,
                  color: isSelected ? RoadOSColors.platinumWhite : RoadOSColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// AI SAFETY CENTER WIDGET
class AiSafetyCenterWidget extends StatelessWidget {
  const AiSafetyCenterWidget({super.key});

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
                  Icon(Icons.shield_rounded, color: RoadOSColors.apexEmerald, size: 20),
                  SizedBox(width: 8),
                  Text('AI RIDE SAFETY CENTER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RoadOSColors.apexEmerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RoadOSColors.apexEmerald),
                ),
                child: const Text('READINESS 98%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: RoadOSColors.apexEmerald)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCheckItem('DOT Approved Smart Helmet Connected', Icons.sports_motorsports_rounded, true),
          _buildCheckItem('Front/Rear TPMS Pressures Nominal', Icons.tire_repair_rounded, true),
          _buildCheckItem('Precipitation & Crosswind Warning (CA-1 Pass)', Icons.thunderstorm_rounded, false),
          _buildCheckItem('12V AGM Battery Voltage Nominal', Icons.battery_charging_full_rounded, true),
          _buildCheckItem('SOS Emergency Contacts & Live Location Ready', Icons.sos_rounded, true),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String label, IconData icon, bool isOk) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: isOk ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isOk ? FontWeight.normal : FontWeight.bold,
                color: isOk ? RoadOSColors.platinumWhite : RoadOSColors.errorCrimson,
              ),
            ),
          ),
          Icon(
            isOk ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
            color: isOk ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson,
            size: 14,
          ),
        ],
      ),
    );
  }
}

/// DIGITAL DOCUMENT CENTER WIDGET
class DigitalDocumentCenterWidget extends StatelessWidget {
  const DigitalDocumentCenterWidget({super.key});

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
                  Icon(Icons.folder_shared_rounded, color: RoadOSColors.solarGold, size: 20),
                  SizedBox(width: 8),
                  Text('DIGITAL DOCUMENT VAULT', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('6 Verified Docs', style: TextStyle(fontSize: 9, color: RoadOSColors.solarGold, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildDocTile('RC Registration', 'Active', Icons.badge_rounded, RoadOSColors.apexEmerald)),
              const SizedBox(width: 8),
              Expanded(child: _buildDocTile('Insurance Policy', 'Renews 42d', Icons.verified_user_rounded, RoadOSColors.cyberCyan)),
              const SizedBox(width: 8),
              Expanded(child: _buildDocTile('Driving Licence', 'Valid 2028', Icons.card_membership_rounded, RoadOSColors.hyperOrange)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDocTile('PUC Certificate', 'Valid 180d', Icons.eco_rounded, RoadOSColors.apexEmerald)),
              const SizedBox(width: 8),
              Expanded(child: _buildDocTile('Service Invoices', '12 Records', Icons.receipt_long_rounded, RoadOSColors.solarGold)),
              const SizedBox(width: 8),
              Expanded(child: _buildDocTile('OEM Warranty', 'Active (2 yr)', Icons.security_rounded, const Color(0xFF8B5CF6))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDocTile(String name, String status, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite), overflow: TextOverflow.ellipsis),
          Text(status, style: TextStyle(fontSize: 8, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
