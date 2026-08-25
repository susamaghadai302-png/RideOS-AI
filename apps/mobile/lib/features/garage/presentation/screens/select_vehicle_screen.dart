import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/vehicle_resolution/providers/my_vehicles_provider.dart';
import 'add_vehicle_screen.dart';
import '../../../../core/design_system/premium_navigation.dart';

class SelectVehicleScreen extends ConsumerWidget {
  final String macAddress;

  const SelectVehicleScreen({super.key, required this.macAddress});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ownedVehicles = ref.watch(myVehiclesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Select Vehicle', style: TextStyle(color: Colors.cyan)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.orange.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Device connected, but vehicle identity is unavailable. Please select which vehicle this device belongs to.',
                    style: const TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ownedVehicles.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('You have no vehicles.', style: TextStyle(color: Colors.white54)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                          onPressed: () => Navigator.push(context, premiumRoute(const AddVehicleScreen())),
                          child: const Text('ADD VEHICLE', style: TextStyle(color: Colors.black)),
                        )
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: ownedVehicles.length,
                    itemBuilder: (context, index) {
                      final v = ownedVehicles[index];
                      return ListTile(
                        leading: const Icon(Icons.two_wheeler, color: Colors.cyan),
                        title: Text(v.fullName, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(v.category, style: const TextStyle(color: Colors.white54)),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan),
                          onPressed: () {
        LuxAudioHapticsService.lightImpact();
                            ref.read(myVehiclesProvider.notifier).associateDevice(macAddress, v.id);
                            Navigator.pop(context, v);
                          },
                          child: const Text('SELECT', style: TextStyle(color: Colors.black)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
