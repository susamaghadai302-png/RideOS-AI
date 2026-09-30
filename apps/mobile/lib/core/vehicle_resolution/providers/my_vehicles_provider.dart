import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/vehicle_profile.dart';
import '../repositories/my_vehicles_repository.dart';

final myVehiclesProvider = StateNotifierProvider<MyVehiclesNotifier, List<VehicleProfile>>((ref) {
  return MyVehiclesNotifier();
});

class MyVehiclesNotifier extends StateNotifier<List<VehicleProfile>> {
  final MyVehiclesRepository repository;

  MyVehiclesNotifier({MyVehiclesRepository? repository})
      : repository = repository ?? MyVehiclesRepository(),
        super([]) {
    _load();
  }

  Future<void> _load() async {
    final vehicles = await repository.getOwnedVehicles();
    if (!mounted) return;
    state = vehicles;
  }

  Future<void> addVehicle(VehicleProfile profile) async {
    await repository.addOwnedVehicle(profile);
    await _load();
  }

  Future<void> associateDevice(String macAddress, String vehicleId) async {
    await repository.associateMacWithVehicle(macAddress, vehicleId);
  }
}
