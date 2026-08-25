import 'package:flutter/material.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_connectivity/services/connection_diagnostics_service.dart';
import 'vehicle_connection_lab_screen.dart';
import '../../../../core/design_system/premium_navigation.dart';

class ConnectionDiagnosticsScreen extends StatefulWidget {
  const ConnectionDiagnosticsScreen({super.key});

  @override
  State<ConnectionDiagnosticsScreen> createState() => _ConnectionDiagnosticsScreenState();
}

class _ConnectionDiagnosticsScreenState extends State<ConnectionDiagnosticsScreen> {
  late Future<ConnectionDiagnosticMetrics> _diagnosticsFuture;

  @override
  void initState() {
    super.initState();
    _refreshDiagnostics();
  }

  void _refreshDiagnostics() {
    setState(() {
      _diagnosticsFuture = ConnectionDiagnosticsService().getLiveDiagnostics();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'CONNECTION DIAGNOSTICS',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: RoadOSColors.electricBlue),
            onPressed: _refreshDiagnostics,
          ),
        ],
      ),
      body: CinematicBackground(child: FutureBuilder<ConnectionDiagnosticMetrics>(
        future: _diagnosticsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: RoadOSColors.electricBlue),
            );
          }

          final d = snapshot.data!;
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildHeaderCard(d),
              const SizedBox(height: 20),
              _buildSectionTitle('RADIO & HARDWARE LAYER'),
              _buildDiagnosticTile('Bluetooth Permissions', d.isBluetoothPermissionGranted ? 'Granted' : 'Denied', d.isBluetoothPermissionGranted),
              _buildDiagnosticTile('Bluetooth 5.0 Radio', d.isBluetoothRadioEnabled ? 'Enabled / Ready' : 'Disabled', d.isBluetoothRadioEnabled),
              _buildDiagnosticTile('BLE Scanner State', d.isBleScanningActive ? 'Active Scan' : 'Standby', true),
              const SizedBox(height: 20),
              _buildSectionTitle('OPERATIONAL LINK STATUS'),
              _buildDiagnosticTile('GATT Services Discovered', '${d.discoveredCharacteristicsCount} Characteristics', d.discoveredCharacteristicsCount > 0),
              _buildDiagnosticTile('Current Diagnostic State', d.connectionStatus, true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.biotech_rounded),
                  label: const Text('OPEN PROTOCOL VERIFICATION LAB', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RoadOSColors.electricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
        LuxAudioHapticsService.lightImpact();
                    Navigator.push(context, premiumRoute(const VehicleConnectionLabScreen()));
                  },
                ),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('TELEMETRY & LINK METRICS'),
              _buildDiagnosticTile('Pairing Status', d.isPaired ? 'Bonded / Paired' : 'Unpaired', d.isPaired),
              _buildDiagnosticTile('Authentication Stream', d.isAuthenticated ? 'Verified' : 'Pending', d.isAuthenticated),
              _buildDiagnosticTile('Connection Latency', '${d.latencyMs.toStringAsFixed(1)} ms', d.latencyMs < 50),
              _buildDiagnosticTile('Telemetry Packets', '${d.packetsReceived} packets', true),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('RUN DIAGNOSTIC HEALTH CHECK', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RoadOSColors.electricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _refreshDiagnostics,
                ),
              ),
            ],
          );
        },
      )),
    );
  }

  Widget _buildHeaderCard(ConnectionDiagnosticMetrics d) {
    final isConnected = d.connectionStatus == 'CONNECTED';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected ? RoadOSColors.apexEmerald.withValues(alpha: 0.5) : RoadOSColors.borderTranslucent,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConnected ? RoadOSColors.apexEmerald.withValues(alpha: 0.15) : Colors.white10,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConnected ? Icons.bluetooth_connected_rounded : Icons.bluetooth_searching_rounded,
              color: isConnected ? RoadOSColors.apexEmerald : RoadOSColors.electricBlue,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.connectionStatus,
                  style: TextStyle(
                    color: isConnected ? RoadOSColors.apexEmerald : RoadOSColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  d.deviceMacOrUuid ?? 'Awaiting device association',
                  style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: RoadOSColors.electricBlue,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDiagnosticTile(String title, String value, bool isPositive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: RoadOSColors.borderTranslucent),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 13)),
          Row(
            children: [
              Icon(
                isPositive ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: isPositive ? RoadOSColors.apexEmerald : RoadOSColors.warningAmber,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                value,
                style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
