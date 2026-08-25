import 'package:flutter/foundation.dart';

enum CapabilitySupportLevel {
  supported,
  notSupported,
  readOnly,
  readWrite,
  unknown,
}

enum VehicleCompatibilityLevel {
  full,
  partial,
  diagnosticOnly,
  displayOnly,
  telematicsOnly,
  gatewayRequired,
  notSupported,
  unknown,
}

@immutable
class VehicleCapabilities {
  final CapabilitySupportLevel connectionType;
  final CapabilitySupportLevel vehicleIdentification;
  final CapabilitySupportLevel speed;
  final CapabilitySupportLevel rpm;
  final CapabilitySupportLevel batteryVoltage;
  final CapabilitySupportLevel batteryLevel; // EV State of Charge or auxiliary battery
  final CapabilitySupportLevel fuelLevel;
  final CapabilitySupportLevel engineTemperature;
  final CapabilitySupportLevel motorTemperature; // EV powertrain
  final CapabilitySupportLevel odometer;
  final CapabilitySupportLevel tripDistance;
  final CapabilitySupportLevel rideMode;
  final CapabilitySupportLevel ignitionState;
  final CapabilitySupportLevel turnSignals;
  final CapabilitySupportLevel lights;
  final CapabilitySupportLevel absStatus;
  final CapabilitySupportLevel tractionControl;
  final CapabilitySupportLevel diagnosticCodes; // DTC
  final CapabilitySupportLevel maintenanceData;
  final CapabilitySupportLevel navigationData; // Smart Display Turn-by-Turn
  final CapabilitySupportLevel smartDisplayData; // Calls, media, warnings
  final CapabilitySupportLevel telemetry;

  const VehicleCapabilities({
    this.connectionType = CapabilitySupportLevel.supported,
    this.vehicleIdentification = CapabilitySupportLevel.supported,
    this.speed = CapabilitySupportLevel.unknown,
    this.rpm = CapabilitySupportLevel.unknown,
    this.batteryVoltage = CapabilitySupportLevel.unknown,
    this.batteryLevel = CapabilitySupportLevel.unknown,
    this.fuelLevel = CapabilitySupportLevel.unknown,
    this.engineTemperature = CapabilitySupportLevel.unknown,
    this.motorTemperature = CapabilitySupportLevel.unknown,
    this.odometer = CapabilitySupportLevel.unknown,
    this.tripDistance = CapabilitySupportLevel.unknown,
    this.rideMode = CapabilitySupportLevel.unknown,
    this.ignitionState = CapabilitySupportLevel.unknown,
    this.turnSignals = CapabilitySupportLevel.unknown,
    this.lights = CapabilitySupportLevel.unknown,
    this.absStatus = CapabilitySupportLevel.unknown,
    this.tractionControl = CapabilitySupportLevel.unknown,
    this.diagnosticCodes = CapabilitySupportLevel.unknown,
    this.maintenanceData = CapabilitySupportLevel.unknown,
    this.navigationData = CapabilitySupportLevel.unknown,
    this.smartDisplayData = CapabilitySupportLevel.unknown,
    this.telemetry = CapabilitySupportLevel.unknown,
  });

  /// Factory for modern Full BLE Connected Vehicles (e.g. Yamaha Y-Connect, Ducati DMS, KTM MY RIDE, Ather, Ola)
  factory VehicleCapabilities.fullConnectedTwoWheeler() {
    return const VehicleCapabilities(
      connectionType: CapabilitySupportLevel.supported,
      vehicleIdentification: CapabilitySupportLevel.readOnly,
      speed: CapabilitySupportLevel.readOnly,
      rpm: CapabilitySupportLevel.readOnly,
      batteryVoltage: CapabilitySupportLevel.readOnly,
      batteryLevel: CapabilitySupportLevel.readOnly,
      fuelLevel: CapabilitySupportLevel.readOnly,
      engineTemperature: CapabilitySupportLevel.readOnly,
      motorTemperature: CapabilitySupportLevel.readOnly,
      odometer: CapabilitySupportLevel.readOnly,
      tripDistance: CapabilitySupportLevel.readOnly,
      rideMode: CapabilitySupportLevel.readOnly,
      ignitionState: CapabilitySupportLevel.readOnly,
      turnSignals: CapabilitySupportLevel.readOnly,
      lights: CapabilitySupportLevel.readOnly,
      absStatus: CapabilitySupportLevel.readOnly,
      tractionControl: CapabilitySupportLevel.readOnly,
      diagnosticCodes: CapabilitySupportLevel.readOnly,
      maintenanceData: CapabilitySupportLevel.readOnly,
      navigationData: CapabilitySupportLevel.readWrite,
      smartDisplayData: CapabilitySupportLevel.readWrite,
      telemetry: CapabilitySupportLevel.readOnly,
    );
  }

