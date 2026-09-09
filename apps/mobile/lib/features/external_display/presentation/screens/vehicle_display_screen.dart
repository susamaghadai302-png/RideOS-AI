import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/vehicle_resolution/services/vehicle_connection_manager.dart';
import '../../../../core/design_system/roados_tokens.dart';

class VehicleDisplayScreen extends ConsumerWidget {
  const VehicleDisplayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(vehicleConnectionManagerProvider);
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // Left Sidebar (Status, Time, Connection)
          Container(
            width: 280,
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: RoadOSColors.borderSubtle, width: 1)),
              color: Color(0xFF0F1423),
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RideOS', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 32),
                _buildStatusRow(Icons.bluetooth_connected, 'Vehicle', connectionState.connectedDeviceName, Colors.greenAccent),
                const SizedBox(height: 16),
                _buildStatusRow(Icons.phone_android, 'Calling', connectionState.isCallingAvailable ? 'Ready' : 'Not Configured', connectionState.isCallingAvailable ? Colors.greenAccent : Colors.orangeAccent),
                const SizedBox(height: 16),
                _buildStatusRow(Icons.navigation, 'Navigation', connectionState.isNavigationReady ? 'Active' : 'Standby', connectionState.isNavigationReady ? Colors.blueAccent : Colors.white54),
                const Spacer(),
                Text(
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w300),
                ),
                Text(
                  '${now.day}/${now.month}/${now.year}',
                  style: GoogleFonts.outfit(color: Colors.white54, fontSize: 16),
                ),
              ],
            ),
          ),
          
          // Main Body (Navigation Map placeholder representing secondary display map view)
          Expanded(
            child: Stack(
              children: [
                // Simulated map or actual map component if API provided
                Container(color: const Color(0xFF1B2338)),
                
                if (connectionState.isNavigationReady)
                  Positioned(
                    top: 24,
                    left: 24,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: RoadOSColors.borderSubtle),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.turn_right, color: Colors.white, size: 48),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('300 ft', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                              Text('Turn right onto Main St', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String title, String value, Color statusColor) {
    return Row(
      children: [
        Icon(icon, color: statusColor, size: 24),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12)),
            Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
          ],
        )
      ],
    );
  }
}
