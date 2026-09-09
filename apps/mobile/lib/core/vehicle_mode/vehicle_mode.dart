import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../vehicle_resolution/models/vehicle_profile.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  VEHICLE MODE — The core concept that drives UI selection
// ─────────────────────────────────────────────────────────────────────────────

/// The primary driving/riding context that determines which HUD is shown.
enum VehicleMode {
  car,
  bike,
  scooter;

  String get displayName {
    switch (this) {
      case VehicleMode.car:
        return 'Car';
      case VehicleMode.bike:
        return 'Bike';
      case VehicleMode.scooter:
        return 'Scooter';
    }
  }

  String get icon {
    switch (this) {
      case VehicleMode.car:
        return '🚗';
      case VehicleMode.bike:
        return '🏍️';
      case VehicleMode.scooter:
        return '🛵';
    }
  }

  /// Whether this mode should prioritize large minimal controls
  bool get isRiderMode => this == VehicleMode.bike || this == VehicleMode.scooter;
}

// ─────────────────────────────────────────────────────────────────────────────
//  PERSISTENCE KEY
// ─────────────────────────────────────────────────────────────────────────────

const _kVehicleModeKey = 'rideos_vehicle_mode';
const _kVehicleModeSelectedKey = 'rideos_vehicle_mode_selected';

// ─────────────────────────────────────────────────────────────────────────────
//  RIVERPOD STATE NOTIFIER
// ─────────────────────────────────────────────────────────────────────────────

class VehicleModeNotifier extends StateNotifier<VehicleMode> {
  VehicleModeNotifier() : super(VehicleMode.bike);

  /// Load persisted mode on startup
  Future<void> loadPersistedMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_kVehicleModeKey);
      if (stored != null) {
        state = VehicleMode.values.firstWhere(
          (m) => m.name == stored,
          orElse: () => VehicleMode.bike,
        );
      }
    } catch (_) {}
  }

  /// Set mode and persist it
  Future<void> setMode(VehicleMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kVehicleModeKey, mode.name);
      await prefs.setBool(_kVehicleModeSelectedKey, true);
    } catch (_) {}
  }

  /// Auto-infer mode from a VehicleProfile's category
  Future<void> inferFromProfile(VehicleProfile profile) async {
    final category = VehicleCategory.fromString(profile.category);
    VehicleMode mode;
    switch (category) {
      case VehicleCategory.car:
      case VehicleCategory.electricCar:
        mode = VehicleMode.car;
        break;
      case VehicleCategory.scooter:
      case VehicleCategory.electricScooter:
        mode = VehicleMode.scooter;
        break;
      default:
        mode = VehicleMode.bike;
    }
    await setMode(mode);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  PROVIDERS
// ─────────────────────────────────────────────────────────────────────────────

final vehicleModeProvider = StateNotifierProvider<VehicleModeNotifier, VehicleMode>((ref) {
  return VehicleModeNotifier();
});

/// Whether the user has explicitly selected a vehicle mode at least once.
/// Used to decide whether to show the VehicleModeSelectorScreen.
final vehicleModeSelectedProvider = FutureProvider<bool>((ref) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kVehicleModeSelectedKey) ?? false;
  } catch (_) {
    return false;
  }
});
