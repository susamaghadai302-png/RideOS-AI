import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_capabilities/models/universal_vehicle_capability_models.dart';
import 'package:rideos_mobile/core/transport/models/transport_types.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/registry/vehicle_compatibility_registry.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/universal_vehicle_connection_manager.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/transports/vehicle_transport.dart';
import 'mocks/simulator_transport.dart';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Universal Motorcycle & Scooter Connectivity Architecture Tests', () {
    late VehicleCompatibilityRegistry registry;
    late UniversalVehicleConnectionManager manager;

    setUp(() {
      registry = VehicleCompatibilityRegistry();
      manager = UniversalVehicleConnectionManager();
    });

    test('Transport Layer: SimulatorTransport emits and transitions states cleanly', () async {
      final sim = SimulatorTransport();
      await sim.initialize();
      expect(sim.state, equals(TransportConnectionState.disconnected));

      final connected = await sim.connect('SIM_ENDPOINT_01');
      expect(connected, isTrue);
      expect(sim.state, equals(TransportConnectionState.connected));

      await sim.disconnect();
      expect(sim.state, equals(TransportConnectionState.disconnected));
      await sim.dispose();
    });

    test('Registry Signature Matching: Identifies Yamaha R15M CCU and classifies as Smart Display', () async {
      await manager.connectVehicle(
        deviceName: 'Y-Connect_CCU_98A2',
        advertisedServices: ['0000fee0-0000-1000-8000-00805f9b34fb'],
        endpointOrMac: 'AA:BB:CC:DD:EE:FF',
        isSimulated: true,
      );

      final state = manager.currentState;
      expect(state.phase, equals(ConnectionLifecyclePhase.telemetryActive));
      expect(state.category, equals(ConnectionCategory.smartDisplay));
      expect(state.activeProfile?.entryId, equals('yamaha_r15m_ccu'));
      expect(state.signalRssi, equals(-52));
      expect(state.latencyMs, equals(18));
    });

    test('Command Safety: Blocks arbitrary ECU and immobilizer injection', () async {
      final blocked = await manager.sendVehicleCommand(
        commandName: 'CAN_INJECT_RAW_KILL_SWITCH',
        parameters: {},
      );
      expect(blocked, isFalse);

      final blockedBrake = await manager.sendVehicleCommand(
        commandName: 'ACTUATE_ELECTRONIC_BRAKE',
        parameters: {},
      );
      expect(blockedBrake, isFalse);
    });

    test('Command Safety: Blocks commands on Read-Only vehicle profiles (Ather Cloud)', () async {
      await manager.connectVehicle(
        deviceName: 'Ather450X_Cloud',
        advertisedServices: ['000018f0-0000-1000-8000-00805f9b34fb'],
        endpointOrMac: 'CLOUD_TOKEN_ENDPOINT',
        isSimulated: true,
      );

      expect(manager.currentState.activeProfile?.isReadOnly, isTrue);

      final blocked = await manager.sendVehicleCommand(
        commandName: 'WRITE_TBT_NAVIGATION_ARROW',
        parameters: {},
      );
      expect(blocked, isFalse);
    });

    test('Dynamic Registration: Future 2027 vehicle model loaded without core changes', () {
      const futureBmw = CompatibilityRegistryEntry(
        entryId: 'bmw_r1300gs_2027',
        manufacturer: 'BMW Motorrad',
        brand: 'BMW',
        model: 'R 1300 GS Adventure',
        modelYearRange: '2027-Present',
        variantTrim: VariantTrimLevel.topPremium,
        region: 'Global',
        displayGeneration: '6.5-inch TFT Connectivity Plus',
        ecuGatewayGeneration: 'BMW Connectivity Hub Gen 4',
        primaryTransport: TransportType.bluetoothLowEnergy,
        supportedProtocols: ['BMW Motorrad Connected GATT', 'LIN Bus Mirror'],
        supportedTelemetry: ['speed', 'rpm', 'fuelLevel', 'tirePressure', 'absStatus'],
        supportedCommands: ['WRITE_TBT_NAVIGATION_ARROW'],
        pairingRequirements: 'BLE Numeric Comparison 6-digit PIN',
        isReadOnly: false,
        safetyRestrictions: 'HUD navigation mirror only.',
        protocolVersion: 'BMW-GATT-v4.0',
        status: VehicleCompatibilityStatus.supported,
      );

      registry.registerProfile(futureBmw);
      expect(registry.entries.any((e) => e.entryId == 'bmw_r1300gs_2027'), isTrue);
    });
  });
}
