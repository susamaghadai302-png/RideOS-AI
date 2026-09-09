import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_resolution/services/vehicle_connection_manager.dart';

class ConnectionCenterScreen extends ConsumerWidget {
  const ConnectionCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(vehicleConnectionManagerProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Connection Center', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _buildStatusCard(
            'Connected Device',
            connectionState.connectedDeviceName,
            Icons.device_hub,
            connectionState.connectedDeviceName != 'None' ? Colors.greenAccent : Colors.white54,
          ),
          const SizedBox(height: 16),
          _buildStatusCard(
            'Connection Method',
            connectionState.displayCapability.protocol.name.toUpperCase(),
            Icons.settings_input_component,
            Colors.blueAccent,
          ),
          const SizedBox(height: 16),
          _buildStatusCard(
            'Display Status',
            connectionState.displayCapability.status.name.toUpperCase(),
            Icons.monitor,
            connectionState.displayCapability.status.name == 'ready' ? Colors.greenAccent : Colors.orangeAccent,
          ),
          const SizedBox(height: 16),
          _buildStatusCard(
            'Navigation Status',
            connectionState.isNavigationReady ? 'READY' : 'STANDBY',
            Icons.navigation,
            connectionState.isNavigationReady ? Colors.greenAccent : Colors.white54,
          ),
          const SizedBox(height: 16),
          _buildStatusCard(
            'Calling Status',
            connectionState.isCallingAvailable ? 'AVAILABLE' : 'UNAVAILABLE',
            Icons.phone_in_talk,
            connectionState.isCallingAvailable ? Colors.greenAccent : Colors.redAccent,
          ),
          const SizedBox(height: 16),
          _buildStatusCard(
            'GPS Status',
            connectionState.isGpsReady ? 'READY' : 'SEARCHING',
            Icons.gps_fixed,
            connectionState.isGpsReady ? Colors.greenAccent : Colors.orangeAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color statusColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF101520),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RoadOSColors.borderSubtle, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: statusColor, size: 32),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
