import 'dart:typed_data';
import '../models/diagnostic_types.dart';
import '../models/dtc_record.dart';

/// Standard UDS Negative Response Codes (NRC) per ISO 14229-1.
enum UdsNegativeResponseCode {
  generalReject(0x10, 'General Reject'),
  serviceNotSupported(0x11, 'Service Not Supported'),
  subFunctionNotSupported(0x12, 'Sub-Function Not Supported'),
  incorrectMessageLengthOrInvalidFormat(0x13, 'Incorrect Message Length or Invalid Format'),
  responseTooLong(0x14, 'Response Too Long'),
  busyRepeatRequest(0x21, 'Busy — Repeat Request'),
  conditionsNotCorrect(0x22, 'Conditions Not Correct (Vehicle State Constraint)'),
  requestSequenceError(0x24, 'Request Sequence Error'),
  noResponseFromSubnetComponent(0x25, 'No Response From Subnet Component'),
  failurePreventsExecution(0x26, 'Failure Prevents Execution Of Requested Action'),
  requestOutOfRange(0x31, 'Request Out Of Range'),
  securityAccessDenied(0x33, 'Security Access Denied / Key Required'),
  invalidKey(0x35, 'Invalid Security Key'),
  exceededNumberOfAttempts(0x36, 'Exceeded Number Of Security Attempts'),
  requiredTimeDelayNotExpired(0x37, 'Required Time Delay Not Expired'),
  responsePending(0x78, 'Request Correctly Received — Response Pending');

  final int code;
  final String description;
  const UdsNegativeResponseCode(this.code, this.description);

  static UdsNegativeResponseCode fromCode(int code) {
    return UdsNegativeResponseCode.values.firstWhere(
      (e) => e.code == code,
      orElse: () => UdsNegativeResponseCode.generalReject,
    );
  }
}

/// ISO 14229-1 Unified Diagnostic Services (UDS) Command Builder & Parser.
class UdsCommandBuilder {
  // =========================================================================
  // Service Request Builders
  // =========================================================================

  /// Service $10: DiagnosticSessionControl
  static Uint8List buildSessionControl(UdsSessionType sessionType) {
    return Uint8List.fromList([
      UdsService.diagnosticSessionControl.serviceId,
      sessionType.typeByte,
    ]);
  }

  /// Service $11: ECUReset
  /// Subfunction: 0x01 (Hard Reset), 0x02 (Key Off/On), 0x03 (Soft Reset)
  static Uint8List buildEcuReset([int resetType = 0x01]) {
    return Uint8List.fromList([
      UdsService.ecuReset.serviceId,
      resetType & 0xFF,
    ]);
  }

  /// Service $14: ClearDiagnosticInformation
  /// Clears DTCs for a 3-byte group (0xFFFFFF = all DTCs).
  static Uint8List buildClearDtcInformation([int dtcGroupMask = 0xFFFFFF]) {
    return Uint8List.fromList([
      UdsService.clearDiagnosticInformation.serviceId,
      (dtcGroupMask >> 16) & 0xFF,
      (dtcGroupMask >> 8) & 0xFF,
      dtcGroupMask & 0xFF,
    ]);
  }

  /// Service $19: ReadDTCInformation
  /// Subfunction 0x02: reportDTCByStatusMask (e.g. 0xFF for all active/pending/history)
  static Uint8List buildReadDtcByStatusMask([int statusMask = 0xFF]) {
    return Uint8List.fromList([
      UdsService.readDtcInformation.serviceId,
      0x02, // sub-function reportDTCByStatusMask
      statusMask & 0xFF,
    ]);
  }

  /// Service $22: ReadDataByIdentifier (DID)
  /// Reads a 2-byte standard DID (e.g. 0xF190 for VIN, 0xF188 for ECU SW ID).
  static Uint8List buildReadDataByIdentifier(int dataIdentifier) {
    return Uint8List.fromList([
      UdsService.readDataByIdentifier.serviceId,
      (dataIdentifier >> 8) & 0xFF,
      dataIdentifier & 0xFF,
    ]);
  }

  /// Service $31: RoutineControl
  /// Subfunction: 0x01 (Start), 0x02 (Stop), 0x03 (Request Results)
  static Uint8List buildRoutineControl(int routineId, {int subFunction = 0x01, List<int>? controlOptionRecord}) {
    final bytes = <int>[
      UdsService.routineControl.serviceId,
      subFunction & 0xFF,
      (routineId >> 8) & 0xFF,
      routineId & 0xFF,
    ];
    if (controlOptionRecord != null) {
      bytes.addAll(controlOptionRecord);
    }
    return Uint8List.fromList(bytes);
  }

  /// Service $3E: TesterPresent Keep-Alive
  static Uint8List buildTesterPresent({bool suppressPositiveResponse = false}) {
    return Uint8List.fromList([
      UdsService.testerPresent.serviceId,
      suppressPositiveResponse ? 0x80 : 0x00,
    ]);
  }

  // =========================================================================
  // Response Parsers
  // =========================================================================

  /// Checks if incoming response is a UDS Negative Response (Service $7F).
  static bool isNegativeResponse(List<int> response) {
    return response.length >= 3 && response[0] == 0x7F;
  }

  /// Extracts Negative Response Code details if response is negative.
  static UdsNegativeResponseCode? parseNegativeResponseCode(List<int> response) {
    if (!isNegativeResponse(response)) return null;
    return UdsNegativeResponseCode.fromCode(response[2]);
  }

  /// Checks if incoming response is a Positive Response for the given service.
  static bool isPositiveResponse(List<int> response, UdsService service) {
    return response.isNotEmpty && response[0] == service.positiveResponseId;
  }

  /// Parses UDS Service $19 subfunction $02 response into a list of [DiagnosticFaultRecord].
  ///
  /// UDS 3-byte DTC format: [Byte High, Byte Middle, Byte Low, StatusByte].
  static List<DiagnosticFaultRecord> parseUdsDtcResponse(
    List<int> response, {
    EcuModule module = EcuModule.engineControlModule_ECM,
  }) {
    if (response.length < 3 || response[0] != 0x59 || response[1] != 0x02) {
      return const [];
    }

    final dtcs = <DiagnosticFaultRecord>[];
    // Byte 2 is DTCStatusAvailabilityMask
    // Bytes 3+ contain 4-byte entries: [DTC_High, DTC_Mid, DTC_Low, DTC_Status]
    for (int i = 3; i + 3 < response.length; i += 4) {
      final high = response[i];
      final mid = response[i + 1];
      final low = response[i + 2];
      final status = response[i + 3];

      if (high == 0 && mid == 0 && low == 0) continue;

      // Extract severity from status mask (Bit 0: TestFailed, Bit 3: ConfirmedDTC, Bit 2: PendingDTC)
      final isConfirmed = (status & 0x08) != 0;
      final isPending = (status & 0x04) != 0;
      final severity = isConfirmed
          ? DtcSeverity.confirmedActive
          : (isPending ? DtcSeverity.pending : DtcSeverity.info);

      final dtc = DiagnosticFaultRecord.fromRawBytes(
        high,
        mid,
        module: module,
        severity: severity,
      );
      if (!dtcs.contains(dtc)) {
        dtcs.add(dtc);
      }
    }
    return dtcs;
  }

  /// Parses Service $22 DID response payload.
  static List<int>? parseDidData(List<int> response, int expectedDid) {
    if (response.length < 3) return null;
    if (response[0] != 0x62) return null; // positive response to 0x22

    final did = (response[1] << 8) | response[2];
    if (did != expectedDid) return null;

    return response.sublist(3);
  }
}