  /// Factory for standard OBD-II / CAN Gateway connected two-wheelers (2015+ Euro 4/5)
  factory VehicleCapabilities.standardObdGateway() {
    return const VehicleCapabilities(
      connectionType: CapabilitySupportLevel.supported,
      vehicleIdentification: CapabilitySupportLevel.readOnly,
      speed: CapabilitySupportLevel.readOnly,
      rpm: CapabilitySupportLevel.readOnly,
      batteryVoltage: CapabilitySupportLevel.readOnly,
      batteryLevel: CapabilitySupportLevel.notSupported,
      fuelLevel: CapabilitySupportLevel.readOnly,
      engineTemperature: CapabilitySupportLevel.readOnly,
      motorTemperature: CapabilitySupportLevel.notSupported,
      odometer: CapabilitySupportLevel.readOnly,
      tripDistance: CapabilitySupportLevel.readOnly,
      rideMode: CapabilitySupportLevel.notSupported,
      ignitionState: CapabilitySupportLevel.readOnly,
      turnSignals: CapabilitySupportLevel.notSupported,
      lights: CapabilitySupportLevel.notSupported,
      absStatus: CapabilitySupportLevel.readOnly,
      tractionControl: CapabilitySupportLevel.notSupported,
      diagnosticCodes: CapabilitySupportLevel.readWrite, // Clear DTC codes
      maintenanceData: CapabilitySupportLevel.readOnly,
      navigationData: CapabilitySupportLevel.notSupported,
      smartDisplayData: CapabilitySupportLevel.notSupported,
      telemetry: CapabilitySupportLevel.readOnly,
    );
  }

  /// Factory for Display-Only / Notification Mirroring smart clusters
  factory VehicleCapabilities.displayOnlyCluster() {
    return const VehicleCapabilities(
      connectionType: CapabilitySupportLevel.supported,
      vehicleIdentification: CapabilitySupportLevel.readOnly,
      speed: CapabilitySupportLevel.notSupported,
      rpm: CapabilitySupportLevel.notSupported,
      batteryVoltage: CapabilitySupportLevel.readOnly,
      batteryLevel: CapabilitySupportLevel.notSupported,
      fuelLevel: CapabilitySupportLevel.notSupported,
      engineTemperature: CapabilitySupportLevel.notSupported,
      motorTemperature: CapabilitySupportLevel.notSupported,
      odometer: CapabilitySupportLevel.notSupported,
      tripDistance: CapabilitySupportLevel.notSupported,
      rideMode: CapabilitySupportLevel.notSupported,
      ignitionState: CapabilitySupportLevel.notSupported,
      turnSignals: CapabilitySupportLevel.notSupported,
      lights: CapabilitySupportLevel.notSupported,
      absStatus: CapabilitySupportLevel.notSupported,
      tractionControl: CapabilitySupportLevel.notSupported,
      diagnosticCodes: CapabilitySupportLevel.notSupported,
      maintenanceData: CapabilitySupportLevel.notSupported,
      navigationData: CapabilitySupportLevel.readWrite,
      smartDisplayData: CapabilitySupportLevel.readWrite,
      telemetry: CapabilitySupportLevel.notSupported,
    );
  }

