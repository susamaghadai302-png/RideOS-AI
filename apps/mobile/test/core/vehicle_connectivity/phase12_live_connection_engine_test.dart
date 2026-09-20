import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/vehicle_capabilities.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/adapters/vehicle_connectivity_adapter.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/automatic_vehicle_identifier.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/vehicle_compatibility_evaluator.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/connection_recovery_engine.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/paired_vehicle_memory_service.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/generic_vehicle_connectivity_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Universal Vehicle Auto-Detection & Live Connection Engine Tests', () {
    late AutomaticVehicleIdentifier identifier;
    late VehicleCompatibilityEvaluator evaluator;
    late ConnectionRecoveryEngine recoveryEngine;
    late PairedVehicleMemoryService memoryService;
    late GenericVehicleConnectivityEngine connectivityEngine;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      identifier = AutomaticVehicleIdentifier();
      evaluator = VehicleCompatibilityEvaluator();
      recoveryEngine = ConnectionRecoveryEngine();
      memoryService = PairedVehicleMemoryService();
      connectivityEngine = GenericVehicleConnectivityEngine();
    });

    test('AutomaticVehicleIdentifier detects Yamaha R15 V4 CCU without guessing', () {
      final device = BluetoothDevice.fromId('DC:A6:32:01:23:45');
      final advData = AdvertisementData(
        advName: 'YAMAHA-R15-CCU-902',
        txPowerLevel: null,
        connectable: true,
        manufacturerData: const {},
        serviceData: const {},
        serviceUuids: [Guid('0000fee0-0000-1000-8000-00805f9b34fb')],
        appearance: null,
      );

      final result = identifier.identifyFromScan(
        device: device,
        advertisementData: advData,
      );

      expect(result.isIdentified, isTrue);
      expect(result.brand, equals('Yamaha'));
      expect(result.model, equals('YZF-R15'));
      expect(result.protocolAdapterId, equals('yamaha_y_connect'));
      expect(result.confidence, greaterThanOrEqualTo(0.90));
    });

    test('AutomaticVehicleIdentifier labels unknown BLE peripheral without guessing vehicle model', () {
      final device = BluetoothDevice.fromId('AA:BB:CC:DD:EE:FF');
      final advData = AdvertisementData(
        advName: 'Random_Sensor_123',
        txPowerLevel: null,
        connectable: true,
        manufacturerData: const {},
        serviceData: const {},
        serviceUuids: const [],
        appearance: null,
      );

      final result = identifier.identifyFromScan(
        device: device,
        advertisementData: advData,
      );

      expect(result.isIdentified, isFalse);
      expect(result.model, isNull);
      expect(result.displayName, contains('Model Identification Unavailable'));
      expect(result.confidence, lessThan(0.50));
    });

    test('VehicleCompatibilityEvaluator scores full connected vs OBD-II gateway accurately', () {
      final fullEval = evaluator.evaluate(VehicleCapabilities.fullConnectedTwoWheeler());
      expect(fullEval.category, equals(CompatibilityScoreCategory.fullyCompatible));
      expect(fullEval.overallScorePercentage, greaterThanOrEqualTo(80));
      expect(fullEval.supportedFeatures.any((f) => f.featureName.contains('Speed')), isTrue);
      expect(fullEval.supportedFeatures.any((f) => f.featureName.contains('Smart Display')), isTrue);

      final obdEval = evaluator.evaluate(VehicleCapabilities.standardObdGateway());
      expect(obdEval.category, equals(CompatibilityScoreCategory.partiallyCompatible));
      expect(obdEval.unsupportedFeatures.any((f) => f.featureName.contains('Smart Display')), isTrue);
    });

    test('PairedVehicleMemoryService saves, retrieves, updates and auto-connects vehicle', () async {
      final record = PairedVehicleRecord(
        id: 'veh_r15_01',
        deviceIdentifier: 'DC:A6:32:01:23:45',
        brand: 'Yamaha',
        model: 'YZF-R15',
        variant: 'M',
        modelYear: 2024,
        category: 'Motorcycle',
        fuelType: 'Petrol',
        protocolAdapterId: 'yamaha_y_connect',
        capabilities: const VehicleCapabilities(
          connectionType: CapabilitySupportLevel.supported,
          speed: CapabilitySupportLevel.readOnly,
        ),
        compatibilityLevel: VehicleCompatibilityLevel.full,
        pairedAt: DateTime.now(),
        lastConnectedAt: DateTime.now(),
        isPrimary: true,
      );

      await memoryService.savePairedVehicle(record);
      final vehicles = await memoryService.getPairedVehicles();
      expect(vehicles, isNotEmpty);
      expect(vehicles.first.brand, equals('Yamaha'));
      expect(vehicles.first.isPrimary, isTrue);

      final autoConnected = await memoryService.connectAutomatically(vehicles.first);
      expect(autoConnected, isFalse, reason: 'Auto-connect must fail without a real underlying transport');
      expect(connectivityEngine.currentState, equals(AdapterConnectionState.error));

      await memoryService.forgetVehicle('veh_r15_01');
      final remaining = await memoryService.getPairedVehicles();
      expect(remaining, isEmpty);
    });

    test('ConnectionRecoveryEngine tracks connection and emits state transitions', () async {
      recoveryEngine.trackActiveConnection(
        targetIdentifier: 'DC:A6:32:01:23:45',
        protocolAdapterId: 'yamaha_y_connect',
      );

      expect(recoveryEngine.currentSnapshot.state, equals(ConnectionRecoveryState.monitoring));
      expect(recoveryEngine.currentSnapshot.maxAttempts, equals(5));

      recoveryEngine.reset();
      expect(recoveryEngine.currentSnapshot.state, equals(ConnectionRecoveryState.idle));
    });
  });
}
