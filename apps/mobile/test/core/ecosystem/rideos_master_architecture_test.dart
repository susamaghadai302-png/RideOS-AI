import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/ecosystem/rideos_master_architecture.dart';

void main() {
  group('Phase 15 Master Architecture Ecosystem Unit Tests', () {
    test('1. Vehicle Domain & Identity Taxonomy serializes and deserializes cleanly', () {
      const identity = MasterVehicleIdentity(
        vehicleId: 'veh_yamaha_r1m_01',
        vin: 'JYARN39E8FA000101',
        make: 'Yamaha',
        model: 'YZF-R1M',
        generation: 'Gen 5',
        year: 2024,
        variant: 'Carbon Performance',
        domainType: VehicleDomainType.motorcycle,
        propulsionType: PropulsionType.internalCombustion,
        fuelType: FuelType.petrol98,
        transmissionType: TransmissionType.sequentialQuickshifter,
        engineCode: 'CP4 Crossplane',
        displacementCc: 998,
        maxPowerHp: 200.0,
        maxTorqueNm: 113.3,
        redlineRpm: 14500.0,
        tankOrBatteryCapacity: 17.0,
        ecuProfileId: 'YAMAHA_CP4_DENSO_OBD2',
        model3dAssetPath: 'assets/3d/yamaha_r1m.glb',
      );

      final json = identity.toJson();
      expect(json['make'], equals('Yamaha'));
      expect(json['model'], equals('YZF-R1M'));
      expect(json['domainType'], equals('motorcycle'));
      expect(json['propulsionType'], equals('internalCombustion'));

      final reconstructed = MasterVehicleIdentity.fromJson(json);
      expect(reconstructed.vehicleId, equals('veh_yamaha_r1m_01'));
      expect(reconstructed.engineCode, equals('CP4 Crossplane'));
      expect(reconstructed.maxPowerHp, equals(200.0));
      expect(reconstructed.domainType, equals(VehicleDomainType.motorcycle));
    });

    test('2. Multi-Domain Support handles Car, Scooter, EV, and ATV taxonomy', () {
      expect(VehicleDomainType.car.label, contains('CAR'));
      expect(VehicleDomainType.motorcycle.label, contains('MOTORCYCLE'));
      expect(VehicleDomainType.scooter.label, contains('SCOOTER'));
      expect(VehicleDomainType.electricVehicle.label, contains('ELECTRIC'));

      expect(PropulsionType.batteryElectric.label, contains('BATTERY ELECTRIC'));
      expect(PhysicalTransportType.bluetoothLowEnergy.displayName, contains('GATT'));
      expect(PhysicalTransportType.usbOtgSerial.displayName, contains('USB OTG'));
    });

    test('3. Diagnostic Protocol & Master DTC Records encode properly', () {
      final dtc = MasterDtcRecord(
        code: 'P0115',
        module: EcuModuleType.engineControlModule_ECM,
        severity: DtcSeverityLevel.confirmedActive,
        description: 'Engine Coolant Temperature Sensor 1 Circuit Malfunction',
        cause: 'Wiring open or sensor thermistor open-circuit',
        recommendedAction: 'Inspect coolant thermistor resistance and harness pin 14',
        freezeFrame: const {'rpm': 4200, 'speed': 64, 'coolantTemp': 118},
        timestamp: DateTime(2026, 8, 31, 12, 0),
      );

      final json = dtc.toJson();
      expect(json['code'], equals('P0115'));
      expect(json['module'], equals('engineControlModule_ECM'));
      expect(json['severity'], equals('confirmedActive'));
      expect(json['freezeFrame']['coolantTemp'], equals(118));
      expect(EcuModuleType.engineControlModule_ECM.hexAddress, equals('0x7E0'));
      expect(EcuModuleType.antiLockBraking_ABS.hexAddress, equals('0x7E2'));
    });

    test('4. Live Telemetry & Digital Twin State Integration', () {
      final telemetry = MasterTelemetrySnapshot(
        speedKmh: 128.5,
        engineRpm: 9200.0,
        currentGear: 4,
        throttlePercentage: 68.0,
        coolantTempCelsius: 88.0,
        intakeAirTempCelsius: 24.0,
        oilPressureBar: 3.4,
        batteryVoltage: 13.9,
        batterySocPercent: 100.0,
        fuelLevelPercentage: 74.0,
        leanAngleDegrees: 38.5,
        pitchAngleDegrees: 1.2,
        lateralGForce: 0.82,
        longitudinalGForce: 0.45,
        frontTirePressurePsi: 34.5,
        rearTirePressurePsi: 40.0,
        odometerKm: 12450,
        isSimulated: false,
        timestamp: DateTime.now(),
      );

      const identity = MasterVehicleIdentity(
        vehicleId: 'veh_ducati_v4s_01',
        vin: 'ZDM12345678901234',
        make: 'Ducati',
        model: 'Panigale V4 S',
        generation: 'Gen 3',
        year: 2024,
        variant: 'Corse S',
        domainType: VehicleDomainType.motorcycle,
        propulsionType: PropulsionType.internalCombustion,
        fuelType: FuelType.petrol98,
        transmissionType: TransmissionType.sequentialQuickshifter,
        engineCode: 'Desmosedici Stradale',
        displacementCc: 1103,
        maxPowerHp: 214.0,
        maxTorqueNm: 124.0,
        redlineRpm: 15000.0,
        tankOrBatteryCapacity: 16.0,
        ecuProfileId: 'DUCATI_BBS_MARELLI_OBD2',
        model3dAssetPath: 'assets/3d/ducati_v4s.glb',
      );

      final digitalTwin = MasterVehicleDigitalTwin(
        identity: identity,
        currentTelemetry: telemetry,
        overallHealthScore: 96.5,
        activeDtcFaults: const [],
        componentWearPercentages: const {
          'engineOil': 22.0,
          'frontBrakePads': 35.0,
          'driveChain': 18.0,
          'frontTire': 40.0,
        },
        nextServiceDueKm: 15000,
        nextServiceDueDate: DateTime(2026, 12, 1),
        totalRidesRecorded: 48,
        lifetimeDistanceKm: 12450.0,
        lastCloudSync: DateTime.now(),
      );

      final json = digitalTwin.toJson();
      expect(json['overallHealthScore'], equals(96.5));
      expect(json['componentWearPercentages']['engineOil'], equals(22.0));
      expect(json['identity']['make'], equals('Ducati'));
      expect(json['currentTelemetry']['speedKmh'], equals(128.5));
    });

    test('5. Customer Commerce & Order Lifecycle model verifies accurately', () {
      const orderItem = CustomerOrderItem(
        itemId: 'prod_obd_dongle_01',
        title: 'RideOS High-Speed CAN OBD-II Bluetooth Dongle',
        category: OrderItemCategory.hardwareAdapter,
        unitPrice: 79.99,
        quantity: 1,
      );

      final order = CustomerOrder(
        orderId: 'ord_2026_9942',
        customerId: 'cust_alex_mercer_77',
        items: const [orderItem],
        totalAmount: 79.99,
        currency: 'USD',
        status: OrderStatus.completed,
        createdAt: DateTime(2026, 8, 31),
      );

      final json = order.toJson();
      expect(json['orderId'], equals('ord_2026_9942'));
      expect(json['status'], equals('completed'));
      expect(json['items'].length, equals(1));
    });

    test('6. Vehicle Screen Projection & Calling State Model', () {
      final screenState = VehicleScreenProjectionState(
        turnInstruction: 'Turn right onto Autobahn A8 in 300 meters',
        maneuverTypeIcon: 4,
        distanceToManeuverMeters: 300,
        streetName: 'Autobahn A8',
        estimatedArrival: DateTime(2026, 8, 31, 14, 30),
        currentSpeedKmh: 110.0,
        speedLimitKmh: 130.0,
        remainingFuelOrRangeKm: 240.0,
        callStatus: HeadUnitCallStatus.incoming,
        activeCallerName: 'Marcus Vance',
        callAudioRoute: CallRouteState.helmetBluetooth,
        safetyAdvisoryNotice: 'Heavy crosswind detected on upcoming viaduct',
      );

      final json = screenState.toJson();
      expect(json['turnInstruction'], contains('Autobahn A8'));
      expect(json['callStatus'], equals('incoming'));
      expect(json['activeCallerName'], equals('Marcus Vance'));
      expect(json['callAudioRoute'], equals('helmetBluetooth'));
    });
  });
}
