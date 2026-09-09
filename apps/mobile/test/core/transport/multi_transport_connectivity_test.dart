import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/transport/models/transport_types.dart';
import 'package:rideos_mobile/core/transport/models/transport_device.dart';
import 'package:rideos_mobile/core/transport/adapters/transport_adapter.dart';
import 'package:rideos_mobile/core/transport/adapters/ble_gatt_adapter.dart';
import 'package:rideos_mobile/core/transport/adapters/bluetooth_spp_adapter.dart';
import 'package:rideos_mobile/core/transport/adapters/usb_serial_adapter.dart';
import 'package:rideos_mobile/core/transport/adapters/wifi_tcp_adapter.dart';
import 'package:rideos_mobile/core/transport/adapters/simulator_transport_adapter.dart';
import 'package:rideos_mobile/core/transport/services/transport_manager.dart';
import 'package:rideos_mobile/core/transport/presentation/screens/multi_transport_connectivity_screen.dart';
import 'package:rideos_mobile/core/vehicle_identification/services/smart_scan_orchestrator.dart';

void main() {
  group('Phase 17: Multi-Transport Connectivity Manager Tests', () {
    // ======================================================================
    // 1. Transport State Machine
    // ======================================================================
    test('1. Transport state machine enforces valid transitions', () {
      // Valid transitions
      expect(TransportState.disconnected.canTransitionTo(TransportState.initializing), isTrue);
      expect(TransportState.initializing.canTransitionTo(TransportState.scanning), isTrue);
      expect(TransportState.scanning.canTransitionTo(TransportState.deviceFound), isTrue);
      expect(TransportState.deviceFound.canTransitionTo(TransportState.connecting), isTrue);
      expect(TransportState.connecting.canTransitionTo(TransportState.connected), isTrue);
      expect(TransportState.connected.canTransitionTo(TransportState.ready), isTrue);
      expect(TransportState.ready.canTransitionTo(TransportState.transferring), isTrue);
      expect(TransportState.ready.canTransitionTo(TransportState.disconnecting), isTrue);
      expect(TransportState.disconnecting.canTransitionTo(TransportState.disconnected), isTrue);

      // Invalid transitions
      expect(TransportState.disconnected.canTransitionTo(TransportState.ready), isFalse);
      expect(TransportState.scanning.canTransitionTo(TransportState.ready), isFalse);
      expect(TransportState.disconnecting.canTransitionTo(TransportState.connecting), isFalse);
      expect(TransportState.unavailable.canTransitionTo(TransportState.ready), isFalse);

      // Error transitions — all states can transition to error
      expect(TransportState.connecting.canTransitionTo(TransportState.error), isTrue);
      expect(TransportState.connected.canTransitionTo(TransportState.error), isTrue);
      expect(TransportState.transferring.canTransitionTo(TransportState.error), isTrue);

      // Recovery from error
      expect(TransportState.error.canTransitionTo(TransportState.initializing), isTrue);
      expect(TransportState.error.canTransitionTo(TransportState.disconnected), isTrue);
      expect(TransportState.error.canTransitionTo(TransportState.ready), isFalse);
    });

    test('2. TransportState reports terminal and active states correctly', () {
      expect(TransportState.disconnected.isTerminal, isTrue);
      expect(TransportState.error.isTerminal, isTrue);
      expect(TransportState.unavailable.isTerminal, isTrue);
      expect(TransportState.connected.isTerminal, isFalse);
      expect(TransportState.scanning.isTerminal, isFalse);

      expect(TransportState.connected.isActive, isTrue);
      expect(TransportState.ready.isActive, isTrue);
      expect(TransportState.transferring.isActive, isTrue);
      expect(TransportState.scanning.isActive, isFalse);
      expect(TransportState.disconnected.isActive, isFalse);
    });

    // ======================================================================
    // 3. Transport Device Model
    // ======================================================================
    test('3. TransportDevice normalizes device identity and signal quality', () {
      final device = TransportDevice(
        deviceId: 'test_ble_001',
        displayName: 'OBD-II BLE Adapter',
        address: 'AA:BB:CC:DD:EE:FF',
        transportType: TransportType.bluetoothLowEnergy,
        manufacturer: 'Vgate',
        model: 'iCar Pro',
        signalStrengthDbm: -45,
        lastSeen: DateTime.now(),
        supportedProtocols: const ['ISO 15765-4'],
      );

      expect(device.deviceId, equals('test_ble_001'));
      expect(device.transportType, equals(TransportType.bluetoothLowEnergy));
      expect(device.signalQuality, equals('Excellent'));

      // Weak signal
      final weak = device.copyWith(signalStrengthDbm: -75);
      expect(weak.signalQuality, equals('Weak'));

      // Very weak
      final veryWeak = device.copyWith(signalStrengthDbm: -90);
      expect(veryWeak.signalQuality, equals('Very Weak'));

      // No signal data (USB/Wi-Fi)
      final usbDevice = TransportDevice(
        deviceId: 'usb_001',
        displayName: 'USB OBD-II',
        address: '/dev/ttyUSB0',
        transportType: TransportType.usbOtgSerial,
        lastSeen: DateTime.now(),
      );
      expect(usbDevice.signalQuality, equals('N/A'));

      // Equality based on deviceId + transportType
      final same = device.copyWith(displayName: 'Different Name');
      expect(device, equals(same));
    });

    test('4. TransportPacket holds payload with metadata', () {
      final packet = TransportPacket(
        payload: const [0x49, 0x02, 0x01],
        sourceTransport: TransportType.bluetoothLowEnergy,
        isResponse: true,
        commandTag: 'MODE_09',
      );

      expect(packet.length, equals(3));
      expect(packet.isNotEmpty, isTrue);
      expect(packet.sourceTransport, equals(TransportType.bluetoothLowEnergy));
      expect(packet.commandTag, equals('MODE_09'));
    });

    // ======================================================================
    // 5. Transport Error Model
    // ======================================================================
    test('5. TransportError codes and formatting', () {
      final error = TransportError(
        code: TransportErrorCode.connectionTimeout,
        transportType: TransportType.bluetoothClassicSpp,
        details: 'Timed out after 15s',
      );

      expect(error.code, equals(TransportErrorCode.connectionTimeout));
      expect(error.transportType, equals(TransportType.bluetoothClassicSpp));
      expect(error.toString(), contains('CONNECTION_TIMEOUT'));
      expect(error.toString(), contains('Timed out after 15s'));
    });

    // ======================================================================
    // 6. Retry Policy
    // ======================================================================
    test('6. TransportRetryPolicy computes exponential backoff correctly', () {
      const policy = TransportRetryPolicy(
        maxRetries: 4,
        initialDelay: Duration(seconds: 1),
        backoffMultiplier: 2.0,
        maxDelay: Duration(seconds: 16),
      );

      expect(policy.delayForAttempt(0), equals(Duration.zero));
      expect(policy.delayForAttempt(1), equals(const Duration(seconds: 1)));
      expect(policy.delayForAttempt(2), equals(const Duration(seconds: 2)));
      expect(policy.delayForAttempt(3), equals(const Duration(seconds: 4)));
      expect(policy.delayForAttempt(4), equals(const Duration(seconds: 8)));

      // Max delay clamping
      expect(policy.delayForAttempt(10).inSeconds, lessThanOrEqualTo(16));

      // No retry policy
      expect(TransportRetryPolicy.noRetry.maxRetries, equals(0));
    });

    // ======================================================================
    // 7-8. BLE GATT Adapter
    // ======================================================================
    test('7. BleGattTransportAdapter reports capabilities and handles disconnect', () async {
      final adapter = BleGattTransportAdapter(
        configuration: BleGattConfiguration.obdStandard,
      );

      expect(adapter.transportType, equals(TransportType.bluetoothLowEnergy));
      expect(adapter.currentState, equals(TransportState.disconnected));
      expect(adapter.activeConnection, isNull);

      final caps = await adapter.getCapabilities();
      expect(caps.transportType, equals(TransportType.bluetoothLowEnergy));
      expect(caps.supportsSubscription, isTrue);
      expect(caps.supportsBidirectional, isTrue);

      // Disconnect while already disconnected — no crash
      await adapter.disconnect();
      expect(adapter.currentState, equals(TransportState.disconnected));

      await adapter.dispose();
    });

    test('8. BleGattTransportAdapter connect throws TransportError without hardware', () async {
      final adapter = BleGattTransportAdapter();
      final device = TransportDevice(
        deviceId: 'ble_test',
        displayName: 'Test BLE',
        address: '00:11:22:33:44:55',
        transportType: TransportType.bluetoothLowEnergy,
        lastSeen: DateTime.now(),
      );

      expect(
        () => adapter.connect(device),
        throwsA(isA<TransportError>().having(
          (e) => e.code,
          'code',
          TransportErrorCode.platformUnavailable,
        )),
      );
      await adapter.dispose();
    });

    // ======================================================================
    // 9. Bluetooth SPP Adapter
    // ======================================================================
    test('9. BluetoothSppTransportAdapter reports capabilities and handles lifecycle', () async {
      final adapter = BluetoothSppTransportAdapter();

      expect(adapter.transportType, equals(TransportType.bluetoothClassicSpp));
      expect(adapter.currentState, equals(TransportState.disconnected));

      final caps = await adapter.getCapabilities();
      expect(caps.transportType, equals(TransportType.bluetoothClassicSpp));
      expect(caps.maxPayloadBytes, equals(1024));

      await adapter.dispose();
    });

    // ======================================================================
    // 10. USB Serial Adapter
    // ======================================================================
    test('10. UsbSerialTransportAdapter reports platform availability', () async {
      final adapter = UsbSerialTransportAdapter(
        configuration: UsbSerialConfiguration.elm327Default,
      );

      expect(adapter.transportType, equals(TransportType.usbOtgSerial));
      expect(adapter.configuration.baudRate, equals(38400));

      final caps = await adapter.getCapabilities();
      expect(caps.transportType, equals(TransportType.usbOtgSerial));
      expect(caps.maxPayloadBytes, equals(4096));

      await adapter.dispose();
    });

    // ======================================================================
    // 11. Wi-Fi TCP Adapter
    // ======================================================================
    test('11. WifiTcpTransportAdapter provides configured device via discovery', () async {
      final adapter = WifiTcpTransportAdapter(
        configuration: const WifiTcpConfiguration(host: '10.0.0.1', port: 8080),
      );

      expect(adapter.transportType, equals(TransportType.wifiTcp));

      final devices = <TransportDevice>[];
      final sub = adapter.discoveryStream.listen(devices.add);
      await adapter.startDiscovery();
      await sub.cancel();

      expect(devices.length, equals(1));
      expect(devices.first.address, equals('10.0.0.1:8080'));
      expect(devices.first.transportType, equals(TransportType.wifiTcp));

      await adapter.dispose();
    });

    // ======================================================================
    // 12-13. Simulator Transport Adapter
    // ======================================================================
    test('12. SimulatorTransportAdapter discovers, connects, and provides deterministic data', () async {
      final adapter = SimulatorTransportAdapter(
        simulatedLatencyMs: 10,
      );

      expect(adapter.transportType, equals(TransportType.bluetoothLowEnergy));

      // Permission check
      final perm = await adapter.checkPermission();
      expect(perm, equals(TransportPermissionState.granted));

      // Discovery — collect devices before starting scan
      final devices = <TransportDevice>[];
      final sub = adapter.discoveryStream.listen(devices.add);
      // Start discovery but don't await (it delays internally)
      final discoveryFuture = adapter.startDiscovery(timeout: const Duration(milliseconds: 100));
      await discoveryFuture;
      await sub.cancel();

      expect(devices, isNotEmpty);
      expect(devices.first.manufacturer, equals('RideOS Simulator'));
      expect(devices.first.metadata['mode'], equals('SIMULATOR'));

      // Connect
      final conn = await adapter.connect(devices.first);
      expect(conn.state, equals(TransportState.ready));
      expect(adapter.activeConnection, isNotNull);

      // Write deterministic command
      await adapter.write([0x41, 0x54, 0x5A], commandTag: 'ATZ'); // 'ATZ'

      // Disconnect
      await adapter.disconnect();
      expect(adapter.currentState, equals(TransportState.disconnected));
      expect(adapter.activeConnection, isNull);

      await adapter.dispose();
    });

    test('13. SimulatorTransportAdapter connection failure injection', () async {
      final adapter = SimulatorTransportAdapter(
        simulatedLatencyMs: 10,
        shouldFailConnect: true,
      );

      final devices = <TransportDevice>[];
      final sub = adapter.discoveryStream.listen(devices.add);
      await adapter.startDiscovery(timeout: const Duration(milliseconds: 100));
      await sub.cancel();

      expect(devices, isNotEmpty);

      // Connecting should throw a controlled TransportError
      try {
        await adapter.connect(devices.first);
        fail('Expected TransportError to be thrown');
      } on TransportError catch (e) {
        expect(e.code, equals(TransportErrorCode.connectionRefused));
      }

      await adapter.dispose();
    });

    // ======================================================================
    // 14-16. Transport Manager
    // ======================================================================
    test('14. TransportManager manages adapters and execution modes', () {
      final manager = TransportManager.instance;

      // Set execution mode
      manager.setExecutionMode(SmartScanExecutionMode.simulator);
      expect(manager.executionMode, equals(SmartScanExecutionMode.simulator));

      // Transport selection priority
      expect(manager.selectionPriority.first, equals(TransportType.bluetoothLowEnergy));
    });

    test('15. TransportManager discovers devices through simulator adapter', () async {
      final manager = TransportManager.instance;
      manager.setExecutionMode(SmartScanExecutionMode.simulator);

      final devices = await manager.discoverDevices(
        timeout: const Duration(milliseconds: 100),
      );

      // Simulator adapters emit devices
      expect(devices, isNotEmpty);
      expect(manager.discoveredDevices, isNotEmpty);
    });

    test('16. TransportManager handles auto-connect through simulator', () async {
      final manager = TransportManager.instance;
      manager.setExecutionMode(SmartScanExecutionMode.simulator);

      final conn = await manager.autoConnect(
        discoveryTimeout: const Duration(milliseconds: 100),
        connectionTimeout: const Duration(milliseconds: 500),
      );

      expect(conn, isNotNull);
      expect(conn!.isActive, isTrue);
      expect(manager.activeConnection, isNotNull);

      // Disconnect
      await manager.disconnect();
      expect(manager.activeConnection, isNull);
      expect(manager.managerState, equals(TransportState.disconnected));
    });

    // ======================================================================
    // 17. Transport Capabilities
    // ======================================================================
    test('17. TransportCapabilities reports readiness correctly', () {
      const ready = TransportCapabilities(
        transportType: TransportType.bluetoothLowEnergy,
        isAvailableOnPlatform: true,
        isAdapterEnabled: true,
        hasPermission: true,
      );
      expect(ready.isFullyReady, isTrue);

      const notReady = TransportCapabilities(
        transportType: TransportType.usbOtgSerial,
        isAvailableOnPlatform: true,
        isAdapterEnabled: false,
        hasPermission: false,
      );
      expect(notReady.isFullyReady, isFalse);
    });

    // ======================================================================
    // 18. UI Widget Test
    // ======================================================================
    testWidgets('18. MultiTransportConnectivityScreen renders tabs and controls', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MultiTransportConnectivityScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify tabs exist
      expect(find.text('BLE'), findsOneWidget);
      expect(find.text('SPP'), findsOneWidget);
      expect(find.text('USB'), findsOneWidget);
      expect(find.text('WI-FI'), findsOneWidget);

      // Verify header
      expect(find.text('MULTI-TRANSPORT CONNECTIVITY'), findsOneWidget);

      // Verify scan button exists
      expect(find.text('SCAN FOR DEVICES'), findsOneWidget);

      // Verify execution mode badge
      expect(find.text('SIMULATOR'), findsOneWidget);

      // Tap SPP tab
      await tester.tap(find.text('SPP'));
      await tester.pumpAndSettle();

      // Tap USB tab
      await tester.tap(find.text('USB'));
      await tester.pumpAndSettle();

      // Tap Wi-Fi tab
      await tester.tap(find.text('WI-FI'));
      await tester.pumpAndSettle();
    });
  });
}
