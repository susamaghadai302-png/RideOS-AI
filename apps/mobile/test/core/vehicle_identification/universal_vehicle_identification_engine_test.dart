import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/ecosystem/rideos_master_architecture.dart';
import 'package:rideos_mobile/core/vehicle_identification/models/universal_vehicle_profile.dart';
import 'package:rideos_mobile/core/vehicle_identification/models/vin_decoder_models.dart';
import 'package:rideos_mobile/core/vehicle_identification/presentation/screens/smart_vehicle_identification_screen.dart';
import 'package:rideos_mobile/core/vehicle_identification/services/smart_scan_orchestrator.dart';
import 'package:rideos_mobile/core/vehicle_identification/services/vin_identification_engine.dart';
import 'package:rideos_mobile/core/vehicle_identification/services/vin_ocr_scanner_engine.dart';

void main() {
  group('Phase 16: Universal Vehicle Identification Engine Tests', () {
    final vinEngine = VinIdentificationEngine.instance;
    final ocrEngine = VinOcrScannerEngine.instance;
    final smartScan = SmartScanOrchestrator.instance;

    test('1. VIN Normalization cleans whitespace, dashes, and lowercase characters', () {
      const raw = ' jya-rn39e5fa-000101 \n';
      final normalized = vinEngine.normalizeVin(raw);
      expect(normalized, equals('JYARN39E5FA000101'));
      expect(normalized.length, equals(17));
    });

    test('2. VIN Format Validation rejects invalid characters and lengths', () {
      expect(vinEngine.validateVinStructure(''), equals(VinValidationStatus.emptyInput));
      expect(vinEngine.validateVinStructure('12345'), equals(VinValidationStatus.invalidLength));
      expect(vinEngine.validateVinStructure('JYARN39EIFA000101'), equals(VinValidationStatus.invalidCharacters)); // 'I' is invalid
      expect(vinEngine.validateVinStructure('JYARN39EOFA000101'), equals(VinValidationStatus.invalidCharacters)); // 'O' is invalid
      expect(vinEngine.validateVinStructure('JYARN39EQFA000101'), equals(VinValidationStatus.invalidCharacters)); // 'Q' is invalid
    });

    test('3. ISO 3779 Check Digit Algorithm computes accurate mathematical check digit', () {
      // Yamaha YZF-R1M VIN check digit at index 8 is '5'
      const vin = 'JYARN39E5FA000101';
      final checkDigit = vinEngine.computeCheckDigit(vin);
      expect(checkDigit, equals('5'));

      // Check digit calculation validation
      expect(vinEngine.validateVinStructure(vin), equals(VinValidationStatus.valid));

      // Altering a single digit invalidates check digit
      const tampered = 'JYARN39E5FA000102';
      expect(vinEngine.validateVinStructure(tampered), equals(VinValidationStatus.invalidCheckDigit));
    });

    test('4. Exact VIN Decoding resolves manufacturer, model, and year', () {
      final result = vinEngine.decodeVin('JYARN39E5FA000101');
      expect(result.isValid, isTrue);
      expect(result.validationStatus, equals(VinValidationStatus.valid));
      expect(result.decodedDetails?.manufacturer, contains('Yamaha'));
      expect(result.decodedDetails?.domainType, equals(VehicleDomainType.motorcycle));
      expect(result.decodedDetails?.modelYear, equals(2015)); // 'F' = 2015
      expect(result.resolvedVehicleModel, contains('YZF-R1M'));
      expect(result.confidenceScore, equals(1.0));
    });

    test('5. Unregistered WMI produces explicit Unresolved State without fabricating vehicle data', () {
      // Synthetic VIN with valid check digit ('7') but unknown WMI 'ZZZ'
      const unregVin = 'ZZZ123457FA000101';
      final result = vinEngine.decodeVin(unregVin);
      expect(result.validationStatus, equals(VinValidationStatus.unrecognizedWmi));
      expect(result.resolvedVehicleModel, isNull);
      expect(result.confidenceScore, lessThan(1.0));
      expect(result.unresolvedReason, contains('not registered in authoritative local catalog'));
    });

    test('6. OCR VIN Scanner parses text streams, sliding windows, and applies heuristics', () {
      const noisyOcr = '''
        STATE REGISTRATION CERTIFICATE
        CHASSIS NUMBER: JYARN39E5FA000101
        MOTOR NO: CP4-998-0042
        WEIGHT: 201 KG
      ''';

      final matches = ocrEngine.parseOcrText(noisyOcr);
      expect(matches.isNotEmpty, isTrue);
      expect(matches.first.candidateVin, equals('JYARN39E5FA000101'));
      expect(matches.first.isExactChecksumVerified, isTrue);
      expect(matches.first.ocrConfidence, equals(1.0));
    });

    test('7. Smart Scan Orchestration probes transport, protocol, Mode 09 and builds Universal Profile', () async {
      final profile = await smartScan.executeSmartScan(
        mode: SmartScanExecutionMode.simulator,
        preferredTransport: PhysicalTransportType.bluetoothLowEnergy,
        mockModelTarget: 'Yamaha',
      );

      expect(profile, isNotNull);
      expect(profile!.manufacturer, equals('Yamaha'));
      expect(profile.model, equals('YZF-R1M'));
      expect(profile.domain, equals(VehicleDomainType.motorcycle));
      expect(profile.propulsionType, equals(PropulsionType.internalCombustion));
      expect(profile.engineOrMotorCode, contains('CP4'));
      expect(profile.maxPowerHp, equals(200.0));
      expect(profile.identificationConfidence, equals(UniversalIdentificationConfidence.exactVinMatch));
      expect(profile.identificationSource, equals(IdentificationSource.simulatedTestBench));
      expect(profile.capabilities.supportsDiagnostics, isTrue);
      expect(profile.capabilities.supportsTelemetry, isTrue);
      expect(profile.capabilities.supportsNavigation, isTrue);
    });

    test('8. Smart Scan distinguishes Real Hardware vs Simulator Mode', () async {
      final hardwareProfile = await smartScan.executeSmartScan(
        mode: SmartScanExecutionMode.realHardware,
        preferredTransport: PhysicalTransportType.bluetoothLowEnergy,
        mockModelTarget: 'Ducati',
      );

      expect(hardwareProfile, isNotNull);
      expect(hardwareProfile!.manufacturer, equals('Ducati'));
      expect(hardwareProfile.model, equals('Panigale V4 S'));
      expect(hardwareProfile.identificationSource, equals(IdentificationSource.obdEcuQuery));
      expect(hardwareProfile.maxPowerHp, equals(214.0));
    });

    test('9. Manual Fallback Profile constructor generates complete profile', () {
      final manual = smartScan.buildManualFallbackProfile(
        domain: VehicleDomainType.car,
        manufacturer: 'Porsche',
        model: '911 GT3 (992)',
        generation: '992.1',
        year: 2024,
        variant: 'Clubsport',
        engine: '4.0L Naturally Aspirated Flat-6',
        fuel: FuelType.petrol98,
        transmission: TransmissionType.dualClutch,
        powerHp: 510.0,
        torqueNm: 470.0,
        model3dPath: 'assets/3d/porsche_911.glb',
      );

      expect(manual.manufacturer, equals('Porsche'));
      expect(manual.domain, equals(VehicleDomainType.car));
      expect(manual.maxPowerHp, equals(510.0));
      expect(manual.identificationConfidence, equals(UniversalIdentificationConfidence.manualSelection));
      expect(manual.identificationSource, equals(IdentificationSource.manualCatalogSelection));
    });

    testWidgets('10. SmartVehicleIdentificationScreen renders tabs and UI controls', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: SmartVehicleIdentificationScreen(
            initialMode: SmartScanExecutionMode.simulator,
          ),
        ),
      );

      expect(find.text('UNIVERSAL VEHICLE IDENTIFIER'), findsOneWidget);
      expect(find.text('Smart Scan'), findsOneWidget);
      expect(find.text('VIN Decoder'), findsOneWidget);
      expect(find.text('OCR Scanner'), findsOneWidget);
      expect(find.text('SCAN (YAMAHA)'), findsOneWidget);
      expect(find.text('SCAN (DUCATI)'), findsOneWidget);
    });
  });
}
