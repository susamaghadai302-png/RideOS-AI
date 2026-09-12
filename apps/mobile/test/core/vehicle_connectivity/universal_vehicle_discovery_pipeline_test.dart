import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/universal_discovery_pipeline_models.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/universal_vehicle_discovery_pipeline.dart';
import 'mocks/mock_vehicle_transport.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Universal Vehicle Discovery Pipeline Tests', () {
    late UniversalVehicleDiscoveryPipeline pipeline;
    late MockVehicleTransport transport;

    setUp(() async {
      pipeline = UniversalVehicleDiscoveryPipeline();
      transport = MockVehicleTransport();
      await transport.initialize();
    });

    tearDown(() async {
      await transport.dispose();
    });

    test('Executes end-to-end 12-step flow to streaming state', () async {
      final success = await pipeline.runPipeline(
        deviceName: 'Yamaha_CCU_YZF_R15M',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        advertisedServices: ['0000fee0-0000-1000-8000-00805f9b34fb'],
        transport: transport,
        hasPermissions: true,
        isBluetoothEnabled: true,
        autoConfirm: true,
      );

      expect(success, isTrue);
      expect(pipeline.currentState, equals(PipelineLifecycleState.streaming));
      expect(pipeline.latestDiscovery, isNotNull);
      expect(pipeline.latestDiscovery?.displayType, equals(DisplayIntegrationType.tftMirror));
      expect(pipeline.latestDiscovery?.compatibility.manufacturer, equals('Yamaha Motor Co.'));
    });

    test('Permission check failure transitions to error and halts', () async {
      final success = await pipeline.runPipeline(
        deviceName: 'Yamaha_CCU_YZF_R15M',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        advertisedServices: ['0000fee0-0000-1000-8000-00805f9b34fb'],
        transport: transport,
        hasPermissions: false,
      );

      expect(success, isFalse);
      expect(pipeline.currentState, equals(PipelineLifecycleState.error));
    });

    test('Bluetooth disabled transitions to error and halts', () async {
      final success = await pipeline.runPipeline(
        deviceName: 'Yamaha_CCU_YZF_R15M',
        macAddress: 'AA:BB:CC:DD:EE:FF',
        advertisedServices: ['0000fee0-0000-1000-8000-00805f9b34fb'],
        transport: transport,
        hasPermissions: true,
        isBluetoothEnabled: false,
      );

      expect(success, isFalse);
      expect(pipeline.currentState, equals(PipelineLifecycleState.error));
    });

    test('Resolves Royal Enfield Tripper Pod as dedicated navigation pod', () async {
      await pipeline.runPipeline(
        deviceName: 'RE_Tripper_Himalayan_450',
        macAddress: '11:22:33:44:55:66',
        advertisedServices: ['0000fe50-0000-1000-8000-00805f9b34fb'],
        transport: transport,
        autoConfirm: false, // Pauses at user confirmation
      );

      expect(pipeline.currentState, equals(PipelineLifecycleState.userConfirmation));
      expect(pipeline.latestDiscovery?.displayType, equals(DisplayIntegrationType.tripperPod));
    });

    test('User cancellation halts pipeline cleanly back to idle', () {
      pipeline.cancel();
      expect(pipeline.currentState, equals(PipelineLifecycleState.idle));
    });
  });
}