  /// Factory for Unsupported / Legacy Vehicles (no wireless connectivity or diagnostic gateway)
  factory VehicleCapabilities.unsupportedVehicle() {
    return const VehicleCapabilities(
      connectionType: CapabilitySupportLevel.notSupported,
      vehicleIdentification: CapabilitySupportLevel.notSupported,
      speed: CapabilitySupportLevel.notSupported,
      rpm: CapabilitySupportLevel.notSupported,
      batteryVoltage: CapabilitySupportLevel.notSupported,
      batteryLevel: CapabilitySupportLevel.notSupported,
      fuelLevel: CapabilitySupportLevel.notSupported,
      engineTemperature: CapabilitySupportLevel.notSupported,
      motorTemperature: CapabilitySupportLevel.notSupported,
      odometer: CapabilitySupportLevel.notSupported,
      tripDistance: CapabilitySupportLevel.notSupported,
      rideMode: CapabilitySupportLevel.notSupported,
      ignitionState: CapabilitySupportLevel.notSupported,
      turnSignals: CapabilitySupportLevel.notSupported,
      lights: CapabilitySupportLevel.notSupported,
      absStatus: CapabilitySupportLevel.notSupported,
      tractionControl: CapabilitySupportLevel.notSupported,
      diagnosticCodes: CapabilitySupportLevel.notSupported,
      maintenanceData: CapabilitySupportLevel.notSupported,
      navigationData: CapabilitySupportLevel.notSupported,
      smartDisplayData: CapabilitySupportLevel.notSupported,
      telemetry: CapabilitySupportLevel.notSupported,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'connectionType': connectionType.name,
      'vehicleIdentification': vehicleIdentification.name,
      'speed': speed.name,
      'rpm': rpm.name,
      'batteryVoltage': batteryVoltage.name,
      'batteryLevel': batteryLevel.name,
      'fuelLevel': fuelLevel.name,
      'engineTemperature': engineTemperature.name,
      'motorTemperature': motorTemperature.name,
      'odometer': odometer.name,
      'tripDistance': tripDistance.name,
      'rideMode': rideMode.name,
      'ignitionState': ignitionState.name,
      'turnSignals': turnSignals.name,
      'lights': lights.name,
      'absStatus': absStatus.name,
      'tractionControl': tractionControl.name,
      'diagnosticCodes': diagnosticCodes.name,
      'maintenanceData': maintenanceData.name,
      'navigationData': navigationData.name,
      'smartDisplayData': smartDisplayData.name,
      'telemetry': telemetry.name,
    };
  }

  factory VehicleCapabilities.fromJson(Map<String, dynamic> json) {
    CapabilitySupportLevel parse(String? key) {
      if (key == null) return CapabilitySupportLevel.unknown;
      return CapabilitySupportLevel.values.firstWhere(
        (e) => e.name == key,
        orElse: () => CapabilitySupportLevel.unknown,
      );
    }

    return VehicleCapabilities(
      connectionType: parse(json['connectionType']),
      vehicleIdentification: parse(json['vehicleIdentification']),
      speed: parse(json['speed']),
      rpm: parse(json['rpm']),
      batteryVoltage: parse(json['batteryVoltage']),
      batteryLevel: parse(json['batteryLevel']),
      fuelLevel: parse(json['fuelLevel']),
      engineTemperature: parse(json['engineTemperature']),
      motorTemperature: parse(json['motorTemperature']),
      odometer: parse(json['odometer']),
      tripDistance: parse(json['tripDistance']),
      rideMode: parse(json['rideMode']),
      ignitionState: parse(json['ignitionState']),
      turnSignals: parse(json['turnSignals']),
      lights: parse(json['lights']),
      absStatus: parse(json['absStatus']),
      tractionControl: parse(json['tractionControl']),
      diagnosticCodes: parse(json['diagnosticCodes']),
      maintenanceData: parse(json['maintenanceData']),
      navigationData: parse(json['navigationData']),
      smartDisplayData: parse(json['smartDisplayData']),
      telemetry: parse(json['telemetry']),
    );
  }
}
