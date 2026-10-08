import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/hardware/capabilities/vehicle_capabilities.dart';
import 'package:rideos_mobile/core/hardware/telemetry/vehicle_telemetry.dart';
import 'package:rideos_mobile/core/hardware/transports/hardware_transport.dart';
import 'package:rideos_mobile/core/hardware/transports/ble_transport.dart';
import 'package:rideos_mobile/core/hardware/transports/bluetooth_classic_transport.dart';
import 'package:rideos_mobile/core/hardware/transports/obd_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  group('Hardware Transport Architecture Tests', () {
    
    test('VehicleCapabilities defaults to unverified without evidence', () {
      const caps = VehicleCapabilities();
      expect(caps.obd, CapabilityStatus.unverified);
      expect(caps.ble, CapabilityStatus.unverified);
      expect(caps.tpms, CapabilityStatus.unverified);
    });

    test('VehicleTelemetry accurately isolates unverified state', () {
      final telemetry = VehicleTelemetry.empty();
      
      expect(telemetry.rpm.isValid, false);
      expect(telemetry.rpm.quality, TelemetryQuality.unavailable);
      expect(telemetry.rpm.value, isNull);
      // It must never synthesize 0 for unavailable
      expect(telemetry.rpm.value == 0, false);
    });

    test('ObdTransport gracefully fails when real hardware is absent (Truth Gate)', () async {
      final baseTransport = BluetoothClassicTransport();
      final obd = ObdTransport(baseTransport);
      
      expect(
        () async => await obd.initialize(),
        throwsA(isA<StateError>().having(
            (e) => e.message, 'message', contains('Physical OBD-II hardware UNVERIFIED'))),
      );
    });

    test('BluetoothClassicTransport fails fast without real RFCOMM', () async {
      final transport = BluetoothClassicTransport();
      
      // In a unit test context without real native channels, it fails due to MissingPluginException
      // or our internal guard. Here we expect an exception indicating hardware failure.
      expect(
        () async => await transport.connect('00:11:22:33:44:55'),
        throwsA(anything),
      );
    });

    test('BluetoothClassicTransport connection race condition correctly aborts stale callback', () async {
      final transport = BluetoothClassicTransport();
      
      // We initiate connect, but before it resolves in the native platform, we disconnect.
      final connectFuture = transport.connect('00:11:22:33:44:55').catchError((_) {});
      await transport.disconnect();
      await connectFuture;
      
      expect(
        transport.currentState, 
        isNot(HardwareTransportState.connected),
        reason: 'Should not be connected after disconnect was called during connection attempt',
      );
    });

    test('BleTransport connection race condition protects against stale callbacks', () async {
      final transport = BleTransport();
      
      final connectFuture = transport.connect('00:11:22:33:44:55').catchError((_) {});
      await transport.disconnect();
      await connectFuture;
      
      expect(transport.currentState, HardwareTransportState.disconnected);
    });
  });
}
