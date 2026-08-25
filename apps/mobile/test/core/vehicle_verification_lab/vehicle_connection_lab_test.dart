import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rideos_mobile/core/vehicle_catalog/services/universal_vehicle_catalog_service.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/models/vehicle_variant_taxonomy.dart';
import 'package:rideos_mobile/core/vehicle_verification_lab/models/verification_lab_models.dart';
import 'package:rideos_mobile/core/vehicle_verification_lab/services/vehicle_connection_lab_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Real Vehicle Connection Lab & Protocol Verification Tests', () {
    late UniversalVehicleCatalogService catalog;
    late VehicleConnectionLabService labService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      catalog = UniversalVehicleCatalogService();
      await catalog.initialize();
      labService = VehicleConnectionLabService();
    });

    test('Runs automated bench verification pipeline on Yamaha R15 V4', () async {
      final r15 = catalog.getProfileById('yamaha_r15_v4_m')!;

      final report = await labService.runVerificationPipeline(
        profile: r15,
        selectedMethod: VehicleConnectivityType.ble,
        isSimulatedBenchMode: true,
      );

      expect(report.reportId, isNotEmpty);
      expect(report.manufacturer, equals('Yamaha'));
      expect(report.verificationGrade, equals(HardwareVerificationGrade.automatedBenchVerified));
      expect(report.isSimulatedBenchDevice, isTrue);
      expect(report.overallScorePercentage, greaterThanOrEqualTo(80));

      // Check discovered GATT services
      expect(report.discoveredServices, isNotEmpty);
      expect(report.discoveredServices.first.serviceName, contains('Yamaha'));

      // Check capability evidence
      expect(report.capabilityAudits.any((a) => a.capabilityName.contains('Speed')), isTrue);
      expect(report.capabilityAudits.any((a) => a.capabilityName.contains('Navigation')), isTrue);

      // Verify connection metrics
      expect(report.qualityMetrics.latencyMs, lessThan(50));
      expect(report.qualityMetrics.packetSuccessRatePct, greaterThanOrEqualTo(95));
      expect(report.qualityMetrics.autoRecoveryVerified, isTrue);
    });

    test('Runs verification pipeline on Universal OBD-II diagnostic gateway', () async {
      final obd = catalog.getProfileById('universal_euro5_obd2')!;

      final report = await labService.runVerificationPipeline(
        profile: obd,
        selectedMethod: VehicleConnectivityType.obd2Gateway,
        isSimulatedBenchMode: true,
      );

      expect(report.manufacturer, equals('Universal / Generic'));
      expect(report.requiresExternalGateway, isTrue);
      expect(report.discoveredServices.first.serviceName, contains('SAE J1979 OBD-II'));
      expect(report.capabilityAudits.any((a) => a.capabilityName.contains('DTC')), isTrue);
    });

    test('Maintains historical verification reports in memory cache', () async {
      final himalayan = catalog.getProfileById('re_himalayan450')!;

      final initialCount = labService.historicalReports.length;
      await labService.runVerificationPipeline(
        profile: himalayan,
        selectedMethod: VehicleConnectivityType.smartDisplayMirror,
        isSimulatedBenchMode: true,
      );

      expect(labService.historicalReports.length, equals(initialCount + 1));
      expect(labService.historicalReports.first.manufacturer, equals('Royal Enfield'));
    });
  });
}
