import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;
import '../../../../core/design_system/design_tokens.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../../../../core/bluetooth/bluetooth_engine.dart';
import '../../../../core/bluetooth/models/bluetooth_connection_state.dart' as AppState;
import 'gatt_diagnostic_screen.dart';
import '../../../../core/design_system/premium_navigation.dart';

class DeviceScannerScreen extends ConsumerStatefulWidget {
  const DeviceScannerScreen({super.key});

  @override
  ConsumerState<DeviceScannerScreen> createState() => _DeviceScannerScreenState();
}

class _DeviceScannerScreenState extends ConsumerState<DeviceScannerScreen> {
  Stream<List<ScanResult>>? _scanStream;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _startScan();
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    try {
      final stream = await BluetoothEngine().scanner.startScan();
      setState(() => _scanStream = stream);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _stopScan() {
    BluetoothEngine().scanner.stopScan();
    setState(() => _isScanning = false);
  }

  @override
  void dispose() {
    _stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(bluetoothStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Discover Vehicles', style: TextStyle(color: Colors.cyan)),
        actions: [
          if (_isScanning)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyan)),
            )
          else
            IconButton(icon: const Icon(Icons.refresh, color: Colors.cyan), onPressed: _startScan),
          IconButton(
            icon: const Icon(Icons.developer_mode, color: Colors.grey),
            onPressed: () => Navigator.push(context, premiumRoute(const GattDiagnosticScreen())),
          )
        ],
      ),
      body: Column(
        children: [
          if (connectionState != AppState.BluetoothConnectionState.idle && connectionState != AppState.BluetoothConnectionState.disconnected)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.cyan.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.cyan),
                  const SizedBox(width: 12),
                  Text('State: ${connectionState.name.toUpperCase()}', style: const TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Expanded(
            child: _scanStream == null ? const Center(child: Text('Initializing scanner...')) : StreamBuilder<List<ScanResult>>(
              stream: _scanStream,
              initialData: const [],
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No vehicles found nearby.', style: TextStyle(color: Colors.white54)));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final result = snapshot.data![index];
                    return ListTile(
                      leading: Icon(Icons.bluetooth, color: result.rssi > -70 ? Colors.green : Colors.orange),
                      title: Text(result.device.advName.isNotEmpty ? result.device.advName : 'Unknown Device', style: const TextStyle(color: Colors.white)),
                      subtitle: Text('${result.device.remoteId} | RSSI: ${result.rssi}', style: const TextStyle(color: Colors.white54)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                        onPressed: () {
        LuxAudioHapticsService.lightImpact();
                          _stopScan();
                          // Production flag would be true in a real build
                          BluetoothEngine().connectAndResolve(result.device, false);
                          Navigator.pop(context);
                        },
                        child: const Text('CONNECT'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
