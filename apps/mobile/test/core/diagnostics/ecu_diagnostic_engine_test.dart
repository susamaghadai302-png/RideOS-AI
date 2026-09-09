import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/diagnostics/models/diagnostic_types.dart';
import 'package:rideos_mobile/core/diagnostics/models/dtc_record.dart';
import 'package:rideos_mobile/core/diagnostics/models/pid_definition.dart';
import 'package:rideos_mobile/core/diagnostics/protocol/iso_tp_handler.dart';
import 'package:rideos_mobile/core/diagnostics/protocol/obd2_command_builder.dart';
import 'package:rideos_mobile/core/diagnostics/protocol/uds_command_builder.dart';
import 'package:rideos_mobile/core/diagnostics/services/diagnostic_database.dart';
import 'package:rideos_mobile/core/diagnostics/services/ecu_diagnostic_manager.dart';
import 'package:rideos_mobile/core/diagnostics/presentation/screens/ecu_diagnostic_console_screen.dart';
import 'package:rideos_mobile/core/transport/services/transport_manager.dart';
import 'package:rideos_mobile/core/vehicle_identification/services/smart_scan_orchestrator.dart';

void main() {
  group('Phase 18: ECU / OBD / CAN / UDS Diagnostic Engine Tests', () {
    // ======================================================================
    // 1. ISO-TP Single Frame (SF)
    // ======================================================================
    test('1. IsoTpHandler encodes and decodes Single Frame payloads correctly', () {
      final handler = IsoTpHandler();
      final payload = [0x01, 0x0C]; // Mode 01 PID 0C (RPM)

      final frames = handler.encodePayload(payload);
      expect(frames.length, equals(1));
      expect(frames[0][0], equals(0x02)); // SF, length=2
      expect(frames[0][1], equals(0x01));
      expect(frames[0][2], equals(0x0C));

      final decoded = handler.processIncomingCanFrame(frames[0]);
      expect(decoded, isNotNull);
      expect(decoded!.length, equals(2));
      expect(decoded[0], equals(0x01));
      expect(decoded[1], equals(0x0C));
    });

    // ======================================================================
    // 2. ISO-TP Multi-Frame (FF + CF) Reassembly
    // ======================================================================
    test('2. IsoTpHandler segments and reassembles Multi-Frame payloads', () {
      final handler = IsoTpHandler();
      // 20-byte payload (e.g. VIN response)
      final longPayload = List<int>.generate(20, (i) => 0x40 + i);

      final frames = handler.encodePayload(longPayload);
      expect(frames.length, equals(3)); // 1 FF (6 bytes) + 2 CF (7 bytes + 7 bytes)

      // First Frame: PCI type 0x10 | (20 >> 8) = 0x10, byte1 = 20
      expect(frames[0][0], equals(0x10));
      expect(frames[0][1], equals(20));

      // Consecutive Frame 1: PCI type 0x20 | 1 = 0x21
      expect(frames[1][0], equals(0x21));

      // Consecutive Frame 2: PCI type 0x20 | 2 = 0x22
      expect(frames[2][0], equals(0x22));

      // Process FF -> returns null (incomplete)
      expect(handler.processIncomingCanFrame(frames[0]), isNull);
      expect(handler.isReassembling, isTrue);

      // Process CF1 -> returns null (incomplete)
      expect(handler.processIncomingCanFrame(frames[1]), isNull);

      // Process CF2 -> reassembly completes
      final reassembled = handler.processIncomingCanFrame(frames[2]);
      expect(reassembled, isNotNull);
      expect(reassembled!.length, equals(20));
      expect(reassembled, equals(longPayload));
      expect(handler.isReassembling, isFalse);
    });

    test('3. IsoTpHandler encodes Flow Control frames accurately', () {
      final handler = IsoTpHandler();
      final fc = handler.encodeFlowControl(
        status: IsoTpFlowStatus.continueToSend,
        blockSize: 8,
        separationTimeMs: 10,
      );

      expect(fc[0], equals(0x30)); // FC type 3, status 0 (CTS)
      expect(fc[1], equals(8));    // Block Size
      expect(fc[2], equals(10));   // STmin
    });

    // ======================================================================
    // 4. Standard OBD-II PID Mathematics
    // ======================================================================
    test('4. DiagnosticPid decoders compute accurate physical units', () {
      // RPM: ((A * 256) + B) / 4 -> ((0x1A * 256) + 0xF8) / 4 = (6656 + 248) / 4 = 1726.0 RPM
      final rpmVal = DiagnosticPid.engineRpm.decode([0x1A, 0xF8]);
      expect(rpmVal, equals(1726.0));

      // Speed: raw byte A = 85 km/h
      final speedVal = DiagnosticPid.vehicleSpeed.decode([0x55]);
      expect(speedVal, equals(85.0));

      // Coolant Temp: A - 40 -> 128 - 40 = 88.0 °C
      final tempVal = DiagnosticPid.coolantTemperature.decode([0x80]);
      expect(tempVal, equals(88.0));

      // Voltage: ((A * 256) + B) / 1000 -> ((0x37 * 256) + 0xDC) / 1000 = (14080 + 220) / 1000 = 14.3 V
      final voltVal = DiagnosticPid.controlModuleVoltage.decode([0x37, 0xDC]);
      expect(voltVal, closeTo(14.3, 0.001));

      // Throttle: (A * 100) / 255 -> (128 * 100) / 255 = 50.196%
      final throttleVal = DiagnosticPid.throttlePosition.decode([0x80]);
      expect(throttleVal, closeTo(50.196, 0.01));
    });

    // ======================================================================
    // 5. OBD-II Command Builder & Response Parsing
    // ======================================================================
    test('5. Obd2CommandBuilder formats ASCII commands correctly', () {
      expect(Obd2CommandBuilder.requestLivePid(DiagnosticPid.engineRpm), equals('010C\r'));
      expect(Obd2CommandBuilder.requestConfirmedDtcs(), equals('03\r'));
      expect(Obd2CommandBuilder.requestClearDtcs(), equals('04\r'));
      expect(Obd2CommandBuilder.requestVin(), equals('0902\r'));
      expect(Obd2CommandBuilder.requestEcuName(), equals('090A\r'));
    });

    test('6. Obd2CommandBuilder parses ASCII hex strings into byte arrays', () {
      const elmOutput = '41 0C 1A F8 >\r\n';
      final bytes = Obd2CommandBuilder.parseAsciiHexToBytes(elmOutput);
      expect(bytes, equals([0x41, 0x0C, 0x1A, 0xF8]));

      final measurement = Obd2CommandBuilder.parseMode01Response(bytes, DiagnosticPid.engineRpm);
      expect(measurement, isNotNull);
      expect(measurement!.value, equals(1726.0));
      expect(measurement.unit, equals('RPM'));
    });

    // ======================================================================
    // 7. SAE J1979 2-Byte DTC Parsing
    // ======================================================================
    test('7. DiagnosticFaultRecord parses raw 2-byte DTCs across P, C, B, U categories', () {
      // Powertrain: P0115 (byteA=0x01, byteB=0x15 -> 0000 0001 0001 0101)
      final pCode = DiagnosticFaultRecord.fromRawBytes(0x01, 0x15);
      expect(pCode.code, equals('P0115'));
      expect(pCode.category, equals(DtcSystemCategory.powertrain));

      // Chassis: C0035 (byteA=0x40, byteB=0x35 -> 0100 0000 0011 0101)
      final cCode = DiagnosticFaultRecord.fromRawBytes(0x40, 0x35);
      expect(cCode.code, equals('C0035'));
      expect(cCode.category, equals(DtcSystemCategory.chassis));

      // Body: B1000 (byteA=0x90, byteB=0x00 -> 1001 0000 0000 0000)
      final bCode = DiagnosticFaultRecord.fromRawBytes(0x90, 0x00);
      expect(bCode.code, equals('B1000'));
      expect(bCode.category, equals(DtcSystemCategory.body));

      // Network: U0100 (byteA=0xC1, byteB=0x00 -> 1100 0001 0000 0000)
      final uCode = DiagnosticFaultRecord.fromRawBytes(0xC1, 0x00);
      expect(uCode.code, equals('U0100'));
      expect(uCode.category, equals(DtcSystemCategory.network));
    });

    // ======================================================================
    // 8. OBD-II Mode $09 VIN Parsing
    // ======================================================================
    test('8. Obd2CommandBuilder decodes Mode 09 VIN responses', () {
      // 0x49 (Mode 49), 0x02 (PID 02), sequence + ASCII 'JYARN39E5FA000101'
      final rawVinBytes = [
        0x49, 0x02, 0x01,
        0x4A, 0x59, 0x41, 0x52, 0x4E, 0x33, 0x39, 0x45, 0x35, 0x46, 0x41, 0x30, 0x30, 0x30, 0x31, 0x30, 0x31,
      ];
      final vin = Obd2CommandBuilder.parseVinResponse(rawVinBytes);
      expect(vin, equals('JYARN39E5FA000101'));
    });

    // ======================================================================
    // 9. UDS ISO 14229-1 Command Building & Responses
    // ======================================================================
    test('9. UdsCommandBuilder generates compliant UDS service requests', () {
      final sessionReq = UdsCommandBuilder.buildSessionControl(UdsSessionType.extendedDiagnosticSession);
      expect(sessionReq, equals([0x10, 0x03]));

      final readDtcReq = UdsCommandBuilder.buildReadDtcByStatusMask(0xFF);
      expect(readDtcReq, equals([0x19, 0x02, 0xFF]));

      final readDidReq = UdsCommandBuilder.buildReadDataByIdentifier(0xF190);
      expect(readDidReq, equals([0x22, 0xF1, 0x90]));

      final clearDtcReq = UdsCommandBuilder.buildClearDtcInformation(0xFFFFFF);
      expect(clearDtcReq, equals([0x14, 0xFF, 0xFF, 0xFF]));
    });

    test('10. UdsCommandBuilder identifies and parses Negative Response Codes (NRC)', () {
      final nrcResponse = [0x7F, 0x22, 0x33]; // Service 22, NRC 0x33 (Security Access Denied)
      expect(UdsCommandBuilder.isNegativeResponse(nrcResponse), isTrue);

      final nrc = UdsCommandBuilder.parseNegativeResponseCode(nrcResponse);
      expect(nrc, equals(UdsNegativeResponseCode.securityAccessDenied));
      expect(nrc!.description, contains('Security Access Denied'));
    });

    test('11. UdsCommandBuilder parses UDS 3-byte DTC status mask records', () {
      // 0x59 (Positive resp to 0x19), subfunction 0x02, status availability mask 0xFF,
      // Entry 1: [0x01, 0x15, 0x00, 0x08] -> P0115 confirmed (0x08)
      final udsDtcPayload = [0x59, 0x02, 0xFF, 0x01, 0x15, 0x00, 0x08];
      final faults = UdsCommandBuilder.parseUdsDtcResponse(udsDtcPayload);

      expect(faults.length, equals(1));
      expect(faults.first.code, equals('P0115'));
      expect(faults.first.severity, equals(DtcSeverity.confirmedActive));
    });

    // ======================================================================
    // 12. Diagnostic Database Lookups
    // ======================================================================
    test('12. DiagnosticDatabase enriches fault codes with causes and remedies', () {
      final db = DiagnosticDatabase.instance;

      final p0300 = db.lookup('P0300');
      expect(p0300.title, contains('Misfire'));
      expect(p0300.severity, equals(DtcSeverity.criticalStopEngine));
      expect(p0300.isMilLampTriggered, isTrue);

      final u0100 = db.lookup('U0100');
      expect(u0100.title, contains('Lost Communication With Engine Control Module'));
      expect(u0100.category, equals(DtcSystemCategory.network));

      final c0035 = db.lookup('C0035');
      expect(c0035.title, contains('Wheel Speed'));
      expect(c0035.category, equals(DtcSystemCategory.chassis));
    });

    // ======================================================================
    // 13. Multi-ECU Bus Addressing
    // ======================================================================
    test('13. EcuModule defines distinct request and response CAN addresses', () {
      expect(EcuModule.engineControlModule_ECM.requestAddress, equals(0x7E0));
      expect(EcuModule.engineControlModule_ECM.responseAddress, equals(0x7E8));

      expect(EcuModule.antiLockBraking_ABS.requestAddress, equals(0x7E2));
      expect(EcuModule.antiLockBraking_ABS.responseAddress, equals(0x7EA));

      expect(EcuModule.batteryManagementSystem_BMS.requestAddress, equals(0x7E3));
      expect(EcuModule.batteryManagementSystem_BMS.responseAddress, equals(0x7EB));
    });

    // ======================================================================
    // 14. Multi-ECU Manager Full Scan
    // ======================================================================
    test('14. EcuDiagnosticManager executes full multi-module ECU scan in simulator mode', () async {
      final manager = EcuDiagnosticManager.instance;
      TransportManager.instance.setExecutionMode(SmartScanExecutionMode.simulator);

      final faults = await manager.performFullEcuScan();

      expect(faults, isNotEmpty);
      expect(manager.moduleResults.containsKey(EcuModule.engineControlModule_ECM), isTrue);
      expect(manager.moduleResults[EcuModule.engineControlModule_ECM]!.isResponding, isTrue);
      expect(manager.moduleResults.containsKey(EcuModule.antiLockBraking_ABS), isTrue);

      expect(faults.any((f) => f.code == 'P0115'), isTrue);
      expect(faults.any((f) => f.code == 'P0300'), isTrue);
    });

    // ======================================================================
    // 15. Safety-Gated DTC Clear Enforcement
    // ======================================================================
    test('15. EcuDiagnosticManager enforces fail-closed safety interlock when telemetry is missing', () async {
      final manager = EcuDiagnosticManager.instance;
      TransportManager.instance.setExecutionMode(SmartScanExecutionMode.simulator);

      // Must require confirmation
      expect(() => manager.clearAllDiagnosticFaults(forceConfirmation: false), throwsArgumentError);

      // Fails closed because telemetry is missing
      expect(() => manager.clearAllDiagnosticFaults(forceConfirmation: true), throwsStateError);
    });

    // ======================================================================
    // 16. UI Console Widget Test
    // ======================================================================
    testWidgets('16. EcuDiagnosticConsoleScreen renders tabs, ECU bus, and controls', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: EcuDiagnosticConsoleScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('MULTI-ECU DIAGNOSTICS'), findsOneWidget);

      // Verify tabs
      expect(find.text('ECU BUS'), findsOneWidget);
      expect(find.text('LIVE PIDS'), findsOneWidget);
      expect(find.text('FAULTS'), findsOneWidget);
      expect(find.text('ISO-TP LOG'), findsOneWidget);

      // Verify action buttons
      expect(find.text('SCAN ALL ECUS'), findsOneWidget);
      expect(find.text('CLEAR DTCs'), findsOneWidget);

      // Tap LIVE PIDS tab
      await tester.tap(find.text('LIVE PIDS'));
      await tester.pumpAndSettle();

      // Tap FAULTS tab
      await tester.tap(find.text('FAULTS'));
      await tester.pumpAndSettle();

      // Tap ISO-TP LOG tab
      await tester.tap(find.text('ISO-TP LOG'));
      await tester.pumpAndSettle();
      expect(find.textContaining('ISO 15765-2'), findsOneWidget);
    });
  });
}
