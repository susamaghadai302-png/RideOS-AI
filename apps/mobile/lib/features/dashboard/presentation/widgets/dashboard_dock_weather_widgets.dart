import 'package:flutter/material.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/widgets/living_3d_environment.dart';

class WeatherWidget extends StatelessWidget {
  final String weatherCondition;
  final double tempCelsius;
  final double rainChance;
  final double windSpeedKmh;
  final Function(RideOSWeatherMode)? onWeatherModeChanged;

  const WeatherWidget({
    super.key,
    this.weatherCondition = 'Clear Aurora Sky',
    this.tempCelsius = 24.5,
    this.rainChance = 5.0,
    this.windSpeedKmh = 12.0,
    this.onWeatherModeChanged,
  });

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
                  Icon(Icons.wb_sunny_rounded, color: RoadOSColors.solarGold, size: 20),
                  SizedBox(width: 8),
                  Text('RIDE WEATHER RADAR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text(
                '${tempCelsius.round()} degC',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: RoadOSColors.cyberCyan),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  weatherCondition,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Rain: ${rainChance.round()}% | Wind: ${windSpeedKmh.round()} km/h',
                style: const TextStyle(fontSize: 10, color: RoadOSColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildModeChip(context, 'CLEAR', RideOSWeatherMode.clearAurora, RoadOSColors.cyberCyan),
              _buildModeChip(context, 'RAIN', RideOSWeatherMode.rain, RoadOSColors.electricBlue),
              _buildModeChip(context, 'FOG', RideOSWeatherMode.fog, RoadOSColors.solarGold),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(BuildContext context, String label, RideOSWeatherMode mode, Color color) {
    return GestureDetector(
      onTap: () {
        LuxAudioHapticsService.lightImpact();
        onWeatherModeChanged?.call(mode);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }
}

class LastRideSummaryWidget extends StatelessWidget {
  final String title;
  final String date;
  final double distanceKm;
  final String duration;
  final double maxLeanAngle;
  final double maxSpeedKmh;
  final int safetyScore;

  const LastRideSummaryWidget({
    super.key,
    this.title = 'Pacific Coast Highway Apex Loop',
    this.date = 'Yesterday | 14:30',
    this.distanceKm = 142.8,
    this.duration = '1h 45m',
    this.maxLeanAngle = 48.5,
    this.maxSpeedKmh = 184.0,
    this.safetyScore = 96,
  });

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
                  Icon(Icons.history_toggle_off_rounded, color: RoadOSColors.hyperOrange, size: 20),
                  SizedBox(width: 8),
                  Text('LAST RIDE SUMMARY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RoadOSColors.hyperOrange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RoadOSColors.hyperOrange),
                ),
                child: Text(
                  'SAFETY: $safetyScore/100',
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: RoadOSColors.hyperOrange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
          Text(date, style: const TextStyle(fontSize: 10, color: RoadOSColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildStatItem('DISTANCE', '${distanceKm.toStringAsFixed(1)} km', Icons.route_rounded)),
              Expanded(child: _buildStatItem('DURATION', duration, Icons.timer_outlined)),
              Expanded(child: _buildStatItem('MAX LEAN', '${maxLeanAngle.toStringAsFixed(1)} deg', Icons.screen_rotation_rounded)),
              Expanded(child: _buildStatItem('TOP SPEED', '${maxSpeedKmh.round()} km/h', Icons.speed_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: RoadOSColors.cyberCyan, size: 16),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
        Text(label, style: const TextStyle(fontSize: 8, color: RoadOSColors.textMuted, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class QuickActionDockWidget extends StatelessWidget {
  final VoidCallback? onNavTap;
  final VoidCallback? onAiTap;
  final VoidCallback? onSosTap;
  final VoidCallback? onDashcamTap;
  final VoidCallback? onObdTap;

  const QuickActionDockWidget({
    super.key,
    this.onNavTap,
    this.onAiTap,
    this.onSosTap,
    this.onDashcamTap,
    this.onObdTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xE60D1117),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: RoadOSColors.hyperOrange.withValues(alpha: 0.3)),
        boxShadow: LuxShadows.glassGlow(RoadOSColors.hyperOrange),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildDockButton('3D NAV', Icons.navigation_rounded, RoadOSColors.hyperOrange, onNavTap),
          _buildDockButton('JARVIS AI', Icons.auto_awesome, RoadOSColors.cyberCyan, onAiTap),
          _buildDockButton('SOS SCAN', Icons.warning_amber_rounded, RoadOSColors.errorCrimson, onSosTap),
          _buildDockButton('DASHCAM', Icons.videocam_rounded, RoadOSColors.electricBlue, onDashcamTap),
          _buildDockButton('OBD BUS', Icons.memory_rounded, RoadOSColors.solarGold, onObdTap),
        ],
      ),
    );
  }

  Widget _buildDockButton(String label, IconData icon, Color color, VoidCallback? onTap) {
    return GestureDetector(
      onTap: () {
        LuxAudioHapticsService.mediumImpact();
        onTap?.call();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
