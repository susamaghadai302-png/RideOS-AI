import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_protocols/models/normalized_telemetry.dart';
import '../../../../core/bluetooth/bluetooth_engine.dart';
import '../../../../core/bluetooth/models/bluetooth_connection_state.dart' as AppState;

class VehicleHealthScreen extends ConsumerWidget {
  const VehicleHealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAdapter = ref.watch(activeAdapterProvider);
    final state = ref.watch(bluetoothStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF040711),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('DIAGNOSTICS & HEALTH', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
      ),
      body: activeAdapter == null
          ? const Center(child: Text('NOT CONNECTED TO VEHICLE', style: TextStyle(color: Colors.white54)))
          : StreamBuilder<NormalizedTelemetry>(
              stream: activeAdapter.telemetryStream,
              builder: (context, snapshot) {
                if (state != AppState.BluetoothConnectionState.streaming) {
                  return const Center(child: Text('AWAITING TELEMETRY STREAM...', style: TextStyle(color: Colors.white54)));
                }
                
                final telemetry = snapshot.data ?? NormalizedTelemetry.empty();
                
                return ListView(
                  padding: const EdgeInsets.all(24.0),
                  children: [
                    _buildHealthCard('ENGINE STATE', telemetry.engineState.available ? telemetry.engineState.value : 'UNAVAILABLE', telemetry.engineState.available),
                    _buildHealthCard('IGNITION', telemetry.ignitionState.available ? telemetry.ignitionState.value : 'UNAVAILABLE', telemetry.ignitionState.available),
                    _buildHealthCard('ABS STATUS', telemetry.abs.available ? (telemetry.abs.value == true ? 'ENGAGED' : 'READY') : 'UNAVAILABLE', telemetry.abs.available),
                    _buildHealthCard('TRACTION CONTROL', telemetry.tractionControl.available ? 'LEVEL ${telemetry.tractionControl.value}' : 'UNAVAILABLE', telemetry.tractionControl.available),
                    
                    const SizedBox(height: 32),
                    const Text('FAULT CODES', style: TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    const SizedBox(height: 16),
                    _buildFaultCodes(telemetry),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildHealthCard(String title, dynamic value, bool isAvailable) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF14192A),
            const Color(0xFF080C1A),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.0),
          left: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1.0),
          right: BorderSide(color: Colors.black.withValues(alpha: 0.2), width: 1.0),
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.4), width: 2.0), // Extrusion
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            spreadRadius: -2,
            offset: const Offset(0, 6), // Drop shadow
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
          Text(
            '$value',
            style: TextStyle(
              color: isAvailable ? RoadOSColors.textPrimary : RoadOSColors.textMuted, 
              fontSize: 16, 
              fontWeight: FontWeight.bold
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaultCodes(NormalizedTelemetry telemetry) {
    if (!telemetry.faultCodes.available) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF14192A), Color(0xFF080C1A)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1.0),
            left: BorderSide(color: Colors.white.withValues(alpha: 0.05), width: 1.0),
            right: BorderSide(color: Colors.black.withValues(alpha: 0.2), width: 1.0),
            bottom: BorderSide(color: Colors.black.withValues(alpha: 0.4), width: 2.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Center(child: Text('DIAGNOSTIC DATA UNAVAILABLE', style: TextStyle(color: RoadOSColors.textMuted, fontWeight: FontWeight.bold))),
      );
    }

    final codes = telemetry.faultCodes.value ?? [];
    if (codes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              RoadOSColors.apexEmerald.withValues(alpha: 0.15),
              RoadOSColors.apexEmerald.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border(
            top: BorderSide(color: RoadOSColors.apexEmerald.withValues(alpha: 0.4), width: 1.0),
            left: BorderSide(color: RoadOSColors.apexEmerald.withValues(alpha: 0.2), width: 1.0),
            right: BorderSide(color: Colors.black.withValues(alpha: 0.2), width: 1.0),
            bottom: BorderSide(color: Colors.black.withValues(alpha: 0.4), width: 2.0),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              spreadRadius: -2,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: RoadOSColors.apexEmerald),
            SizedBox(width: 12),
            Text('NO FAULT CODES DETECTED', style: TextStyle(color: RoadOSColors.apexEmerald, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return Column(
      children: codes.map((code) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: RoadOSColors.errorCrimson.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: RoadOSColors.errorCrimson.withValues(alpha: 0.3))),
        child: Row(
          children: [
            const Icon(Icons.warning, color: RoadOSColors.errorCrimson),
            const SizedBox(width: 12),
            Text(code, style: const TextStyle(color: RoadOSColors.errorCrimson, fontWeight: FontWeight.bold)),
          ],
        ),
      )).toList(),
    );
  }
}
