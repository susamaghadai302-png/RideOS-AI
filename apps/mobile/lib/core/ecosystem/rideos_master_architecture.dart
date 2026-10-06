// ignore_for_file: constant_identifier_names

import 'dart:async';
import 'package:flutter/foundation.dart';

// ============================================================================
// 1. VEHICLE DOMAIN & PROPULSION TAXONOMY (Car / Motorcycle / Scooter / EV)
// ============================================================================

enum VehicleDomainType {
  motorcycle,
  car,
  scooter,
  electricVehicle,
  commercialFleet,
  atvUtv,
  unknown;

  String get label {
    switch (this) {
      case VehicleDomainType.motorcycle:
        return 'MOTORCYCLE';
      case VehicleDomainType.car:
        return 'PASSENGER CAR';
      case VehicleDomainType.scooter:
        return 'MAXI / URBAN SCOOTER';
      case VehicleDomainType.electricVehicle:
        return 'ELECTRIC VEHICLE (EV)';
      case VehicleDomainType.commercialFleet:
        return 'COMMERCIAL FLEET';
      case VehicleDomainType.atvUtv:
        return 'ALL-TERRAIN VEHICLE (ATV/UTV)';
      case VehicleDomainType.unknown:
        return 'GENERIC VEHICLE';
    }
  }
}

enum PropulsionType {
  internalCombustion,
  batteryElectric,
  plugInHybrid,
  hybridElectric,
  hydrogenFuelCell,
  unknown;

  String get label {
    switch (this) {
      case PropulsionType.internalCombustion:
        return 'INTERNAL COMBUSTION ENGINE (ICE)';
      case PropulsionType.batteryElectric:
        return 'BATTERY ELECTRIC (BEV)';
      case PropulsionType.plugInHybrid:
        return 'PLUG-IN HYBRID (PHEV)';
      case PropulsionType.hybridElectric:
        return 'HYBRID ELECTRIC (HEV)';
      case PropulsionType.hydrogenFuelCell:
        return 'HYDROGEN FUEL CELL (FCEV)';
      case PropulsionType.unknown:
        return 'STANDARD PROPULSION';
    }
  }
}

enum FuelType {
  petrol95,
  petrol98,
  petrol100,
  diesel,
  electric,
  e85,
  cng,
  lpg,
  hydrogen,
  unknown;
}

enum TransmissionType {
  manual,
  automatic,
  dualClutch,
  cvt,
  directDriveEv,
  sequentialQuickshifter,
  automatedManual,
  unknown;
}

// ============================================================================
// 2. VEHICLE PROFILE IDENTITY & SPECIFICATION CONTRACT
// ============================================================================

@immutable
class MasterVehicleIdentity {
  final String vehicleId;
  final String vin; // Vehicle Identification Number (ISO 3779)
  final String make; // e.g. Yamaha, Ducati, Porsche, Tesla, BMW
  final String model; // e.g. YZF-R1M, Panigale V4 S, 911 GT3, Model S Plaid
  final String generation; // e.g. Gen 5, 992, Facelift
  final int year;
  final String variant; // e.g. Performance Pro, Track Edition
  final VehicleDomainType domainType;
  final PropulsionType propulsionType;
  final FuelType fuelType;
  final TransmissionType transmissionType;
  final String engineCode; // e.g. CP4 998cc, Desmosedici Stradale 1103cc
  final int displacementCc;
  final double maxPowerHp;
  final double maxTorqueNm;
  final double redlineRpm;
  final double tankOrBatteryCapacity; // Litres or kWh
  final String ecuProfileId; // Unique ECU identifier
  final String model3dAssetPath; // .glb 3D asset reference

  const MasterVehicleIdentity({
    required this.vehicleId,
    required this.vin,
    required this.make,
    required this.model,
    required this.generation,
    required this.year,
    required this.variant,
    required this.domainType,
    required this.propulsionType,
    required this.fuelType,
    required this.transmissionType,
    required this.engineCode,
    required this.displacementCc,
    required this.maxPowerHp,
    required this.maxTorqueNm,
    required this.redlineRpm,
    required this.tankOrBatteryCapacity,
    required this.ecuProfileId,
    required this.model3dAssetPath,
  });

