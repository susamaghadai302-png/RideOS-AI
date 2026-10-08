enum CapabilityStatus {
  supported,
  unsupported,
  unavailable,
  unverified,
}

class VehicleCapabilities {
  final CapabilityStatus ble;
  final CapabilityStatus bluetoothClassic;
  final CapabilityStatus obd;
  final CapabilityStatus rpm;
  final CapabilityStatus vehicleSpeed;
  final CapabilityStatus coolantTemperature;
  final CapabilityStatus throttlePosition;
  final CapabilityStatus batteryVoltage;
  final CapabilityStatus tpms;

  const VehicleCapabilities({
    this.ble = CapabilityStatus.unverified,
    this.bluetoothClassic = CapabilityStatus.unverified,
    this.obd = CapabilityStatus.unverified,
    this.rpm = CapabilityStatus.unverified,
    this.vehicleSpeed = CapabilityStatus.unverified,
    this.coolantTemperature = CapabilityStatus.unverified,
    this.throttlePosition = CapabilityStatus.unverified,
    this.batteryVoltage = CapabilityStatus.unverified,
    this.tpms = CapabilityStatus.unverified,
  });

  VehicleCapabilities copyWith({
    CapabilityStatus? ble,
    CapabilityStatus? bluetoothClassic,
    CapabilityStatus? obd,
    CapabilityStatus? rpm,
    CapabilityStatus? vehicleSpeed,
    CapabilityStatus? coolantTemperature,
    CapabilityStatus? throttlePosition,
    CapabilityStatus? batteryVoltage,
    CapabilityStatus? tpms,
  }) {
    return VehicleCapabilities(
      ble: ble ?? this.ble,
      bluetoothClassic: bluetoothClassic ?? this.bluetoothClassic,
      obd: obd ?? this.obd,
      rpm: rpm ?? this.rpm,
      vehicleSpeed: vehicleSpeed ?? this.vehicleSpeed,
      coolantTemperature: coolantTemperature ?? this.coolantTemperature,
      throttlePosition: throttlePosition ?? this.throttlePosition,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      tpms: tpms ?? this.tpms,
    );
  }
}
