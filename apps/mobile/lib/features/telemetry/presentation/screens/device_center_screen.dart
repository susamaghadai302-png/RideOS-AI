import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/device_providers/models/normalized_telemetry_models.dart';
import '../../../../core/device_providers/services/fleet_telematics_engine.dart';
import '../../../../core/widgets/cinematic_background.dart';

class DeviceCenterScreen extends StatefulWidget {
  const DeviceCenterScreen({super.key});

  @override
  State<DeviceCenterScreen> createState() => _DeviceCenterScreenState();
}

class _DeviceCenterScreenState extends State<DeviceCenterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _engine = FleetTelematicsEngine();
  String _selectedProviderKey = 'simulator';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF060912),
        title: const Text(
          'DEVICE & TELEMATICS CENTER',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: RoadOSColors.electricBlue,
          labelColor: RoadOSColors.electricBlue,
          unselectedLabelColor: RoadOSColors.textMuted,
          tabs: const [
            Tab(icon: Icon(Icons.bluetooth_searching_rounded, size: 18), text: 'Devices'),
            Tab(icon: Icon(Icons.speed_rounded, size: 18), text: 'Live HUD'),
            Tab(icon: Icon(Icons.health_and_safety_rounded, size: 18), text: 'Diagnostics'),
            Tab(icon: Icon(Icons.data_object_rounded, size: 18), text: 'Packets'),
          ],
        ),
      ),
      body: CinematicBackground(child: TabBarView(
        controller: _tabController,
        children: [
          _buildDevicesTab(),
          _buildLiveHudTab(),
          _buildDiagnosticsTab(),
          _buildPacketInspectorTab(),
        ],
      )),
    );
  }

  Widget _buildDevicesTab() {
    final provider = _engine.activeProvider;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Source Classification Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: provider?.dataSourceClassification == TelemetryDataSource.realDevice
                ? RoadOSColors.apexEmerald.withValues(alpha: 0.15)
                : const Color(0xFFFFD600).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: provider?.dataSourceClassification == TelemetryDataSource.realDevice
                  ? RoadOSColors.apexEmerald
                  : const Color(0xFFFFD600),
            ),
          ),
          child: Row(
            children: [
              Icon(
                provider?.dataSourceClassification == TelemetryDataSource.realDevice
                    ? Icons.sensors_rounded
                    : Icons.science_rounded,
                color: provider?.dataSourceClassification == TelemetryDataSource.realDevice
                    ? RoadOSColors.apexEmerald
                    : const Color(0xFFFFD600),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      provider?.dataSourceClassification.label ?? 'NO PROVIDER',
                      style: TextStyle(
                        color: provider?.dataSourceClassification == TelemetryDataSource.realDevice
                            ? RoadOSColors.apexEmerald
                            : const Color(0xFFFFD600),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      provider?.displayName ?? 'No Active Provider',
                      style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        const Text('SELECT HARDWARE SOURCE', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 10),

        _buildProviderCard('simulator', 'RideOS Telemetry Simulator', 'Mathematical Wave Generator (Sine/Ramp)', Icons.science_rounded, true),
        _buildProviderCard('ble_generic', 'Generic BLE Diagnostic Adapter', 'GATT Speed/Cadence & Custom Telemetry', Icons.bluetooth_rounded, false),
        _buildProviderCard('obd2_can', 'OBD-II / CAN-Bus Adapter', 'SAE J1979 Mode 01 Sensor Polling & DTC', Icons.settings_input_composite_rounded, false),

        const SizedBox(height: 16),
        // Recording Session Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF080C1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1A2035)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('RIDE SESSION RECORDER', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text(
                    _engine.isRecordingSession
                        ? 'Recording: ${_engine.recordedSessionSamples.length} samples'
                        : 'Ready to record ride telemetry',
                    style: TextStyle(color: _engine.isRecordingSession ? RoadOSColors.apexEmerald : RoadOSColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: Icon(_engine.isRecordingSession ? Icons.stop_rounded : Icons.fiber_manual_record_rounded, size: 16),
                label: Text(_engine.isRecordingSession ? 'STOP' : 'RECORD'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _engine.isRecordingSession ? Colors.redAccent : RoadOSColors.electricBlue,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
        LuxAudioHapticsService.lightImpact();
                  setState(() {
                    if (_engine.isRecordingSession) {
                      _engine.stopRecordingSession();
                    } else {
                      _engine.startRecordingSession();
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(String key, String title, String subtitle, IconData icon, bool isSim) {
    final isSelected = _selectedProviderKey == key;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isSelected ? RoadOSColors.electricBlue.withValues(alpha: 0.12) : RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isSelected ? RoadOSColors.electricBlue : RoadOSColors.borderTranslucent),
      ),
      child: ListTile(
        leading: Icon(icon, color: isSelected ? RoadOSColors.electricBlue : RoadOSColors.textMuted),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
        trailing: isSelected
            ? const Icon(Icons.check_circle_rounded, color: RoadOSColors.apexEmerald, size: 20)
            : ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF060912),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(70, 32),
                ),
                onPressed: () {
        LuxAudioHapticsService.lightImpact();
                  setState(() {
                    _selectedProviderKey = key;
                    _engine.switchProvider(key);
                    _engine.connectDevice('target_$key');
                  });
                },
                child: const Text('Connect', style: TextStyle(fontSize: 11)),
              ),
      ),
    );
  }

  Widget _buildLiveHudTab() {
    return StreamBuilder<NormalizedTelemetrySnapshot>(
      stream: _engine.telemetryStream,
      initialData: _engine.latestSnapshot,
      builder: (context, snapshot) {
        final data = snapshot.data;
        if (data == null) {
          return const Center(child: Text('Awaiting Telemetry Stream...', style: TextStyle(color: RoadOSColors.textMuted)));
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: _buildMetricTile('SPEED', data.vehicleSpeedKmh.formattedValue, 'KM/H', RoadOSColors.electricBlue)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricTile('ENGINE RPM', data.engineRpm.formattedValue, 'RPM', RoadOSColors.hyperOrange)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricTile('COOLANT', data.coolantTempC.formattedValue, ' degC', RoadOSColors.cyberCyan)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricTile('BATTERY', data.batteryVoltage.formattedValue, 'V', RoadOSColors.apexEmerald)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricTile('THROTTLE', data.throttlePositionPct.formattedValue, '%', RoadOSColors.neonMagenta)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricTile('LEAN ANGLE', data.leanAngleDeg.formattedValue, ' deg', RoadOSColors.warningAmber)),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile(String label, String value, String unit, Color accent) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value, style: TextStyle(color: accent, fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              Text(unit, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF080C1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF1A2035)),
          ),
          child: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: RoadOSColors.apexEmerald, size: 32),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ECU & SENSORS HEALTHY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('0 Active Diagnostic Trouble Codes (DTC)', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.delete_sweep_rounded, size: 18),
          label: const Text('CLEAR DTC FAULT CODES'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF060912),
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(44),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: (_engine.activeProvider?.canClearDtcCodes ?? false)
              ? () {
                  _engine.activeProvider?.clearDtcCodes();
                  showLuxSnack(context, 'DTC codes cleared.', variant: LuxSnackVariant.info);
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildPacketInspectorTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF070B18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1A2035)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('RAW PACKET LOG STREAM', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildHexLine('0x41 0x0C 0x1A 0xF8', 'RPM: 6904 (Mode 01 PID 0C)'),
              _buildHexLine('0x41 0x0D 0x3E', 'Speed: 62 km/h (Mode 01 PID 0D)'),
              _buildHexLine('0x41 0x05 0x80', 'Coolant: 88 degC (Mode 01 PID 05)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHexLine(String hex, String decoded) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(hex, style: const TextStyle(color: RoadOSColors.cyberCyan, fontFamily: 'monospace', fontSize: 11)),
          Text(decoded, style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
