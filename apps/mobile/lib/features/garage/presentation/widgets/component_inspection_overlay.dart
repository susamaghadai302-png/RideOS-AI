import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../domain/entities/garage_vehicle_model.dart';

/// Technical detail inspection drawer for motorcycle components
class ComponentInspectionOverlay extends StatelessWidget {
  final GarageVehicleModel vehicle;
  final String activeComponentKey;
  final Function(String nextKey) onSelectComponent;
  final VoidCallback onClose;

  const ComponentInspectionOverlay({
    super.key,
    required this.vehicle,
    required this.activeComponentKey,
    required this.onSelectComponent,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final spec = vehicle.components[activeComponentKey];
    if (spec == null) return const SizedBox.shrink();

    final accent = vehicle.factoryAccentColor;

    return Container(
      width: 400,
      decoration: BoxDecoration(
        color: const Color(0xF00A0F1D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: 4,
          ),
          const BoxShadow(color: Colors.black87, blurRadius: 40, spreadRadius: 10),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent),
                ),
                child: Text(
                  spec.category.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Component Title
          Text(
            spec.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),

          // Short Summary
          Text(
            spec.shortSummary,
            style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Key Feature Highlight Banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [accent.withValues(alpha: 0.15), Colors.transparent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded, color: accent, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    spec.keyFeature,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Technical Specs Table
          const Text(
            'ENGINEERING SPECIFICATIONS',
            style: TextStyle(color: Colors.white54, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: spec.technicalDetails.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    children: [
                      Text(entry.key, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      const Spacer(),
                      Text(
                        entry.value,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Quick Component Switcher Carousel
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: vehicle.components.keys.map((key) {
                final isSelected = key == activeComponentKey;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    label: Text(
                      key.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : Colors.white,
                      ),
                    ),
                    backgroundColor: isSelected ? accent : Colors.white10,
                    onPressed: () {
                      LuxAudioHapticsService.selectionClick();
                      onSelectComponent(key);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
