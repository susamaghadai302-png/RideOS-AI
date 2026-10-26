import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/adapters/ble_adapter.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/adapters/obd_gateway_adapter.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/adapters/smart_display_adapter.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/adapters/usb_serial_adapter.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/adapters/can_gateway_adapter.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/adapters/wifi_gateway_adapter.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/adapters/manufacturer_api_adapter.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/adapters/bluetooth_classic_adapter.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/vehicle_capabilities.dart';
import 'package:rideos_mobile/core/vehicle_protocols/generic_ble_adapter.dart';
import 'package:rideos_mobile/core/vehicle_identification/services/vin_identification_engine.dart';
import 'package:rideos_mobile/core/vehicle_catalog/models/vehicle_catalog_models.dart';

void main() {
  group('Production Truth Gate Tests', () {
    test('Fake TEST/demo_device identifiers cannot bypass BLE failures', () async {
      final adapter = GenericBleVehicleAdapter(
        adapterId: 'test',
        adapterName: 'test',
        capabilities: const VehicleCapabilities(),
      );
      final result = await adapter.connect('demo_device');
      expect(result, isFalse);
    });

    test('OBD gateway cannot become CONNECTED without transport success', () async {
      final adapter = ObdGatewayAdapter();
      final result = await adapter.connect('target');
      expect(result, isFalse);
    });

    test('Smart display cannot become CONNECTED without transport success', () async {
      final adapter = SmartDisplayAdapter();
      final result = await adapter.connect('target');
      expect(result, isFalse);
    });

    test('USB serial cannot become CONNECTED without transport success', () async {
      final adapter = UsbSerialAdapter();
      final result = await adapter.connect('target');
      expect(result, isFalse);
    });

    test('CAN gateway cannot become CONNECTED without transport success', () async {
      final adapter = CanGatewayAdapter();
      final result = await adapter.connect('target');
      expect(result, isFalse);
    });

    test('WiFi gateway cannot become CONNECTED without transport success', () async {
      final adapter = WifiGatewayAdapter();
      final result = await adapter.connect('target');
      expect(result, isFalse);
    });

    test('Manufacturer API adapter cannot become CONNECTED without successful real backend/API communication', () async {
      final adapter = ManufacturerApiAdapter(
        adapterId: 'test_api',
        adapterName: 'Test API',
        apiEndpoint: 'https://test.com',
        manufacturerName: 'Test Moto',
        capabilities: const VehicleCapabilities(),
      );
      final result = await adapter.connect('target');
      expect(result, isFalse);
    });

    test('Bluetooth Classic cannot become CONNECTED without transport success', () async {
      final adapter = BluetoothClassicAdapter();
      final result = await adapter.connect('target');
      expect(result, isFalse);
    });

    test('Hardcoded battery/speed/RPM values are never emitted as real telemetry', () async {
      final obdAdapter = ObdGatewayAdapter();
      final obdTelemetry = await obdAdapter.readTelemetry();
      expect(obdTelemetry.batteryVoltage, isNull);

      final smartDisplayAdapter = SmartDisplayAdapter();
      final sdTelemetry = await smartDisplayAdapter.readTelemetry();
      expect(sdTelemetry.batteryVoltage, isNull);

      final usbAdapter = UsbSerialAdapter();
      final usbTelemetry = await usbAdapter.readTelemetry();
      expect(usbTelemetry.batteryVoltage, isNull);

      final genericBle = GenericBleAdapter();
      final parsedTelemetry = genericBle.parseTelemetry([0x00, 0x50]); // Fake 80kmh
      expect(parsedTelemetry.batteryVoltage.value, isNull);
    });
    test('VIN identification returns null for year instead of 2024 when missing', () {
      final engine = VinIdentificationEngine();
      final result = engine.decodeVin('1FALP62W5UA123456'); // Valid structure, Year 'U' is not in map
      expect(result.isValid, isTrue);
      expect(result.decodedDetails?.modelYear, isNull);
    });

    test('Unknown vehicle metadata is not silently fabricated as 2024/Petrol', () {
      final profile = UniversalVehicleProfile.fromJson({
        'id': 'unknown-metadata-test',
        'brand': 'Test Brand',
        'model': 'Urban',
        'variant': 'Standard',
      });

      expect(profile.modelYear, 0, reason: '0 represents an unknown model year.');
      expect(profile.fuelType, 'Unknown');
      expect(profile.fullName, 'Test Brand Urban (Standard)');
    });
  });
}
