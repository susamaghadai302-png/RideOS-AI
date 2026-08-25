import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import '../../../../core/services/lux_haptics_audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/telemetry_engine/models/telemetry_metric_entry.dart';
import '../../../../core/telemetry_engine/services/vehicle_telemetry_engine.dart';
import '../../../../core/telemetry_engine/services/ride_session_manager.dart';
import 'package:rideos_mobile/core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import 'package:rideos_mobile/features/ai_assistant/presentation/screens/rider_mode_assistant_screen.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/premium_overlays.dart';
import '../../../../core/widgets/apex_components.dart';

class SmartCockpitScreen extends ConsumerStatefulWidget {
  const SmartCockpitScreen({super.key});

  @override
  ConsumerState<SmartCockpitScreen> createState() => _SmartCockpitScreenState();
}

class _SmartCockpitScreenState extends ConsumerState<SmartCockpitScreen> {
  final _telemetryEngine = VehicleTelemetryEngine();
  final _sessionManager = RideSessionManager();

  @override
  Widget build(BuildContext context) {
    final activeContext = ref.watch(activeVehicleContextProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.speed_rounded, color: RoadOSColors.electricBlue, size: 20),
            const SizedBox(width: 8),
            Text(
              activeContext.hasActiveVehicle
                  ? activeContext.profile!.fullName.toUpperCase()
                  : 'SMART COCKPIT',
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Rider AI Assistant',
            icon: const Icon(Icons.mic_rounded, color: RoadOSColors.electricBlue),
            onPressed: () {
        LuxAudioHapticsService.lightImpact();
              Navigator.push(context, premiumRoute(const RiderModeAssistantScreen()));
            },
          ),
          StreamBuilder<LiveVehicleCockpitSnapshot>(
            stream: _telemetryEngine.snapshotStream,
            initialData: _telemetryEngine.currentSnapshot,
            builder: (context, snapshot) {
              final isConn = snapshot.data?.isVehicleConnected ?? false;
              return Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isConn ? RoadOSColors.apexEmerald : RoadOSColors.textMuted).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: (isConn ? RoadOSColors.apexEmerald : RoadOSColors.textMuted).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.circle, size: 8, color: isConn ? RoadOSColors.apexEmerald : RoadOSColors.textMuted),
                    const SizedBox(width: 6),
                    Text(
                      isConn ? 'BLE LINK' : 'STANDBY',
                      style: TextStyle(color: isConn ? RoadOSColors.apexEmerald : RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: CinematicBackground(child: StreamBuilder<LiveVehicleCockpitSnapshot>(
        stream: _telemetryEngine.snapshotStream,
        initialData: _telemetryEngine.currentSnapshot,
        builder: (context, snapshot) {
          final data = snapshot.data ?? LiveVehicleCockpitSnapshot.initialDisconnected());
          return Column(
            children: [
              _buildStaleOrOfflineBanner(data),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildPrimarySpeedDisplay(data.speedKmh),
                    const SizedBox(height: 16),
                    _buildSecondaryGaugesGrid(data),
                    const SizedBox(height: 16),
                    _buildSafetyAndDiagnosticsBar(data),
                    const SizedBox(height: 16),
                    _buildAiRideInsightCard(data),
                    const SizedBox(height: 20),
                    _buildRideSessionControls(),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStaleOrOfflineBanner(LiveVehicleCockpitSnapshot data) {
    if (data.isOfflineMode) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        color: Colors.amber.withValues(alpha: 0.2),
        child: Row(
          children: const [
            Icon(Icons.cloud_off_rounded, size: 14, color: Colors.amber),
            SizedBox(width: 8),
            Text(
              'OFFLINE MODE — Local vehicle connection & ride session recording active',
              style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    if (data.speedKmh.state == TelemetryFreshnessState.stale) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        color: Colors.redAccent.withValues(alpha: 0.2),
        child: Row(
          children: const [
            Icon(Icons.history_toggle_off_rounded, size: 14, color: Colors.redAccent),
            SizedBox(width: 8),
            Text(
              'TELEMETRY STALE — Signal paused or ignition off. Awaiting fresh stream...',
              style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPrimarySpeedDisplay(TelemetryMetric<double> speed) {
    final speedVal = speed.isSupported && speed.value != null ? speed.value! : 0.0;
    final rpmFraction = (speedVal / 220.0).clamp(0.0, 1.0);
    return RoadOSCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SPEEDOMETER',
                style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
              _buildFreshnessBadge(speed.state),
            ],
          ),
          const SizedBox(height: 12),
          // Premium cockpit gauge
          ApexCockpitGauge(
            speed: speedVal,
            rpmValue: rpmFraction,
            gear: speedVal < 20 ? '1' : speedVal < 50 ? '2' : speedVal < 90 ? '3' : speedVal < 130 ? '4' : speedVal < 170 ? '5' : '6',
            size: 190,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryGaugesGrid(LiveVehicleCockpitSnapshot data) {
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.4,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        if (data.rpm.isSupported)
          _buildGaugeCard(
            title: 'ENGINE RPM',
            value: data.rpm.formattedValue,
            unit: 'RPM',
            icon: Icons.multiline_chart_rounded,
            badge: data.rpm.state,
          ),
        if (data.stateOfChargePct.isSupported)
          _buildGaugeCard(
            title: 'BATTERY SOC',
            value: data.stateOfChargePct.formattedValue,
            unit: '%',
            icon: Icons.electric_bike_rounded,
            badge: data.stateOfChargePct.state,
          )
        else if (data.fuelLevelPct.isSupported)
          _buildGaugeCard(
            title: 'FUEL LEVEL',
            value: data.fuelLevelPct.formattedValue,
            unit: '%',
            icon: Icons.local_gas_station_rounded,
            badge: data.fuelLevelPct.state,
          ),
        if (data.batteryVoltage.isSupported)
          _buildGaugeCard(
            title: 'BATTERY 12V',
            value: data.batteryVoltage.formattedValue,
            unit: 'V',
            icon: Icons.battery_charging_full_rounded,
            badge: data.batteryVoltage.state,
          ),
        if (data.engineTempC.isSupported)
          _buildGaugeCard(
            title: 'COOLANT TEMP',
            value: data.engineTempC.formattedValue,
            unit: ' degC',
            icon: Icons.thermostat_rounded,
            badge: data.engineTempC.state,
          )
        else if (data.motorTempC.isSupported)
          _buildGaugeCard(
            title: 'MOTOR TEMP',
            value: data.motorTempC.formattedValue,
            unit: ' degC',
            icon: Icons.thermostat_rounded,
            badge: data.motorTempC.state,
          ),
      ],
    );
  }

  Widget _buildGaugeCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
    required TelemetryFreshnessState badge,
  }) {
    return RoadOSCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: RoadOSColors.electricBlue, size: 18),
              _buildFreshnessBadge(badge),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(value, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 4),
                  Text(unit, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
                ],
              ),
              Text(title, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, letterSpacing: 1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyAndDiagnosticsBar(LiveVehicleCockpitSnapshot data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RoadOSColors.borderTranslucent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusIcon('ABS', data.absStatus.isSupported ? (data.absStatus.value == true ? 'ACTIVE' : 'READY') : 'N/A', Icons.shield_rounded, RoadOSColors.apexEmerald),
          _buildStatusIcon('TCS', data.tractionControl.isSupported ? (data.tractionControl.value == true ? 'ACTIVE' : 'STANDBY') : 'N/A', Icons.track_changes_rounded, RoadOSColors.electricBlue),
          _buildStatusIcon('DTC', data.activeDtcCodes.isSupported ? (data.activeDtcCodes.value?.isEmpty ?? true ? 'CLEAR' : '${data.activeDtcCodes.value!.length} DTC') : 'N/A', Icons.healing_rounded, RoadOSColors.warningAmber),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String label, String status, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(status, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9)),
          ],
        ),
      ],
    );
  }

  Widget _buildAiRideInsightCard(LiveVehicleCockpitSnapshot data) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RoadOSColors.neonViolet.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: RoadOSColors.neonViolet.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: RoadOSColors.neonViolet, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'AI RIDE INSIGHT',
                  style: TextStyle(color: RoadOSColors.neonViolet, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                SizedBox(height: 2),
                Text(
                  'Linear throttle modulation observed — Energy efficiency +14% over fleet baseline.',
                  style: TextStyle(color: RoadOSColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRideSessionControls() {
    return StreamBuilder<RideSessionState>(
      stream: _sessionManager.stateStream,
      initialData: _sessionManager.currentState,
      builder: (context, snapshot) {
        final state = snapshot.data ?? RideSessionState.idle;
        final isRiding = state == RideSessionState.riding;
        final isPaused = state == RideSessionState.paused;

        if (!isRiding && !isPaused) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_circle_filled_rounded),
              label: const Text('START RIDE SESSION', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
              style: ElevatedButton.styleFrom(
                backgroundColor: RoadOSColors.apexEmerald,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _sessionManager.startRideSession(),
            ),
          );
        }

        return Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(isRiding ? Icons.pause_circle_rounded : Icons.play_arrow_rounded),
                label: Text(isRiding ? 'PAUSE RIDE' : 'RESUME RIDE', style: const TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RoadOSColors.warningAmber,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
        LuxAudioHapticsService.lightImpact();
                  if (isRiding) {
                    _sessionManager.pauseRideSession();
                  } else {
                    _sessionManager.resumeRideSession();
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.stop_circle_rounded),
                label: const Text('END RIDE', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
        LuxAudioHapticsService.lightImpact();
                  final summary = _sessionManager.endRideSession();
                  showLuxSnack(context, 'Ride Finished: ${summary.totalDistanceKm.toStringAsFixed(1)} km recorded', variant: LuxSnackVariant.info);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFreshnessBadge(TelemetryFreshnessState state) {
    Color color;
    String label;

    switch (state) {
      case TelemetryFreshnessState.live:
        color = RoadOSColors.apexEmerald;
        label = 'LIVE';
        break;
      case TelemetryFreshnessState.stale:
        color = RoadOSColors.warningAmber;
        label = 'STALE';
        break;
      case TelemetryFreshnessState.simulated:
        color = RoadOSColors.neonViolet;
        label = 'SIM';
        break;
      case TelemetryFreshnessState.offline:
        color = Colors.amber;
        label = 'OFFLINE';
        break;
      case TelemetryFreshnessState.unsupported:
        color = RoadOSColors.textMuted;
        label = 'N/A';
        break;
      default:
        color = RoadOSColors.textMuted;
        label = '—';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}
