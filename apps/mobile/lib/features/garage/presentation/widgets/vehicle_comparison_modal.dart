import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../domain/entities/garage_vehicle_model.dart';

/// Multi-Motorcycle Side-by-Side Technical Comparison Modal
class VehicleComparisonModal extends StatefulWidget {
  final List<GarageVehicleModel> catalog;
  final String initialSelectedId;

  const VehicleComparisonModal({
    super.key,
    required this.catalog,
    required this.initialSelectedId,
  });

  @override
  State<VehicleComparisonModal> createState() => _VehicleComparisonModalState();
}

class _VehicleComparisonModalState extends State<VehicleComparisonModal> {
  late String _bike1Id;
  late String _bike2Id;

  @override
  void initState() {
    super.initState();
    _bike1Id = widget.initialSelectedId;
    // Default second bike to a different vehicle
    final otherBikes = widget.catalog.where((b) => b.id != _bike1Id).toList();
    _bike2Id = otherBikes.isNotEmpty ? otherBikes.first.id : _bike1Id;
  }

  GarageVehicleModel _getBike(String id) =>
      widget.catalog.firstWhere((b) => b.id == id, orElse: () => widget.catalog.first);

  @override
  Widget build(BuildContext context) {
    final bike1 = _getBike(_bike1Id);
    final bike2 = _getBike(_bike2Id);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 820),
        decoration: BoxDecoration(
          color: const Color(0xF00A0F1D),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 40, spreadRadius: 10),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 20, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.compare_arrows_rounded, color: Color(0xFF00E5FF), size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TECHNICAL VEHICLE COMPARISON',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'Side-by-side performance benchmarks & race telemetry',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),

            // Vehicle Selector Row
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Bike 1 Dropdown
                  Expanded(
                    child: _buildBikeDropdown(
                      selectedId: _bike1Id,
                      accentColor: bike1.factoryAccentColor,
                      onChanged: (id) => setState(() => _bike1Id = id!),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    child: Text('VS', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  // Bike 2 Dropdown
                  Expanded(
                    child: _buildBikeDropdown(
                      selectedId: _bike2Id,
                      accentColor: bike2.factoryAccentColor,
                      onChanged: (id) => setState(() => _bike2Id = id!),
                    ),
                  ),
                ],
              ),
            ),

            // Comparison Metrics Table
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  children: [
                    _buildMetricRow(
                      label: 'PEAK POWER',
                      val1: '${bike1.horsepower} HP',
                      val2: '${bike2.horsepower} HP',
                      num1: bike1.horsepower.toDouble(),
                      num2: bike2.horsepower.toDouble(),
                      color1: bike1.factoryAccentColor,
                      color2: bike2.factoryAccentColor,
                      unit: 'HP',
                    ),
                    _buildMetricRow(
                      label: 'MAX TORQUE',
                      val1: '${bike1.torqueNm} Nm',
                      val2: '${bike2.torqueNm} Nm',
                      num1: bike1.torqueNm,
                      num2: bike2.torqueNm,
                      color1: bike1.factoryAccentColor,
                      color2: bike2.factoryAccentColor,
                      unit: 'Nm',
                    ),
                    _buildMetricRow(
                      label: 'TOP SPEED',
                      val1: bike1.topSpeedKmh,
                      val2: bike2.topSpeedKmh,
                      num1: double.parse(bike1.topSpeedKmh.split(' ')[0]),
                      num2: double.parse(bike2.topSpeedKmh.split(' ')[0]),
                      color1: bike1.factoryAccentColor,
                      color2: bike2.factoryAccentColor,
                      unit: 'km/h',
                    ),
                    _buildMetricRow(
                      label: '0-100 KM/H ACCELERATION',
                      val1: bike1.zeroToHundred,
                      val2: bike2.zeroToHundred,
                      num1: 5.0 - double.parse(bike1.zeroToHundred.split(' ')[0]), // Invert so lower is better
                      num2: 5.0 - double.parse(bike2.zeroToHundred.split(' ')[0]),
                      color1: bike1.factoryAccentColor,
                      color2: bike2.factoryAccentColor,
                      unit: '',
                    ),
                    _buildMetricRow(
                      label: 'CURB WEIGHT',
                      val1: '${bike1.curbWeightKg} kg',
                      val2: '${bike2.curbWeightKg} kg',
                      num1: 300.0 - bike1.curbWeightKg, // Invert so lighter is better
                      num2: 300.0 - bike2.curbWeightKg,
                      color1: bike1.factoryAccentColor,
                      color2: bike2.factoryAccentColor,
                      unit: 'kg',
                    ),
                    _buildMetricRow(
                      label: 'DISPLACEMENT',
                      val1: '${bike1.engineCc} cc',
                      val2: '${bike2.engineCc} cc',
                      num1: bike1.engineCc.toDouble(),
                      num2: bike2.engineCc.toDouble(),
                      color1: bike1.factoryAccentColor,
                      color2: bike2.factoryAccentColor,
                      unit: 'cc',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBikeDropdown({
    required String selectedId,
    required Color accentColor,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          dropdownColor: const Color(0xFF0F172A),
          isExpanded: true,
          items: widget.catalog.map((bike) {
            return DropdownMenuItem<String>(
              value: bike.id,
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: bike.factoryAccentColor, shape: BoxShape.circle)),
                  const SizedBox(width: 10),
                  Text(
                    bike.fullName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (id) {
            LuxAudioHapticsService.selectionClick();
            onChanged(id);
          },
        ),
      ),
    );
  }

  Widget _buildMetricRow({
    required String label,
    required String val1,
    required String val2,
    required double num1,
    required double num2,
    required Color color1,
    required Color color2,
    required String unit,
  }) {
    final maxNum = math.max(num1, num2);
    final ratio1 = maxNum > 0 ? (num1 / maxNum).clamp(0.1, 1.0) : 0.5;
    final ratio2 = maxNum > 0 ? (num2 / maxNum).clamp(0.1, 1.0) : 0.5;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
          const SizedBox(height: 6),
          Row(
            children: [
              // Bike 1 Value & Bar
              Expanded(
                child: Row(
                  children: [
                    Text(val1, style: TextStyle(color: color1, fontWeight: FontWeight.w900, fontSize: 12)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio1,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(color1),
                          minHeight: 6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              // Bike 2 Bar & Value
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: ratio2,
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation<Color>(color2),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(val2, style: TextStyle(color: color2, fontWeight: FontWeight.w900, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
