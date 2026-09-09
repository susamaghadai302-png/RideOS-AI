import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../domain/models/advanced_trip_models.dart';
import '../../core/services/advanced_trip_navigation_engine.dart';
import '../../../../core/widgets/cinematic_background.dart';

class AdvancedTripHistoryScreen extends StatefulWidget {
  const AdvancedTripHistoryScreen({super.key});

  @override
  State<AdvancedTripHistoryScreen> createState() => _AdvancedTripHistoryScreenState();
}

class _AdvancedTripHistoryScreenState extends State<AdvancedTripHistoryScreen> {
  final _tripEngine = AdvancedTripNavigationEngine();
  String? _selectedVehicleFilter;
  String _aiOutput = '';
  final TextEditingController _queryController = TextEditingController();

  void _sendQuery(String prompt) {
    if (prompt.trim().isEmpty) return;
    final res = _tripEngine.processTripAiQuery(prompt.trim());
    setState(() {
      _aiOutput = res;
      _queryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final places = _tripEngine.getSavedPlaces();
    final services = _tripEngine.getNearbyServices();
    final trips = _tripEngine.getTripHistory(vehicleId: _selectedVehicleFilter);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF060912),
        title: const Text(
          'TRIP INTELLIGENCE & NAVIGATION',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
        ),
      ),
      body: CinematicBackground(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Saved Places
          const Text('SAVED PLACES & QUICK ROUTES', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: places.map((p) => _buildSavedPlaceCard(p)).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Verified Local POIs
          const Text('VERIFIED LOCAL POIs & SERVICES', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ...services.map((s) => _buildServicePoiTile(s)),

          const SizedBox(height: 16),

          // 3. Trip History & Motorcycle Filter
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('RECORDED TRIP SESSIONS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              if (_selectedVehicleFilter != null)
                GestureDetector(
                  onTap: () => setState(() => _selectedVehicleFilter = null),
                  child: const Text('Clear Filter', style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildVehicleFilterChip('All Bikes', null),
                _buildVehicleFilterChip('Yamaha R1M', 'v_yamaha_r1m'),
                _buildVehicleFilterChip('Ducati Panigale', 'v_ducati_v4s'),
                _buildVehicleFilterChip('Yamaha MT-09', 'v_yamaha_mt09_sp'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          ...trips.map((t) => _buildTripCard(t)),

          const SizedBox(height: 16),

          // 4. Trip AI Assistant
          const Text('TRIP & NAVIGATION AI ASSISTANT', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPromptChip('How was my last ride?'),
                _buildPromptChip('What is my pre-ride checklist?'),
                _buildPromptChip('Find nearest fuel station'),
                _buildPromptChip('Show my saved places'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (_aiOutput.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF060A14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.smart_toy_rounded, color: RoadOSColors.cyberCyan, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_aiOutput, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3)),
                  ),
                ],
              ),
            ),

          // Query Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Ask about previous rides, nearest services...',
                    hintStyle: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF080C1A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: RoadOSColors.borderTranslucent),
                    ),
                  ),
                  onSubmitted: _sendQuery,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: RoadOSColors.electricBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                onPressed: () => _sendQuery(_queryController.text),
              ),
            ],
          ),
        ],
      )),
    );
  }

  Widget _buildSavedPlaceCard(SavedPlaceItem p) {
    IconData iconData = Icons.location_on;
    if (p.category == SavedPlaceCategory.home) iconData = Icons.home;
    if (p.category == SavedPlaceCategory.work) iconData = Icons.work;
    if (p.category == SavedPlaceCategory.serviceCenter) iconData = Icons.build;
    if (p.category == SavedPlaceCategory.favorite) iconData = Icons.star;

    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF060A14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, color: RoadOSColors.cyberCyan, size: 18),
          const SizedBox(height: 6),
          Text(p.title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(p.subtitle, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildServicePoiTile(NearbyServicePoi s) {
    IconData icon = Icons.local_gas_station;
    Color col = RoadOSColors.hyperOrange;
    if (s.category == NearbyServiceCategory.hospital) {
      icon = Icons.local_hospital;
      col = Colors.redAccent;
    } else if (s.category == NearbyServiceCategory.serviceCenter) {
      icon = Icons.build_circle;
      col = RoadOSColors.cyberCyan;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF060A14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Row(
        children: [
          Icon(icon, color: col, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('${s.distanceKm} km | ${s.address}', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleFilterChip(String label, String? vehicleId) {
    final isSelected = _selectedVehicleFilter == vehicleId;
    return GestureDetector(
      onTap: () => setState(() => _selectedVehicleFilter = vehicleId),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? RoadOSColors.electricBlue : RoadOSColors.cardSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.borderTranslucent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : RoadOSColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTripCard(TripRecord t) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t.vehicleName, style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 12, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${t.safetyScore}/100 SCORE', style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('${t.startAddress} ➔ ${t.destinationAddress}', style: const TextStyle(color: Colors.white, fontSize: 11)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${t.distanceKm} km | ${t.durationMinutes.round()} mins', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
              Text('Avg ${t.averageSpeedKmh.round()} km/h (Top ${t.maxSpeedKmh.round()} km/h)', style: const TextStyle(color: RoadOSColors.hyperOrange, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String prompt) {
    return GestureDetector(
      onTap: () => _sendQuery(prompt),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF080C1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1A2035)),
        ),
        child: Text(prompt, style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