  Map<String, dynamic> toJson() => {
        'vehicleId': vehicleId,
        'vin': vin,
        'make': make,
        'model': model,
        'generation': generation,
        'year': year,
        'variant': variant,
        'domainType': domainType.name,
        'propulsionType': propulsionType.name,
        'fuelType': fuelType.name,
        'transmissionType': transmissionType.name,
        'engineCode': engineCode,
        'displacementCc': displacementCc,
        'maxPowerHp': maxPowerHp,
        'maxTorqueNm': maxTorqueNm,
        'redlineRpm': redlineRpm,
        'tankOrBatteryCapacity': tankOrBatteryCapacity,
        'ecuProfileId': ecuProfileId,
        'model3dAssetPath': model3dAssetPath,
      };

  factory MasterVehicleIdentity.fromJson(Map<String, dynamic> json) => MasterVehicleIdentity(
        vehicleId: json['vehicleId'] ?? '',
        vin: json['vin'] ?? 'UNKNOWN_VIN',
        make: json['make'] ?? 'Generic',
        model: json['model'] ?? 'Generic Model',
        generation: json['generation'] ?? 'Gen 1',
        year: json['year'] ?? DateTime.now().year,
        variant: json['variant'] ?? 'Base',
        domainType: VehicleDomainType.values.firstWhere(
          (e) => e.name == json['domainType'],
          orElse: () => VehicleDomainType.motorcycle,
        ),
        propulsionType: PropulsionType.values.firstWhere(
          (e) => e.name == json['propulsionType'],
          orElse: () => PropulsionType.internalCombustion,
        ),
        fuelType: FuelType.values.firstWhere(
          (e) => e.name == json['fuelType'],
          orElse: () => FuelType.petrol95,
        ),
        transmissionType: TransmissionType.values.firstWhere(
          (e) => e.name == json['transmissionType'],
          orElse: () => TransmissionType.manual,
        ),
        engineCode: json['engineCode'] ?? 'STD-ENG',
        displacementCc: json['displacementCc'] ?? 0,
        maxPowerHp: (json['maxPowerHp'] as num?)?.toDouble() ?? 0.0,
        maxTorqueNm: (json['maxTorqueNm'] as num?)?.toDouble() ?? 0.0,
        redlineRpm: (json['redlineRpm'] as num?)?.toDouble() ?? 12000.0,
        tankOrBatteryCapacity: (json['tankOrBatteryCapacity'] as num?)?.toDouble() ?? 15.0,
        ecuProfileId: json['ecuProfileId'] ?? 'GENERIC_OBD2',
        model3dAssetPath: json['model3dAssetPath'] ?? 'assets/3d/generic_motorcycle.glb',
      );
}

// ============================================================================
// 3. UNIFIED PHYSICAL CONNECTIVITY & TRANSPORT ARCHITECTURE
// ============================================================================

enum PhysicalTransportType {
  bluetoothLowEnergy,
  bluetoothClassicSpp,
  usbOtgSerial,
  wifiTcpSocket,
  manufacturerCloudRest,
  simulatedTestBench;

  String get displayName {
    switch (this) {
      case PhysicalTransportType.bluetoothLowEnergy:
        return 'Bluetooth LE (GATT)';
      case PhysicalTransportType.bluetoothClassicSpp:
        return 'Bluetooth Classic (SPP/RFCOMM)';
      case PhysicalTransportType.usbOtgSerial:
        return 'USB OTG (FTDI / CH340 / CP2102)';
      case PhysicalTransportType.wifiTcpSocket:
        return 'Wi-Fi Socket (ELM327 Wi-Fi / IP)';
      case PhysicalTransportType.manufacturerCloudRest:
        return 'OEM Cloud REST / MQTT';
      case PhysicalTransportType.simulatedTestBench:
        return 'Simulated Engine Bench';
    }
  }
}

enum HardwareAdapterType {
  elm327V15,
  stn1110,
  stn2120,
  obdLinkMxPlus,
  vGateiCarPro,
  macchinaM2,
  kvaserLeaf,
  proprietaryOemTBox,
  simulatedHILBench;
}

enum ConnectionLifecycleState {
  disconnected,
  discovering,
  connecting,
  handshakeNegotiating,
  protocolIdentified,
  streamingLiveTelemetry,
  suspended,
  reconnecting,
  error;
}

abstract class IConnectionTransport {
  PhysicalTransportType get transportType;
  ConnectionLifecycleState get connectionState;
  Stream<ConnectionLifecycleState> get stateStream;
  Future<bool> openConnection(String connectionEndpointOrAddress);
  Future<void> closeConnection();
  Future<List<int>> sendRawFrame(List<int> payload, {Duration timeout = const Duration(milliseconds: 500)});
  Stream<List<int>> get rawStream;
}

