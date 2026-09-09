import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/widgets/roados_visual_environment.dart';
import '../../core/services/obd_full_telemetry_service.dart';
import '../widgets/connected_platform_widgets.dart';
import '../../../../core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

class ObdDiagnosticsScreen extends StatefulWidget {
  const ObdDiagnosticsScreen({super.key});

  @override
  State<ObdDiagnosticsScreen> createState() => _ObdDiagnosticsScreenState();
}

class _ObdDiagnosticsScreenState extends State<ObdDiagnosticsScreen> {
  late bool _isSimulated;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _isSimulated = ObdFullTelemetryService().isSimulatorMode;
  }

  @override
  Widget build(BuildContext context) {
    final telemetry = ObdFullTelemetryService().getLatestTelemetry();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RoadOSColors.platinumWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'OBD-II CAN-BUS DIAGNOSTICS',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: RoadOSColors.cyberCyan, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: RoadOSVisualEnvironment(
        environmentType: RoadOSEnvironmentType.notifications,
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: LuxResponsiveContainer(
              child: Column(
                children: [
                  // Data Source Banner
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _isSimulated ? Colors.amber.withValues(alpha: 0.15) : RoadOSColors.cyberCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _isSimulated ? Colors.amberAccent.withValues(alpha: 0.4) : RoadOSColors.cyberCyan.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Icon(_isSimulated ? Icons.tune_rounded : Icons.sensors_rounded, color: _isSimulated ? Colors.amberAccent : RoadOSColors.cyberCyan, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _isSimulated ? 'DATA SOURCE: SYNTHETIC ISO 15765 SIMULATOR' : 'DATA SOURCE: PHYSICAL ELM327 BLE HARDWARE',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: _isSimulated ? Colors.amberAccent : RoadOSColors.cyberCyan,
                              letterSpacing: 0.9,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // CAN-BUS Connection Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: _isConnected ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: (_isConnected ? RoadOSColors.apexEmerald : RoadOSColors.errorCrimson).withValues(alpha: 0.6),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isConnected ? 'CAN-BUS ISO 15765-4 | 500kbps Active' : 'Bluetooth Adapter Disconnected',
                            style: const TextStyle(fontSize: 11, color: RoadOSColors.textMuted, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(
                          _isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_searching_rounded,
                          color: RoadOSColors.cyberCyan,
                          size: 20,
                        ),
                        onPressed: () {
                          LuxAudioHapticsService.selectionClick();
                          setState(() => _isConnected = !_isConnected);
                        },
                        tooltip: _isConnected ? 'Disconnect BLE' : 'Connect BLE',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // TPMS Sensors
                  TpmsTireVisualizerWidget(
                    frontPsi: _isConnected ? (telemetry.frontTirePsi ?? 36.0) : 0.0,
                    rearPsi: _isConnected ? (telemetry.rearTirePsi ?? 42.0) : 0.0,
                    tireTempC: _isConnected ? (telemetry.tireTempC ?? 32.0) : 0.0,
                    lowPressureWarning: telemetry.lowPressureWarning,
                  ),
                  const SizedBox(height: 16),

                  // Full OBD-II Diagnostics Grid
                  FullObd2DiagnosticsGridWidget(
                    rpm: _isConnected ? (telemetry.engineRpm ?? 0) : 0,
                    coolantTemp: _isConnected ? (telemetry.coolantTempC ?? 0) : 0,
                    batteryVoltage: _isConnected ? (telemetry.batteryVoltage ?? 0) : 0,
                    throttlePct: _isConnected ? (telemetry.throttlePositionPct ?? 0) : 0,
                    fuelLevelPct: _isConnected ? (telemetry.fuelLevelPct ?? 0) : 0,
                    fuelConsL100: _isConnected ? (telemetry.fuelConsumptionLitersPer100Km ?? 0) : 0,
                    engineLoadPct: _isConnected ? (telemetry.engineLoadPct ?? 0) : 0,
                    oilTempC: _isConnected ? (telemetry.oilTempC ?? 0) : 0,
                    airIntakeTempC: _isConnected ? (telemetry.airIntakeTempC ?? 0) : 0,
                    o2Volts: _isConnected ? (telemetry.oxygenSensorVolts ?? 0) : 0,
                    checkEngine: telemetry.checkEngineLight,
                  ),
                  const SizedBox(height: 16),

                  // Smart Helmet Mesh Link
                  const SmartHelmetConnectivityWidget(),
                  const SizedBox(height: 16),

                  // Ride Telemetry Analytics Summary
                  const RideAnalyticsSummaryWidget(),
                  const SizedBox(height: 16),

                  // Smart Garage AI Vault Summary
                  const SmartGarageVaultWidget(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
