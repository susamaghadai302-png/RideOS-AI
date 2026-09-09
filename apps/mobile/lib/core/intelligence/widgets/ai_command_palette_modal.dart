import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design_system/roados_components.dart';
import '../../services/lux_haptics_audio_service.dart';
import '../../../features/garage/presentation/screens/luxury_garage_showroom_screen.dart';
import '../../../features/navigation/presentation/screens/three_d_navigation_screen.dart';
import '../../../features/diagnostics/presentation/screens/vehicle_health_dashboard_screen.dart';
import '../../../features/connected_vehicle/presentation/screens/connect_vehicle_screen.dart';
import '../../../features/ride_history/presentation/screens/ride_history_screen.dart';
import '../../../features/vehicle_manager/presentation/screens/my_vehicles_screen.dart';
import '../../../features/vehicle_manager/presentation/screens/vehicle_catalog_screen.dart';
import '../../../features/maintenance/presentation/screens/predictive_ride_intelligence_screen.dart';
import '../../../features/settings/presentation/screens/settings_hub_screen.dart';
import '../../design_system/premium_navigation.dart';

class CommandPaletteEntry {
  final String title;
  final String category;
  final IconData icon;
  final Color color;
  final VoidCallback onSelect;

  const CommandPaletteEntry({
    required this.title,
    required this.category,
    required this.icon,
    required this.color,
    required this.onSelect,
  });
}

void showAiCommandPaletteModal(BuildContext context) {
  showLiquidGlassModal(
    context: context,
    child: _CommandPaletteContent(),
  );
}

class _CommandPaletteContent extends StatefulWidget {
  @override
  State<_CommandPaletteContent> createState() => _CommandPaletteContentState();
}

class _CommandPaletteContentState extends State<_CommandPaletteContent> {
  final _searchController = TextEditingController();
  String _query = '';

  List<CommandPaletteEntry> _getEntries(BuildContext context) {
    return [
      CommandPaletteEntry(
        title: 'Open 3D Garage Showroom',
        category: 'VEHICLE',
        icon: Icons.garage_rounded,
        color: RoadOSColors.cyberCyan,
        onSelect: () => Navigator.push(context, premiumRoute(const LuxuryGarageShowroomScreen())),
      ),
      CommandPaletteEntry(
        title: 'Connect Hardware via Bluetooth',
        category: 'CONNECTIVITY',
        icon: Icons.bluetooth_connected_rounded,
        color: RoadOSColors.electricBlue,
        onSelect: () => Navigator.push(context, premiumRoute(const ConnectVehicleScreen())),
      ),
      CommandPaletteEntry(
        title: 'Vehicle Diagnostics & Health',
        category: 'DIAGNOSTICS',
        icon: Icons.health_and_safety_rounded,
        color: RoadOSColors.apexEmerald,
        onSelect: () => Navigator.push(context, premiumRoute(const VehicleHealthDashboardScreen())),
      ),
      CommandPaletteEntry(
        title: 'Predictive Ride Intelligence & Maintenance',
        category: 'AI & PREDICTION',
        icon: Icons.auto_awesome_rounded,
        color: RoadOSColors.hyperOrange,
        onSelect: () => Navigator.push(context, premiumRoute(const PredictiveRideIntelligenceScreen())),
      ),
      CommandPaletteEntry(
        title: '3D Smart Route GPS Navigation',
        category: 'NAVIGATION',
        icon: Icons.navigation_rounded,
        color: RoadOSColors.cyberCyan,
        onSelect: () => Navigator.push(context, premiumRoute(const ThreeDNavigationScreen())),
      ),
      CommandPaletteEntry(
        title: 'My Vehicles Garage & Fleet',
        category: 'FLEET',
        icon: Icons.two_wheeler_rounded,
        color: RoadOSColors.neonViolet,
        onSelect: () => Navigator.push(context, premiumRoute(const MyVehiclesScreen())),
      ),
      CommandPaletteEntry(
        title: 'Explore Global Vehicle Catalog',
        category: 'FLEET',
        icon: Icons.explore_rounded,
        color: RoadOSColors.cyberCyan,
        onSelect: () => Navigator.push(context, premiumRoute(const VehicleCatalogScreen())),
      ),
      CommandPaletteEntry(
        title: 'Ride History & Telemetry Logs',
        category: 'ANALYTICS',
        icon: Icons.history_rounded,
        color: RoadOSColors.neonViolet,
        onSelect: () => Navigator.push(context, premiumRoute(const RideHistoryScreen())),
      ),
      CommandPaletteEntry(
        title: 'System Settings & Hardware Hub',
        category: 'SYSTEM',
        icon: Icons.settings_rounded,
        color: RoadOSColors.textSecondary,
        onSelect: () => Navigator.push(context, premiumRoute(const SettingsHubScreen())),
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = _getEntries(context);
    final filtered = _query.isEmpty
        ? allEntries
        : allEntries
            .where((e) =>
                e.title.toLowerCase().contains(_query.toLowerCase()) ||
                e.category.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'AI COMMAND PALETTE',
                style: GoogleFonts.outfit(
                  color: RoadOSColors.cyberCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'ROUTE LAUNCHER',
              style: TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Search Input
        LiquidGlassInput(
          controller: _searchController,
          hintText: 'Search actions, screens, diagnostics...',
          prefixIcon: Icons.search_rounded,
          onChanged: (val) => setState(() => _query = val),
        ),
        const SizedBox(height: 14),

        // List of Commands
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 280),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No matching commands found.',
                      style: GoogleFonts.inter(color: RoadOSColors.textMuted, fontSize: 12),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (context, idx) {
                    final item = filtered[idx];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: LiquidGlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        borderRadius: 12,
                        blurSigma: 14,
                        onTap: () {
                          LuxAudioHapticsService.selectionClick();
                          Navigator.pop(context);
                          item.onSelect();
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: item.color.withValues(alpha: 0.15),
                              ),
                              child: Icon(item.icon, color: item.color, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                item.title,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: RoadOSColors.midnightNavy,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: RoadOSColors.borderSubtle),
                              ),
                              child: Text(
                                item.category,
                                style: const TextStyle(
                                  color: RoadOSColors.textMuted,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
