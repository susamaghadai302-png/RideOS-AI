import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/vehicle_protocols/models/normalized_telemetry.dart';
import '../../../../core/bluetooth/bluetooth_engine.dart';
import '../../../../core/bluetooth/models/bluetooth_connection_state.dart' as AppState;

class ConnectionMonitorScreen extends ConsumerWidget {
  const ConnectionMonitorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeAdapter = ref.watch(activeAdapterProvider);
    final state = ref.watch(bluetoothStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF040711),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('CONNECTION MONITOR', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(state, activeAdapter),
            const SizedBox(height: 24),
            Expanded(
              child: activeAdapter == null
                  ? const Center(child: Text('NO ACTIVE ADAPTER', style: TextStyle(color: Colors.white24)))
                  : StreamBuilder<NormalizedTelemetry>(
                      stream: activeAdapter.telemetryStream,
                      builder: (context, snapshot) {
                        final q = snapshot.data?.connectionQuality.value ?? 0;
                        final available = snapshot.data?.connectionQuality.available ?? false;
                        
                        return Column(
                          children: [
                            const Text('SIGNAL STRENGTH', style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 2)),
                            const SizedBox(height: 32),
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 200,
                                  height: 200,
                                  child: CircularProgressIndicator(
                                    value: available ? q / 100.0 : 0.0,
                                    strokeWidth: 12,
                                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                                    color: _getSignalColor(q),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      available ? '$q%' : 'N/A',
                                      style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900),
                                    ),
                                    const SizedBox(height: 8),
                                    Icon(
                                      available ? Icons.signal_cellular_alt : Icons.signal_cellular_connected_no_internet_4_bar,
                                      color: available ? _getSignalColor(q) : Colors.red,
                                      size: 32,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(AppState.BluetoothConnectionState state, dynamic activeAdapter) {
    bool isConnected = state == AppState.BluetoothConnectionState.connected || state == AppState.BluetoothConnectionState.streaming;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isConnected ? Colors.cyan.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled, color: isConnected ? Colors.cyan : Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(state.name.toUpperCase(), style: TextStyle(color: isConnected ? Colors.white : Colors.red, fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(activeAdapter != null ? 'Protocol: ${activeAdapter.adapterId}' : 'No Protocol Active', style: const TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Color _getSignalColor(int quality) {
    if (quality > 70) return Colors.greenAccent;
    if (quality > 30) return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
