import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';

/// Interactive Lighting & Illumination Quick-Control Widget
class LightsControllerWidget extends StatelessWidget {
  final bool isHeadlightOn;
  final bool isHighBeamOn;
  final bool isBrakeLightOn;
  final bool isLeftIndicatorOn;
  final bool isRightIndicatorOn;
  final bool isHazardOn;
  final ValueChanged<bool> onToggleHeadlight;
  final ValueChanged<bool> onToggleHighBeam;
  final ValueChanged<bool> onToggleBrakeLight;
  final ValueChanged<bool> onToggleLeftIndicator;
  final ValueChanged<bool> onToggleRightIndicator;
  final ValueChanged<bool> onToggleHazard;

  const LightsControllerWidget({
    super.key,
    required this.isHeadlightOn,
    required this.isHighBeamOn,
    required this.isBrakeLightOn,
    required this.isLeftIndicatorOn,
    required this.isRightIndicatorOn,
    required this.isHazardOn,
    required this.onToggleHeadlight,
    required this.onToggleHighBeam,
    required this.onToggleBrakeLight,
    required this.onToggleLeftIndicator,
    required this.onToggleRightIndicator,
    required this.onToggleHazard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xDD0A0F1D),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1.0),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 16),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Headlight (Low Beam)
          _buildLightButton(
            icon: Icons.lightbulb_rounded,
            tooltip: 'Headlight (Low Beam)',
            isActive: isHeadlightOn,
            activeColor: const Color(0xFF00E5FF),
            onTap: () {
              LuxAudioHapticsService.selectionClick();
              onToggleHeadlight(!isHeadlightOn);
            },
          ),
          const SizedBox(width: 6),

          // 2. High Beam
          _buildLightButton(
            icon: Icons.highlight_rounded,
            tooltip: 'High Beam',
            isActive: isHighBeamOn,
            activeColor: Colors.blueAccent,
            onTap: () {
              LuxAudioHapticsService.selectionClick();
              onToggleHighBeam(!isHighBeamOn);
            },
          ),
          const SizedBox(width: 6),

          // 3. Brake Light (Hold / Tap)
          _buildLightButton(
            icon: Icons.warning_amber_rounded,
            tooltip: 'Brake Light',
            isActive: isBrakeLightOn,
            activeColor: const Color(0xFFFF1744),
            onTap: () {
              LuxAudioHapticsService.selectionClick();
              onToggleBrakeLight(!isBrakeLightOn);
            },
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: Colors.white24),
          const SizedBox(width: 8),

          // 4. Left Turn Indicator
          _buildLightButton(
            icon: Icons.turn_left_rounded,
            tooltip: 'Left Indicator',
            isActive: isLeftIndicatorOn,
            activeColor: const Color(0xFFFFB300),
            onTap: () {
              LuxAudioHapticsService.selectionClick();
              onToggleLeftIndicator(!isLeftIndicatorOn);
            },
          ),
          const SizedBox(width: 6),

          // 5. Right Turn Indicator
          _buildLightButton(
            icon: Icons.turn_right_rounded,
            tooltip: 'Right Indicator',
            isActive: isRightIndicatorOn,
            activeColor: const Color(0xFFFFB300),
            onTap: () {
              LuxAudioHapticsService.selectionClick();
              onToggleRightIndicator(!isRightIndicatorOn);
            },
          ),
          const SizedBox(width: 6),

          // 6. Hazard 4-Way Flasher
          _buildLightButton(
            icon: Icons.emergency_rounded,
            tooltip: 'Hazard 4-Way Flashers',
            isActive: isHazardOn,
            activeColor: const Color(0xFFFF3D00),
            onTap: () {
              LuxAudioHapticsService.heavyImpact();
              onToggleHazard(!isHazardOn);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLightButton({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? activeColor.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.06),
            shape: BoxShape.circle,
            border: Border.all(
              color: isActive ? activeColor : Colors.white12,
              width: 1.2,
            ),
            boxShadow: isActive
                ? [BoxShadow(color: activeColor.withValues(alpha: 0.6), blurRadius: 10, spreadRadius: 1)]
                : [],
          ),
          child: Icon(
            icon,
            color: isActive ? activeColor : Colors.white54,
            size: 16,
          ),
        ),
      ),
    );
  }
}
