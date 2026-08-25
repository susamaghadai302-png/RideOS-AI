import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../core/engine/garage_3d_viewport.dart';
import '../../core/services/garage_storage_service.dart';

/// Interactive Lighting Studio controller panel
class LightingStudioPanel extends StatefulWidget {
  final GarageLightingMode activeMode;
  final double keyIntensity;
  final double fillIntensity;
  final double rimIntensity;
  final double reflectionOpacity;
  final Function(GarageLightingMode mode) onModeChanged;
  final Function(double key, double fill, double rim, double reflection) onSlidersChanged;
  final VoidCallback onClose;

  const LightingStudioPanel({
    super.key,
    required this.activeMode,
    required this.keyIntensity,
    required this.fillIntensity,
    required this.rimIntensity,
    required this.reflectionOpacity,
    required this.onModeChanged,
    required this.onSlidersChanged,
    required this.onClose,
  });

  @override
  State<LightingStudioPanel> createState() => _LightingStudioPanelState();
}

class _LightingStudioPanelState extends State<LightingStudioPanel> {
  late double _key;
  late double _fill;
  late double _rim;
  late double _reflection;

  @override
  void initState() {
    super.initState();
    _key = widget.keyIntensity;
    _fill = widget.fillIntensity;
    _rim = widget.rimIntensity;
    _reflection = widget.reflectionOpacity;
  }

  void _notifySliders() {
    widget.onSlidersChanged(_key, _fill, _rim, _reflection);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      decoration: BoxDecoration(
        color: const Color(0xF00A0E1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
        boxShadow: const [
          BoxShadow(color: Colors.black87, blurRadius: 30, spreadRadius: 8),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.wb_sunny_rounded, color: Color(0xFF00E5FF), size: 18),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIGHTING STUDIO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 1.0,
                    ),
                  ),
                  Text(
                    'PBR Studio Rig & HDRI Atmosphere',
                    style: TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                onPressed: widget.onClose,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Environment Presets Grid
          const Text(
            'STUDIO ENVIRONMENT PRESETS',
            style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold, letterSpacing: 1.0),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GarageLightingMode.values.map((mode) {
              final isSelected = widget.activeMode == mode;
              return ChoiceChip(
                label: Text(
                  mode.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                selected: isSelected,
                selectedColor: const Color(0xFF00E5FF),
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                onSelected: (val) {
                  if (val) {
                    LuxAudioHapticsService.selectionClick();
                    widget.onModeChanged(mode);
                    GarageStorageService().saveLightingMode(mode.index);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Fine-tuning Light Sliders
          _buildLightSlider(
            label: 'KEY SPOTLIGHT INTENSITY',
            value: _key,
            icon: Icons.light_mode_rounded,
            color: const Color(0xFFFFD54F),
            onChanged: (val) {
              setState(() => _key = val);
              _notifySliders();
            },
          ),
          _buildLightSlider(
            label: 'FILL LIGHT INTENSITY',
            value: _fill,
            icon: Icons.blur_on_rounded,
            color: const Color(0xFF81D4FA),
            onChanged: (val) {
              setState(() => _fill = val);
              _notifySliders();
            },
          ),
          _buildLightSlider(
            label: 'RIM BACKLIGHT INTENSITY',
            value: _rim,
            icon: Icons.flare_rounded,
            color: const Color(0xFFFF8A80),
            onChanged: (val) {
              setState(() => _rim = val);
              _notifySliders();
            },
          ),
          _buildLightSlider(
            label: 'FLOOR SPECULAR REFLECTION',
            value: _reflection,
            icon: Icons.gradient_rounded,
            color: const Color(0xFF00E5FF),
            onChanged: (val) {
              setState(() => _reflection = val);
              _notifySliders();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLightSlider({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 13),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${(value * 100).round()}%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              thumbColor: color,
              activeTrackColor: color,
              inactiveTrackColor: Colors.white12,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
            ),
            child: Slider(
              value: value,
              min: 0.1,
              max: 2.0,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
