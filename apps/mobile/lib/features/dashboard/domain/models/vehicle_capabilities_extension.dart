import 'package:rideos_mobile/core/vehicle_resolution/models/active_vehicle_context.dart';

extension ActiveVehicleContextCapabilitiesX on ActiveVehicleContext {
  bool get hasFuel {
    final cat = profile?.category ?? 'motorcycle';
    final fuel = (profile?.fuelType ?? 'petrol').toLowerCase();
    if (cat == 'electric_motorcycle' || cat == 'electric_car' || cat == 'electric_scooter' || fuel == 'electric') {
      return false;
    }
    return true;
  }

  bool get hasRpm {
    // EVs typically don't expose engine RPM in the traditional sense
    return hasFuel;
  }

  bool get hasLeanAngle {
    final cat = profile?.category ?? 'motorcycle';
    return cat == 'motorcycle' || cat == 'scooter' || cat == 'electric_motorcycle' || cat == 'electric_scooter';
  }

  int get tpmsSensorCount {
    final cat = profile?.category ?? 'motorcycle';
    if (cat == 'car' || cat == 'electric_car') {
      return 4;
    }
    return 2;
  }

  List<String> get tpmsSensorLabels {
    if (tpmsSensorCount == 4) {
      return ['FL', 'FR', 'RL', 'RR'];
    }
    return ['FRONT', 'REAR'];
  }

  double? get maxSpeedKmh {
    return profile?.topSpeedKmh?.toDouble();
  }

  /// Returns null when no manufacturer RPM spec is available in VehicleProfile.
  /// The UI must show CONFIGURATION REQUIRED or hide the tachometer.
  double? get maxRpm {
    // VehicleProfile does not currently carry maxRpm — return null until
    // the profile is extended with manufacturer specs.
    return null;
  }

  /// Returns null when no manufacturer redline spec is available.
  double? get redlineRpm {
    return null;
  }

  /// Returns null when no manufacturer tire pressure spec is available.
  /// The UI must show UNAVAILABLE for target pressure.
  double? get optimalTirePressureFront {
    return null;
  }
}