// ============================================================================
// 4. DIAGNOSTIC PROTOCOL & ECU MULTI-MODULE SYSTEM (OBD / CAN / UDS)
// ============================================================================

enum DiagnosticProtocolType {
  iso15765_4_Can_11bit_500k,
  iso15765_4_Can_29bit_500k,
  iso15765_4_Can_11bit_250k,
  iso14229_1_UdsOverCan,
  iso14230_4_Kwp2000Fast,
  iso9141_2_KLine,
  saeJ1939_HeavyDuty,
  saeJ1850_Pwm,
  saeJ1850_Vpw,
  proprietaryYamahaCcu,
  proprietaryDucatiBbs;
}

enum EcuModuleType {
  engineControlModule_ECM,
  transmissionControlUnit_TCU,
  antiLockBraking_ABS,
  batteryManagementSystem_BMS,
  instrumentCluster_IPC,
  bodyControlModule_BCM,
  electronicSuspension_DES,
  tractionControl_IMU,
  telematicsBox_TCU;

  String get hexAddress {
    switch (this) {
      case EcuModuleType.engineControlModule_ECM:
        return '0x7E0';
      case EcuModuleType.transmissionControlUnit_TCU:
        return '0x7E1';
      case EcuModuleType.antiLockBraking_ABS:
        return '0x7E2';
      case EcuModuleType.batteryManagementSystem_BMS:
        return '0x7E3';
      case EcuModuleType.instrumentCluster_IPC:
        return '0x7E4';
      case EcuModuleType.bodyControlModule_BCM:
        return '0x7E5';
      case EcuModuleType.electronicSuspension_DES:
        return '0x7E6';
      case EcuModuleType.tractionControl_IMU:
        return '0x7E7';
      case EcuModuleType.telematicsBox_TCU:
        return '0x7E8';
    }
  }
}

enum DtcSeverityLevel {
  info,
  pending,
  confirmedActive,
  criticalStopEngine,
  permanentHistory;
}

@immutable
class MasterDtcRecord {
  final String code; // e.g. P0115, P0300, C0035, U0100
  final EcuModuleType module;
  final DtcSeverityLevel severity;
  final String description;
  final String cause;
  final String recommendedAction;
  final Map<String, dynamic> freezeFrame;
  final DateTime timestamp;

  const MasterDtcRecord({
    required this.code,
    required this.module,
    required this.severity,
    required this.description,
    required this.cause,
    required this.recommendedAction,
    this.freezeFrame = const {},
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'module': module.name,
        'severity': severity.name,
        'description': description,
        'cause': cause,
        'recommendedAction': recommendedAction,
        'freezeFrame': freezeFrame,
        'timestamp': timestamp.toIso8601String(),
      };
}

abstract class IDiagnosticEngine {
  DiagnosticProtocolType get activeProtocol;
  Future<List<MasterDtcRecord>> readActiveDtcFaults({EcuModuleType? targetModule});
  Future<bool> clearDtcFaults({EcuModuleType? targetModule});
  Future<Map<String, dynamic>> readFreezeFrame(String dtcCode);
  Future<bool> executeServiceFunction(String functionCode, Map<String, dynamic> parameters);
}

// ============================================================================
// 5. LIVE TELEMETRY & MULTI-METRIC COCKPIT SNAPSHOT
// ============================================================================

@immutable
class MasterTelemetrySnapshot {
  final double speedKmh;
  final double engineRpm;
  final int currentGear;
  final double throttlePercentage;
  final double coolantTempCelsius;
  final double intakeAirTempCelsius;
  final double oilPressureBar;
  final double batteryVoltage;
  final double batterySocPercent; // For EV / Hybrids
  final double fuelLevelPercentage;
  final double leanAngleDegrees;
  final double pitchAngleDegrees;
  final double lateralGForce;
  final double longitudinalGForce;
  final double frontTirePressurePsi;
  final double rearTirePressurePsi;
  final int odometerKm;
  final bool isSimulated;
  final DateTime timestamp;

  const MasterTelemetrySnapshot({
    required this.speedKmh,
    required this.engineRpm,
    required this.currentGear,
    required this.throttlePercentage,
    required this.coolantTempCelsius,
    required this.intakeAirTempCelsius,
    required this.oilPressureBar,
    required this.batteryVoltage,
    required this.batterySocPercent,
    required this.fuelLevelPercentage,
    required this.leanAngleDegrees,
    required this.pitchAngleDegrees,
    required this.lateralGForce,
    required this.longitudinalGForce,
    required this.frontTirePressurePsi,
    required this.rearTirePressurePsi,
    required this.odometerKm,
    required this.isSimulated,
    required this.timestamp,
  });

