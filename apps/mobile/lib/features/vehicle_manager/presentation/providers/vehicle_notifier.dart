import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'vehicle_state.dart';
import '../../domain/entities/motorcycle_entity.dart';
import '../../../auth/data/models/rider_model.dart';

class VehicleNotifier extends StateNotifier<VehicleState> {
  static const String _garagePrefsKey = 'rideos_saved_garage_v1';
  static const String _activeBikePrefsKey = 'rideos_active_bike_id_v1';

  VehicleNotifier() : super(const VehicleState()) {
    loadSavedVehicles();
  }

  Future<void> loadSavedVehicles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedGarageJson = prefs.getStringList(_garagePrefsKey);
      final savedActiveId = prefs.getString(_activeBikePrefsKey);

      if (savedGarageJson != null && savedGarageJson.isNotEmpty) {
        final List<MotorcycleEntity> loadedGarage = savedGarageJson.map((jsonStr) {
          final Map<String, dynamic> map = jsonDecode(jsonStr) as Map<String, dynamic>;
          return MotorcycleModel.fromJson(map);
        }).toList();

        MotorcycleEntity? active;
        if (savedActiveId != null) {
          active = loadedGarage.firstWhere(
            (b) => b.bikeId == savedActiveId,
            orElse: () => loadedGarage.first,
          );
        } else {
          active = loadedGarage.firstWhere((b) => b.isPrimary, orElse: () => loadedGarage.first);
        }

        state = state.copyWith(garage: loadedGarage, activeMotorcycle: active);
      }
    } catch (e) {
      debugPrint('[VehicleNotifier] Error loading saved garage: $e');
    }
  }

  Future<void> _persistGarage(List<MotorcycleEntity> garage, String? activeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String> encodedList = garage.map((bike) {
        final model = MotorcycleModel(
          bikeId: bike.bikeId,
          make: bike.make,
          model: bike.model,
          year: bike.year,
          engineCC: bike.engineCC,
          maxLeanAngleLimit: bike.maxLeanAngleLimit,
          isPrimary: bike.isPrimary,
          frontPsi: bike.frontPsi,
          rearPsi: bike.rearPsi,
          imageUrl: bike.imageUrl,
          topSpeed: bike.topSpeed,
          horsePower: bike.horsePower,
          weightKg: bike.weightKg,
          aiHealthScore: bike.aiHealthScore,
          liveryColorHex: bike.liveryColorHex,
        );
        return jsonEncode(model.toJson());
      }).toList();

      await prefs.setStringList(_garagePrefsKey, encodedList);
      if (activeId != null) {
        await prefs.setString(_activeBikePrefsKey, activeId);
      }
    } catch (e) {
      debugPrint('[VehicleNotifier] Error persisting garage: $e');
    }
  }

  void setInitialGarage(List<MotorcycleEntity> garage) {
    if (garage.isEmpty) return;
    final primary = garage.firstWhere((b) => b.isPrimary, orElse: () => garage.first);
    state = state.copyWith(garage: garage, activeMotorcycle: primary);
    _persistGarage(garage, primary.bikeId);
  }

  void addMotorcycle(MotorcycleEntity bike) {
    final updatedGarage = [...state.garage, bike];
    final active = state.activeMotorcycle ?? bike;
    state = state.copyWith(garage: updatedGarage, activeMotorcycle: active);
    _persistGarage(updatedGarage, active.bikeId);
  }

  void updateMotorcycle(MotorcycleEntity updatedBike) {
    final updatedGarage = state.garage.map((b) => b.bikeId == updatedBike.bikeId ? updatedBike : b).toList();
    final active = state.activeMotorcycle?.bikeId == updatedBike.bikeId ? updatedBike : state.activeMotorcycle;
    state = state.copyWith(garage: updatedGarage, activeMotorcycle: active);
    _persistGarage(updatedGarage, active?.bikeId);
  }

  void deleteMotorcycle(String bikeId) {
    final updatedGarage = state.garage.where((b) => b.bikeId != bikeId).toList();
    MotorcycleEntity? active = state.activeMotorcycle;
    if (active?.bikeId == bikeId) {
      active = updatedGarage.isNotEmpty ? updatedGarage.first : null;
    }
    state = state.copyWith(garage: updatedGarage, activeMotorcycle: active);
    _persistGarage(updatedGarage, active?.bikeId);
  }

  void selectActiveMotorcycle(String bikeId) {
    if (state.garage.isEmpty) return;
    final selected = state.garage.firstWhere(
      (b) => b.bikeId == bikeId,
      orElse: () => state.garage.first,
    );
    state = state.copyWith(activeMotorcycle: selected);
    _persistGarage(state.garage, selected.bikeId);
  }
}

final vehicleNotifierProvider =
    StateNotifierProvider<VehicleNotifier, VehicleState>((ref) {
  return VehicleNotifier();
});
