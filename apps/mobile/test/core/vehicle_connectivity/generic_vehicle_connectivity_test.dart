import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/vehicle_capabilities.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/vehicle_variant_taxonomy.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/vehicle_adapter_registry.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/generic_vehicle_connectivity_engine.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/connection_diagnostics_service.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/universal_vehicle_database.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/adapters/vehicle_connectivity_adapter.dart';

void main() {
  group('Universal Bike & Scooter Smart-Display Connectivity Platform Tests', () {
    late VehicleAdapterRegistry registry;
    late GenericVehicleConnectivityEngine engine;
    late ConnectionDiagnosticsService diagnosticsService;
    late UniversalVehicleDatabase universalDb;

    setUp(() {
      registry = VehicleAdapterRegistry();
      engine = GenericVehicleConnectivityEngine();
      diagnosticsService = ConnectionDiagnosticsService();
      universalDb = UniversalVehicleDatabase();
    });

    test('VehicleCapabilities models full connected two-wheelers without fabricating missing values', () {
      final full = VehicleCapabilities.fullConnectedTwoWheeler();
      expect(full.speed, equals(CapabilitySupportLevel.readOnly));
      expect(full.rpm, equals(CapabilitySupportLevel.readOnly));
      expect(full.batteryVoltage, equals(CapabilitySupportLevel.readOnly));
      expect(full.navigationData, equals(CapabilitySupportLevel.readWrite));
      expect(full.smartDisplayData, equals(CapabilitySupportLevel.readWrite));

      final obd = VehicleCapabilities.standardObdGateway();
      expect(obd.speed, equals(CapabilitySupportLevel.readOnly));
      expect(obd.navigationData, equals(CapabilitySupportLevel.notSupported));

      final unsupported = VehicleCapabilities.unsupportedVehicle();
      expect(unsupported.connectionType, equals(CapabilitySupportLevel.notSupported));
    });

    test('VehicleAdapterRegistry initializes multi-brand 2015+ adapters including BT Classic, Wi-Fi and USB', () {
      expect(registry.isAdapterRegistered('generic_ble'), isTrue);
      expect(registry.isAdapterRegistered('yamaha_y_connect'), isTrue);
      expect(registry.isAdapterRegistered('suzuki_ride_connect'), isTrue);
      expect(registry.isAdapterRegistered('ducati_dms'), isTrue);
      expect(registry.isAdapterRegistered('bmw_motorrad_connect'), isTrue);
      expect(registry.isAdapterRegistered('ktm_my_ride'), isTrue);
      expect(registry.isAdapterRegistered('honda_roadsync'), isTrue);
      expect(registry.isAdapterRegistered('royal_enfield_tripper'), isTrue);
      expect(registry.isAdapterRegistered('tvs_smartxonnect'), isTrue);
      expect(registry.isAdapterRegistered('ather_cloud_telematics'), isTrue);
      expect(registry.isAdapterRegistered('ola_moveos_telematics'), isTrue);
      expect(registry.isAdapterRegistered('bt_classic_spp_gateway'), isTrue);
      expect(registry.isAdapterRegistered('wifi_direct_telematics_gateway'), isTrue);
      expect(registry.isAdapterRegistered('usb_serial_diagnostic_adapter'), isTrue);
      expect(registry.isAdapterRegistered('obd2_gateway_standard'), isTrue);
      expect(registry.isAdapterRegistered('can_bus_gateway_listener'), isTrue);
    });

    test('UniversalVehicleDatabase maintains multi-brand 2015+ open taxonomy and search', () {
      expect(universalDb.availableBrands, contains('Yamaha'));
      expect(universalDb.availableBrands, contains('Suzuki'));
      expect(universalDb.availableBrands, contains('Ducati'));
      expect(universalDb.availableBrands, contains('BMW Motorrad'));
      expect(universalDb.availableBrands, contains('KTM'));
      expect(universalDb.availableBrands, contains('Royal Enfield'));
      expect(universalDb.availableBrands, contains('Ather Energy'));
      expect(universalDb.availableBrands, contains('Ola Electric'));

      final searchResults = universalDb.search(query: 'Himalayan');
      expect(searchResults, isNotEmpty);
      expect(searchResults.first.brand, equals('Royal Enfield'));
      expect(searchResults.first.displayType, contains('TFT'));

      final scooterResults = universalDb.search(query: 'Aerox');
      expect(scooterResults, isNotEmpty);
      expect(scooterResults.first.vehicleType, equals('Scooter'));

      // Verify dynamic registration of future models (e.g. 2028 Next-Gen)
      universalDb.registerEntry(const UniversalVehicleEntry(
        id: 'future_ev_2028',
        brand: 'NextGen EV',
        family: 'Quantum',
        generation: 'Gen 1',
        model: 'Quantum R',
        variant: 'Ultra Pro',
        modelYear: 2028,
        vehicleType: 'ElectricMotorcycle',
        fuelType: 'Electric',
        displayType: 'AR HUD Helmet / 8-inch OLED',
        connectionMethod: VehicleConnectivityType.ble,
        protocolAdapterId: 'generic_ble',
        capabilities: VehicleCapabilities(
          connectionType: CapabilitySupportLevel.supported,
          vehicleIdentification: CapabilitySupportLevel.readOnly,
          speed: CapabilitySupportLevel.readOnly,
          batteryLevel: CapabilitySupportLevel.readOnly,
        ),
        compatibilityLevel: VehicleCompatibilityLevel.full,
      ));

      final futureSearch = universalDb.search(query: 'Quantum R');
      expect(futureSearch, isNotEmpty);
      expect(futureSearch.first.modelYear, equals(2028));
    });

    test('GenericVehicleConnectivityEngine connects, streams telemetry, pushes navigation turns, and sends safe commands', () async {
      final connected = await engine.connectVehicle(
        targetIdentifier: 'DC:A6:32:01:23:45',
        protocolAdapterId: 'yamaha_y_connect',
      );

      expect(connected, isTrue);
      expect(engine.currentState, equals(AdapterConnectionState.connected));
      expect(engine.activeAdapter?.adapterId, equals('yamaha_y_connect'));

      final maneuverSent = await engine.pushNavigationTurn(
        turnInstruction: 'In 200m turn right onto Highway 101',
        distanceMeters: 200.0,
        maneuverCode: 2,
      );
      expect(maneuverSent, isTrue);

      final notifSent = await engine.pushClusterNotification(
        title: 'Incoming Call',
        body: 'Rider Support',
        category: 'telephony',
      );
      expect(notifSent, isTrue);

      final safeCmdSent = await engine.sendCommand(commandName: 'sync_clock');
      expect(safeCmdSent, isTrue);

      final unsafeCmdBlocked = await engine.sendCommand(commandName: 'unauthorized_ecu_remap');
      expect(unsafeCmdBlocked, isFalse);

      await engine.disconnectVehicle();
      expect(engine.currentState, equals(AdapterConnectionState.disconnected));
    });

    test('ConnectionDiagnosticsService evaluates real-time connection link metrics', () async {
      final metrics = await diagnosticsService.getLiveDiagnostics();
      expect(metrics.isBluetoothPermissionGranted, isTrue);
      expect(metrics.discoveredCharacteristicsCount, isNotNull);
      expect(metrics.protocolName, isNotEmpty);
    });
  });
}