  static MasterTelemetrySnapshot zero({bool isSimulated = false}) => MasterTelemetrySnapshot(
        speedKmh: 0.0,
        engineRpm: 0.0,
        currentGear: 0,
        throttlePercentage: 0.0,
        coolantTempCelsius: 85.0,
        intakeAirTempCelsius: 25.0,
        oilPressureBar: 2.8,
        batteryVoltage: 12.8,
        batterySocPercent: 100.0,
        fuelLevelPercentage: 100.0,
        leanAngleDegrees: 0.0,
        pitchAngleDegrees: 0.0,
        lateralGForce: 0.0,
        longitudinalGForce: 0.0,
        frontTirePressurePsi: 36.0,
        rearTirePressurePsi: 0.0,
        odometerKm: 0,
        isSimulated: isSimulated,
        timestamp: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'speedKmh': speedKmh,
        'engineRpm': engineRpm,
        'currentGear': currentGear,
        'throttlePercentage': throttlePercentage,
        'coolantTempCelsius': coolantTempCelsius,
        'intakeAirTempCelsius': intakeAirTempCelsius,
        'oilPressureBar': oilPressureBar,
        'batteryVoltage': batteryVoltage,
        'batterySocPercent': batterySocPercent,
        'fuelLevelPercentage': fuelLevelPercentage,
        'leanAngleDegrees': leanAngleDegrees,
        'pitchAngleDegrees': pitchAngleDegrees,
        'lateralGForce': lateralGForce,
        'longitudinalGForce': longitudinalGForce,
        'frontTirePressurePsi': frontTirePressurePsi,
        'rearTirePressurePsi': rearTirePressurePsi,
        'odometerKm': odometerKm,
        'isSimulated': isSimulated,
        'timestamp': timestamp.toIso8601String(),
      };
}

// ============================================================================
// 6. VEHICLE DIGITAL TWIN PLATFORM
// ============================================================================

@immutable
class MasterVehicleDigitalTwin {
  final MasterVehicleIdentity identity;
  final MasterTelemetrySnapshot currentTelemetry;
  final double overallHealthScore; // 0 to 100%
  final List<MasterDtcRecord> activeDtcFaults;
  final Map<String, double> componentWearPercentages; // Brake, Tire, Chain, Oil
  final int nextServiceDueKm;
  final DateTime nextServiceDueDate;
  final int totalRidesRecorded;
  final double lifetimeDistanceKm;
  final DateTime lastCloudSync;

  const MasterVehicleDigitalTwin({
    required this.identity,
    required this.currentTelemetry,
    required this.overallHealthScore,
    required this.activeDtcFaults,
    required this.componentWearPercentages,
    required this.nextServiceDueKm,
    required this.nextServiceDueDate,
    required this.totalRidesRecorded,
    required this.lifetimeDistanceKm,
    required this.lastCloudSync,
  });

  Map<String, dynamic> toJson() => {
        'identity': identity.toJson(),
        'currentTelemetry': currentTelemetry.toJson(),
        'overallHealthScore': overallHealthScore,
        'activeDtcFaults': activeDtcFaults.map((e) => e.toJson()).toList(),
        'componentWearPercentages': componentWearPercentages,
        'nextServiceDueKm': nextServiceDueKm,
        'nextServiceDueDate': nextServiceDueDate.toIso8601String(),
        'totalRidesRecorded': totalRidesRecorded,
        'lifetimeDistanceKm': lifetimeDistanceKm,
        'lastCloudSync': lastCloudSync.toIso8601String(),
      };
}

abstract class IVehicleDigitalTwinManager {
  Stream<MasterVehicleDigitalTwin> get digitalTwinStream;
  MasterVehicleDigitalTwin get currentTwin;
  Future<void> updateTwinState({
    required MasterTelemetrySnapshot telemetry,
    List<MasterDtcRecord>? faults,
  });
  Future<void> persistTwinSnapshot();
}

// ============================================================================
// 7. CUSTOMER, COMMERCE & SERVICE HISTORY DOMAIN
// ============================================================================

// OrderStatus and OrderItemCategory have been migrated to lib/features/orders/domain/entities/order_entity.dart

// CustomerOrderItem and CustomerOrder have been migrated to lib/features/orders/domain/entities/order_entity.dart

@immutable
class ServiceHistoryRecord {
  final String recordId;
  final String vehicleId;
  final String serviceType; // Oil Change, Brake Pad, Chain Adjustment, Major Overhaul
  final int odometerKm;
  final double cost;
  final String workshopName;
  final String technicianNotes;
  final List<String> partsReplaced;
  final DateTime serviceDate;

