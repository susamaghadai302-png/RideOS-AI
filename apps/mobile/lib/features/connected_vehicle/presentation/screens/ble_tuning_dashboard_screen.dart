import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_connectivity/services/ble_characteristic_tuning_engine.dart';
import '../../../../core/widgets/cinematic_background.dart';

class BleTuningDashboardScreen extends StatefulWidget {
  const BleTuningDashboardScreen({super.key});

  @override
  State<BleTuningDashboardScreen> createState() => _BleTuningDashboardScreenState();
}

class _BleTuningDashboardScreenState extends State<BleTuningDashboardScreen> {
  final _tuningEngine = BleCharacteristicTuningEngine();
  BleStreamScenario _selectedScenario = BleStreamScenario.stableConnection;

  @override
  void dispose() {
    _tuningEngine.stopScenario();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.bluetooth_audio_rounded, color: RoadOSColors.electricBlue, size: 20),
            SizedBox(width: 8),
            Text(
              'BLE FIELD TUNING BENCH',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: CinematicBackground(child: StreamBuilder<BleTuningSessionState>(
        stream: _tuningEngine.sessionStream,
        initialData: _tuningEngine.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data ?? _tuningEngine.currentState;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildScenarioSelector(state),
              const SizedBox(height: 16),
              _buildGattLinkCard(state),
              const SizedBox(height: 16),
              _buildLiveMetricsCard(state),
              const SizedBox(height: 16),
              _buildTelemetryGaugeCard(state),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(state.isStreaming ? Icons.stop_rounded : Icons.play_arrow_rounded),
                label: Text(
                  state.isStreaming ? 'STOP TUNING STREAM' : 'START TUNING STREAM',
                  style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: state.isStreaming ? Colors.redAccent : RoadOSColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
        LuxAudioHapticsService.lightImpact();
                  if (state.isStreaming) {
                    _tuningEngine.stopScenario();
                  } else {
                    _tuningEngine.startScenario(_selectedScenario);
                  }
                },
              ),
            ],
          );
        },
      )),
    );
  }

  Widget _buildScenarioSelector(BleTuningSessionState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SIMULATED BLE STREAM SCENARIO', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          DropdownButtonFormField<BleStreamScenario>(
            value: _selectedScenario,
            dropdownColor: Colors.black,
            style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              filled: true,
              fillColor: Colors.black,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            items: BleStreamScenario.values.map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(s.name.replaceAllMapped(RegExp(r'[A-Z]'), (m) => ' ${m[0]}').toUpperCase()),
              );
            }).toList(),
            onChanged: state.isStreaming ? null : (val) {
              if (val != null) {
                setState(() => _selectedScenario = val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGattLinkCard(BleTuningSessionState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoadOSColors.electricBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(state.vehicleProfileLabel, style: const TextStyle(color: RoadOSColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RoadOSColors.electricBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(state.protocolVerificationLabel, style: const TextStyle(color: RoadOSColors.electricBlue, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Service: ${state.activeServiceUuid}', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
          Text('Characteristic: ${state.activeCharacteristicUuid}', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildLiveMetricsCard(BleTuningSessionState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat('RSSI', '${state.rssi} dBm'),
          _buildStat('MTU', '${state.mtu} B'),
          _buildStat('RATE', '${state.notificationFrequencyHz} Hz'),
          _buildStat('LOSS', '${state.packetLossPercent.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  Widget _buildStat(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTelemetryGaugeCard(BleTuningSessionState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('TUNED SENSOR OUTPUT (10 Hz)', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Text('SPEED', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                      Text('${state.telemetry.speedKmh.toInt()} km/h', style: const TextStyle(color: RoadOSColors.electricBlue, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      const Text('RPM', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                      Text('${state.telemetry.rpm.toInt()}', style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
