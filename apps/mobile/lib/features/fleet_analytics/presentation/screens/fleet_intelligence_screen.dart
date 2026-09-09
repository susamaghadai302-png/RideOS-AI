import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../domain/models/multi_vehicle_fleet_models.dart';
import '../../services/multi_vehicle_fleet_engine.dart';
import '../../../../core/widgets/cinematic_background.dart';

class FleetIntelligenceScreen extends StatefulWidget {
  const FleetIntelligenceScreen({super.key});

  @override
  State<FleetIntelligenceScreen> createState() => _FleetIntelligenceScreenState();
}

class _FleetIntelligenceScreenState extends State<FleetIntelligenceScreen> {
  final _fleetEngine = MultiVehicleFleetEngine();
  String _selectedVehicleId = 'v_yamaha_r1m';
  String _aiResponse = '';
  final TextEditingController _queryController = TextEditingController();

  void _sendQuery(String prompt) {
    if (prompt.trim().isEmpty) return;
    final res = _fleetEngine.processVehicleSpecificAiQuery(prompt.trim());
    setState(() {
      _aiResponse = res;
      _queryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final rider = _fleetEngine.getRiderProfileStats();
    final vehicles = _fleetEngine.getFleetVehicles();
    final priorities = _fleetEngine.getFleetServicePriorities();
    final comparison = _fleetEngine.getCrossVehicleComparison();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF060912),
        title: const Text(
          'FLEET & MULTI-VEHICLE INTELLIGENCE',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
        ),
      ),
      body: CinematicBackground(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Rider Profile Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF070B18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: RoadOSColors.electricBlue.withValues(alpha: 0.4)),
              boxShadow: RoadOSShadows.luxuryCard,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rider.riderName, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text('${rider.callSign} | ${rider.rank}', style: const TextStyle(color: RoadOSColors.hyperOrange, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: RoadOSColors.apexEmerald.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '${rider.overallSafetyScore}/100 SAFETY',
                        style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 10, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const Divider(color: RoadOSColors.borderTranslucent, height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildRiderStat('LIFETIME DISTANCE', '${rider.totalDistanceKm.toStringAsFixed(0)} km', RoadOSColors.cyberCyan),
                    _buildRiderStat('TOTAL RIDES', '${rider.totalRides}', RoadOSColors.hyperOrange),
                    _buildRiderStat('ACTIVE MOTORCYCLES', '${rider.activeBikeCount} Bikes', RoadOSColors.electricBlue),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Multi-Motorcycle Switcher & Cards
          const Text('REGISTERED FLEET MOTORCYCLES', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 10),

          ...vehicles.map((v) {
            final isSelected = v.vehicleId == _selectedVehicleId;
            return GestureDetector(
              onTap: () => setState(() => _selectedVehicleId = v.vehicleId),
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF070B18) : const Color(0xFF080C1A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? RoadOSColors.electricBlue : RoadOSColors.borderTranslucent,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                      color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${v.make} ${v.model}', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900)),
                              _buildStatusBadge(v.status),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${v.category} | ${v.year} | Odometer: ${v.currentOdometerKm} km', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                          const SizedBox(height: 4),
                          Text('Health: ${v.healthScore}% | BLE: ${v.bluetoothDeviceId}', style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // 3. Smart Fleet Service Prioritization Roadmap
          const Text('FLEET SERVICE PRIORITIZATION ROADMAP', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ...priorities.map((p) => _buildPriorityTile(p)),

          const SizedBox(height: 16),

          // 4. Cross-Vehicle Comparison
          RoadOSCard(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('CROSS-VEHICLE UTILIZATION MATRIX', style: TextStyle(color: RoadOSColors.platinumWhite, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text('Total Fleet Mileage: ${comparison.totalFleetDistanceKm.toStringAsFixed(0)} km across ${comparison.totalFleetRides} sessions', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
                const SizedBox(height: 6),
                Text('Most Ridden Asset: ${comparison.mostRiddenVehicle}', style: const TextStyle(color: RoadOSColors.hyperOrange, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Vehicle-Specific AI Assistant Queries
          const Text('VEHICLE & FLEET AI ASSISTANT', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPromptChip('How is my R1M?'),
                _buildPromptChip('When is Ducati due?'),
                _buildPromptChip('Which bike needs attention?'),
                _buildPromptChip('Which motorcycle did I ride the most?'),
                _buildPromptChip('Compare R1M and Panigale'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (_aiResponse.isNotEmpty)
            RoadOSCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.smart_toy_rounded, color: RoadOSColors.cyberCyan, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_aiResponse, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3)),
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
                    hintText: 'Ask about any motorcycle in your fleet...',
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

  Widget _buildRiderStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildStatusBadge(FleetVehicleStatus status) {
    Color bg = RoadOSColors.apexEmerald.withValues(alpha: 0.15);
    Color fg = RoadOSColors.apexEmerald;

    if (status == FleetVehicleStatus.attentionRequired) {
      bg = Colors.amber.withValues(alpha: 0.15);
      fg = Colors.amberAccent;
    } else if (status == FleetVehicleStatus.critical) {
      bg = Colors.red.withValues(alpha: 0.2);
      fg = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPriorityTile(FleetServicePriorityItem p) {
    final isPriHigh = p.priorityLabel == 'HIGH';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RoadOSCard(
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${p.vehicleName} | ${p.taskType}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Due in ${p.remainingKm} km (at ${p.dueKm} km)',
                    style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: isPriHigh ? RoadOSColors.warningAmber.withValues(alpha: 0.18) : RoadOSColors.apexEmerald.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPriHigh ? RoadOSColors.warningAmber.withValues(alpha: 0.5) : RoadOSColors.apexEmerald.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                p.priorityLabel,
                style: TextStyle(
                  color: isPriHigh ? RoadOSColors.warningAmber : RoadOSColors.apexEmerald,
                  fontSize: 8.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
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
          color: const Color(0xFF0A0F1C),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.30)),
        ),
        child: Text(prompt, style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