  const ServiceHistoryRecord({
    required this.recordId,
    required this.vehicleId,
    required this.serviceType,
    required this.odometerKm,
    required this.cost,
    required this.workshopName,
    required this.technicianNotes,
    required this.partsReplaced,
    required this.serviceDate,
  });

  Map<String, dynamic> toJson() => {
        'recordId': recordId,
        'vehicleId': vehicleId,
        'serviceType': serviceType,
        'odometerKm': odometerKm,
        'cost': cost,
        'workshopName': workshopName,
        'technicianNotes': technicianNotes,
        'partsReplaced': partsReplaced,
        'serviceDate': serviceDate.toIso8601String(),
      };
}

// ============================================================================
// 8. VEHICLE SCREEN, ANDROID AUTO & CALLING HEAD-UNIT INTERFACE
// ============================================================================

enum CallRouteState {
  helmetBluetooth,
  vehicleSpeakers,
  phoneEarpiece,
  disabled;
}

enum HeadUnitCallStatus {
  idle,
  incoming,
  active,
  onHold,
  ended;
}

@immutable
class VehicleScreenProjectionState {
  final String turnInstruction;
  final int maneuverTypeIcon; // Arrow icon identifier
  final int distanceToManeuverMeters;
  final String streetName;
  final DateTime estimatedArrival;
  final double currentSpeedKmh;
  final double speedLimitKmh;
  final double remainingFuelOrRangeKm;
  final HeadUnitCallStatus callStatus;
  final String? activeCallerName;
  final CallRouteState callAudioRoute;
  final String? safetyAdvisoryNotice;

  const VehicleScreenProjectionState({
    required this.turnInstruction,
    required this.maneuverTypeIcon,
    required this.distanceToManeuverMeters,
    required this.streetName,
    required this.estimatedArrival,
    required this.currentSpeedKmh,
    required this.speedLimitKmh,
    required this.remainingFuelOrRangeKm,
    this.callStatus = HeadUnitCallStatus.idle,
    this.activeCallerName,
    this.callAudioRoute = CallRouteState.helmetBluetooth,
    this.safetyAdvisoryNotice,
  });

  Map<String, dynamic> toJson() => {
        'turnInstruction': turnInstruction,
        'maneuverTypeIcon': maneuverTypeIcon,
        'distanceToManeuverMeters': distanceToManeuverMeters,
        'streetName': streetName,
        'estimatedArrival': estimatedArrival.toIso8601String(),
        'currentSpeedKmh': currentSpeedKmh,
        'speedLimitKmh': speedLimitKmh,
        'remainingFuelOrRangeKm': remainingFuelOrRangeKm,
        'callStatus': callStatus.name,
        'activeCallerName': activeCallerName,
        'callAudioRoute': callAudioRoute.name,
        'safetyAdvisoryNotice': safetyAdvisoryNotice,
      };
}

abstract class IVehicleScreenProjectionProvider {
  Stream<VehicleScreenProjectionState> get projectionStream;
  Future<bool> sendTurnManeuverToCluster({
    required int maneuverType,
    required String textInstruction,
    required int metersRemaining,
  });
  Future<bool> answerIncomingCall();
  Future<bool> declineIncomingCall();
}

// ============================================================================
// 9. PROVIDER-INDEPENDENT CONTRACT DEFINITIONS (Pluggable Micro-Architectures)
// ============================================================================

abstract class IVehicleCatalogProvider {
  Future<List<MasterVehicleIdentity>> fetchCatalog({VehicleDomainType? domain});
  Future<MasterVehicleIdentity?> resolveByVin(String vin);
  Future<MasterVehicleIdentity?> resolveByBleSignature(String advertisedName, List<String> serviceUuids);
}

abstract class IMapRoutingProvider {
  String get providerName;
  bool get requiresPaidBilling;
  Future<Map<String, dynamic>> calculateRoute({
    required double startLat,
    required double startLng,
    required double destLat,
    required double destLng,
  });
}

abstract class IAIAssistantProvider {
  String get providerIdentifier;
  bool get isOfflineCapable;
  Future<String> queryDiagnosticsAssistant({
    required String userQuery,
    required MasterVehicleDigitalTwin twinContext,
  });
}
