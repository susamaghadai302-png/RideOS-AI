import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/vehicle_capabilities.dart';
import '../models/vehicle_variant_taxonomy.dart';

enum AdapterConnectionState {
  disconnected,
  discovering,
  connecting,
  authenticating,
  connected,
  reconnecting,
  error,
  unsupported,
}

@immutable
class RawVehicleTelemetryPacket {
  final DateTime timestamp;
  final double? speedKmh;
  final double? rpm;
  final double? batteryVoltage;
  final double? stateOfChargePct;
  final double? fuelLevelPct;
  final double? engineTempC;
  final double? motorTempC;
  final double? odometerKm;
  final double? tripDistanceKm;
  final int? currentGear;
  final String? rideMode;
  final bool? isAbsActive;
  final bool? isTractionControlActive;
  final List<String> activeDtcCodes;
  final bool isSimulated;

  const RawVehicleTelemetryPacket({
    required this.timestamp,
    this.speedKmh,
    this.rpm,
    this.batteryVoltage,
    this.stateOfChargePct,
    this.fuelLevelPct,
    this.engineTempC,
    this.motorTempC,
    this.odometerKm,
    this.tripDistanceKm,
    this.currentGear,
    this.rideMode,
    this.isAbsActive,
    this.isTractionControlActive,
    this.activeDtcCodes = const [],
    this.isSimulated = false,
  });
}

abstract class VehicleConnectivityAdapter {
  String get adapterId;
  String get adapterName;
  String get version;
  VehicleConnectivityType get connectivityType;
  VehicleCapabilities get capabilities;

  AdapterConnectionState get connectionState;
  Stream<AdapterConnectionState> get stateStream;
  Stream<RawVehicleTelemetryPacket> get telemetryStream;

  Future<bool> discover({Duration timeout = const Duration(seconds: 10)});
  Future<bool> connect(String targetIdentifier);
  Future<bool> authenticate({String? secretKey, String? pinCode});
  Future<void> disconnect();
  
  VehicleCapabilities getCapabilities();
  Future<RawVehicleTelemetryPacket> readTelemetry();
  Future<List<String>> readDiagnostics();
  
  // Smart Display Mirroring (Non-intrusive navigation & notification delivery)
  Future<bool> sendNavigationManeuver({
    required String turnInstruction,
    required double distanceToTurnMeters,
    required int maneuverIconCode,
  });

  Future<bool> sendRiderNotification({
    required String title,
    required String body,
    required String category,
  });

  /// Safe Command Dispatcher (Guards safety-critical systems; only executes officially exposed protocols)
  Future<bool> sendCommand({
    required String commandName,
    Map<String, dynamic>? parameters,
  });
}
