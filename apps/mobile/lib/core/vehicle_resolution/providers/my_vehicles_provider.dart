import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_profile.dart';
import '../repositories/my_vehicles_repository.dart';

final myVehiclesProvider = StateNotifierProvider<MyVehiclesNotifier, List<VehicleProfile>>((ref) {
  return MyVehiclesNotifier();
});

class MyVehiclesNotifier extends StateNotifier<List<VehicleProfile>> {
  MyVehiclesNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final vehicles = await MyVehiclesRepository().getOwnedVehicles();
    if (!mounted) return;
    state = vehicles;
  }

  Future<void> addVehicle(VehicleProfile profile) async {
    await MyVehiclesRepository().addOwnedVehicle(profile);
    await _load();
  }

  Future<void> associateDevice(String macAddress, String vehicleId) async {
    await MyVehiclesRepository().associateMacWithVehicle(macAddress, vehicleId);
  }
}
