import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';

class LiveRideDashboardScreen extends StatefulWidget {
  const LiveRideDashboardScreen({super.key});

  @override
  State<LiveRideDashboardScreen> createState() => _LiveRideDashboardScreenState();
}

class _LiveRideDashboardScreenState extends State<LiveRideDashboardScreen> {
  final double _currentSpeed = 88.0;
  final double _avgSpeed = 64.2;
  final double _altitudeMeters = 1420.0;
  final double _gpsAccuracyMeters = 1.2;
  final int _batteryPercent = 94;
  final String _networkStatus = '5G Ultra';
  final String _weatherText = '24 degC | Clear Sky';
  final String _compassHeading = 'NNE 34 deg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RoadOSColors.platinumWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'LIVE RIDE DASHBOARD HUD',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: RoadOSColors.cyberCyan),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: RoadOSColors.cyberCyan),
            onPressed: () {
              LuxAudioHapticsService.lightImpact();
            },
          ),
        ],
      ),
      body: LuxAuroraBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Top System Bar Row (Battery, Network, Voice Status)
              RoadOSCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.mic_rounded, color: RoadOSColors.apexEmerald, size: 18),
                        SizedBox(width: 6),
                        Text('JARVIS VOICE ACTIVE', style: TextStyle(color: RoadOSColors.apexEmerald, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(Icons.wifi_rounded, color: RoadOSColors.cyberCyan, size: 18),
                        const SizedBox(width: 4),
                        Text(_networkStatus, style: const TextStyle(color: RoadOSColors.platinumWhite, fontSize: 10, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 14),
                        const Icon(Icons.battery_5_bar_rounded, color: RoadOSColors.apexEmerald, size: 18),
                        const SizedBox(width: 4),
                        Text('$_batteryPercent%', style: const TextStyle(color: RoadOSColors.platinumWhite, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Main Speedometer Arc Hero Widget
              RepaintBoundary(
                child: RoadOSCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        _currentSpeed.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 72,
                          fontWeight: FontWeight.w900,
                          color: RoadOSColors.platinumWhite,
                          height: 1.0,
                        ),
                      ),
                      const Text('KM / H', style: TextStyle(color: RoadOSColors.cyberCyan, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2.0)),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('AVG SPEED', '${_avgSpeed.toInt()} km/h', Icons.speed_rounded),
                          _buildStatItem('ALTITUDE', '${_altitudeMeters.toInt()}m', Icons.terrain_rounded),
                          _buildStatItem('GPS ACCURACY', '+/-${_gpsAccuracyMeters}m', Icons.gps_fixed_rounded),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Turn-by-Turn Navigation Live Card Widget
              RoadOSCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: RoadOSColors.hyperOrange,
                      ),
                      child: const Icon(Icons.turn_right_rounded, color: Colors.black, size: 28),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('IN 350 METERS', style: TextStyle(color: RoadOSColors.hyperOrange, fontSize: 10, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Turn Right onto Canyon Pass Trail', style: TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 2),
                          Text('Optimal Flow | 42.5 km Remaining', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Trip Telemetry Grid (ETA, Duration, Compass, Weather)
              Row(
                children: [
                  const Expanded(
                    child: RoadOSCard(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ETA & DURATION', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                          SizedBox(height: 6),
                          Text('18:45', style: TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.w900, fontSize: 20)),
                          Text('01h 12m elapsed', style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RoadOSCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('WEATHER & COMPASS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(_compassHeading, style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.w900, fontSize: 16)),
                          Text(_weatherText, style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: RoadOSColors.textMuted, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold, fontSize: 13)),
        Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
