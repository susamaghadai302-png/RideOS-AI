import '../adapters/vehicle_connectivity_adapter.dart';
import '../adapters/ble_adapter.dart';
import '../adapters/obd_gateway_adapter.dart';
import '../adapters/can_gateway_adapter.dart';
import '../adapters/smart_display_adapter.dart';
import '../adapters/manufacturer_api_adapter.dart';
import '../adapters/bluetooth_classic_adapter.dart';
import '../adapters/wifi_gateway_adapter.dart';
import '../adapters/usb_serial_adapter.dart';
import '../models/vehicle_capabilities.dart';

class VehicleAdapterRegistry {
  static final VehicleAdapterRegistry _instance = VehicleAdapterRegistry._internal();
  factory VehicleAdapterRegistry() => _instance;

  final Map<String, VehicleConnectivityAdapter> _registeredAdapters = {};

  VehicleAdapterRegistry._internal() {
    _registerDefaultAdapters();
  }

  void _registerDefaultAdapters() {
    // 1. Generic Standard BLE Adapter
    registerAdapter(GenericBleVehicleAdapter(
      adapterId: 'generic_ble',
      adapterName: 'Generic Two-Wheeler BLE Telematics Adapter',
      capabilities: const VehicleCapabilities(
        connectionType: CapabilitySupportLevel.supported,
        vehicleIdentification: CapabilitySupportLevel.readOnly,
        speed: CapabilitySupportLevel.readOnly,
        rpm: CapabilitySupportLevel.readOnly,
        batteryVoltage: CapabilitySupportLevel.readOnly,
        telemetry: CapabilitySupportLevel.readOnly,
      ),
    ));

    // 2. Yamaha Y-Connect CCU Adapter (2019+ YZF-R15, R3, MT-03, Aerox 155, FZ-X, MT-07, R7, R1M)
    registerAdapter(GenericBleVehicleAdapter(
      adapterId: 'yamaha_y_connect',
      adapterName: 'Yamaha Y-Connect CCU BLE Adapter',
      targetServiceUuids: ['0000fee0-0000-1000-8000-00805f9b34fb'],
      capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
    ));

    // 3. Suzuki Ride Connect / S-NET (2020+ Burgman Street EX, Access 125, Avenis, V-Strom SX, GSX-8S)
    registerAdapter(GenericBleVehicleAdapter(
      adapterId: 'suzuki_ride_connect',
      adapterName: 'Suzuki Ride Connect / S-NET BLE Adapter',
      capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
    ));

    // 4. Ducati Multimedia System (DMS) (2018+ Panigale, Multistrada, Monster, Streetfighter, DesertX)
    registerAdapter(GenericBleVehicleAdapter(
      adapterId: 'ducati_dms',
      adapterName: 'Ducati Multimedia System (DMS) Bluetooth Adapter',
      targetServiceUuids: ['000018f0-0000-1000-8000-00805f9b34fb'],
      capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
    ));

    // 5. BMW Motorrad Connected (2017+ S1000RR, R1250GS, R1300GS, F900R, CE 04 EV, M1000R)
    registerAdapter(GenericBleVehicleAdapter(
      adapterId: 'bmw_motorrad_connect',
      adapterName: 'BMW Motorrad Connected TFT Hub Adapter',
      capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
    ));

    // 6. KTM MY RIDE / Husqvarna Connectivity (2018+ Duke 390/790/890/990/1390, Super Adventure, Svartpilen)
    registerAdapter(GenericBleVehicleAdapter(
      adapterId: 'ktm_my_ride',
      adapterName: 'KTM MY RIDE Bluetooth Connectivity Adapter',
      capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
    ));

    // 7. Honda RoadSync / Smartphone Voice Control (2020+ CB350, H'ness, Transalp, Africa Twin, X-ADV, Forza)
    registerAdapter(GenericBleVehicleAdapter(
      adapterId: 'honda_roadsync',
      adapterName: 'Honda RoadSync & Smartphone Voice Control Adapter',
      capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
    ));

    // 8. Royal Enfield Tripper / Wingman (2020+ Meteor 350, Super Meteor 650, Himalayan 450, Guerrilla 450, Interceptor Bear 650)
    registerAdapter(SmartDisplayAdapter(
      adapterId: 'royal_enfield_tripper',
      adapterName: 'Royal Enfield Tripper & Wingman TBT Cluster Adapter',
    ));

    // 9. TVS SmartXonnect (2019+ Apache RTR 160/200/310, RR 310, NTORQ 125, Jupiter, Ronin, iQube EV)
    registerAdapter(GenericBleVehicleAdapter(
      adapterId: 'tvs_smartxonnect',
      adapterName: 'TVS SmartXonnect Bluetooth Telematics Adapter',
      capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
    ));

    // 10. Ather Energy Smart Grid / AtherStack (2018+ Ather 450X, 450S, 450 Apex, Rizta EV)
    registerAdapter(ManufacturerApiAdapter(
      adapterId: 'ather_cloud_telematics',
      adapterName: 'AtherStack Connected Telematics API Adapter',
      manufacturerName: 'Ather Energy',
      apiEndpoint: 'https://api.atherenergy.com/v1/vehicles',
      capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
    ));

    // 11. Ola Electric MoveOS (2021+ Ola S1 Pro, S1 Air, S1 X+, Roadster EV)
    registerAdapter(ManufacturerApiAdapter(
      adapterId: 'ola_moveos_telematics',
      adapterName: 'Ola MoveOS Telematics & Cloud Adapter',
      manufacturerName: 'Ola Electric',
      apiEndpoint: 'https://api.olaelectric.com/v1/telematics',
      capabilities: VehicleCapabilities.fullConnectedTwoWheeler(),
    ));

    // 12. Bluetooth Classic SPP Telematics Adapter
    registerAdapter(BluetoothClassicAdapter());

    // 13. Wi-Fi / Hotspot Telematics Gateway Adapter
    registerAdapter(WifiGatewayAdapter());

    // 14. USB Serial Diagnostic Adapter
    registerAdapter(UsbSerialAdapter());

    // 15. Standard OBD-II Diagnostic Gateway (All 2015+ Euro 4/5/6 & BS-IV/BS-VI Two-Wheelers)
    registerAdapter(ObdGatewayAdapter());

    // 16. Passive CAN-Bus Gateway Listener
    registerAdapter(CanGatewayAdapter());

    // 17. Generic Smart Display Mirror Adapter
    registerAdapter(SmartDisplayAdapter());
  }

  void registerAdapter(VehicleConnectivityAdapter adapter) {
    _registeredAdapters[adapter.adapterId] = adapter;
  }

  VehicleConnectivityAdapter? getAdapter(String adapterId) {
    return _registeredAdapters[adapterId];
  }

  List<VehicleConnectivityAdapter> getAllAdapters() {
    return _registeredAdapters.values.toList();
  }

  bool isAdapterRegistered(String adapterId) {
    return _registeredAdapters.containsKey(adapterId);
  }
}
