import 'dart:convert';
import 'dart:typed_data';
import '../models/diagnostic_types.dart';
import '../models/dtc_record.dart';
import '../models/pid_definition.dart';

/// SAE J1979 OBD-II Diagnostic Command Builder and Response Parser.
class Obd2CommandBuilder {
  /// Builds ASCII command string for ELM327/STN adapters (e.g. "010C\r").
  static String buildAsciiCommand(ObdMode mode, [String? pidHex]) {
    final modeStr = mode.serviceByte.toRadixString(16).padLeft(2, '0').toUpperCase();
    if (pidHex != null && pidHex.isNotEmpty) {
      return '$modeStr${pidHex.toUpperCase()}\r';
    }
    return '$modeStr\r';
  }

  /// Builds raw binary request payload for direct CAN/ISO-TP frames.
  static Uint8List buildBinaryRequest(ObdMode mode, [int? pid]) {
    if (pid != null) {
      return Uint8List.fromList([mode.serviceByte, pid & 0xFF]);
    }
    return Uint8List.fromList([mode.serviceByte]);
  }

  // =========================================================================
  // Standard OBD-II Requests
  // =========================================================================

  /// Mode $01 Request: Read Live PID
  static String requestLivePid(DiagnosticPid pid) => buildAsciiCommand(ObdMode.mode01_currentData, pid.code);

  /// Mode $02 Request: Read Freeze Frame PID
  static String requestFreezeFrame(DiagnosticPid pid, [int frameIndex = 0]) =>
      '02${pid.code}${frameIndex.toRadixString(16).padLeft(2, '0')}\r';

  /// Mode $03 Request: Read Confirmed DTCs
  static String requestConfirmedDtcs() => buildAsciiCommand(ObdMode.mode03_confirmedDtc);

  /// Mode $04 Request: Clear Diagnostic Trouble Codes
  ///
  /// IMPORTANT: Mode $04 must only be dispatched after safety checks confirm vehicle speed is 0.
  static String requestClearDtcs() => buildAsciiCommand(ObdMode.mode04_clearDtc);

  /// Mode $07 Request: Read Pending DTCs
  static String requestPendingDtcs() => buildAsciiCommand(ObdMode.mode07_pendingDtc);

  /// Mode $09 PID $02: Read VIN
  static String requestVin() => buildAsciiCommand(ObdMode.mode09_vehicleInfo, '02');

  /// Mode $09 PID $0A: Read ECU Name
  static String requestEcuName() => buildAsciiCommand(ObdMode.mode09_vehicleInfo, '0A');

  /// Mode $0A Request: Read Permanent DTCs
  static String requestPermanentDtcs() => buildAsciiCommand(ObdMode.mode0A_permanentDtc);

  // =========================================================================
  // Response Parsers
  // =========================================================================

  /// Parses an ELM327 ASCII response string into cleaned byte list.
  ///
  /// Strips headers, spaces, CR/LF, and prompt character '>'.
  static List<int> parseAsciiHexToBytes(String asciiResponse) {
    final cleaned = asciiResponse
        .replaceAll('>', '')
        .replaceAll('\r', '')
        .replaceAll('\n', '')
        .replaceAll(' ', '')
        .trim();

    if (cleaned.isEmpty || cleaned == 'NODATA' || cleaned == 'ERROR' || cleaned == '?') {
      return const [];
    }

    final bytes = <int>[];
    for (int i = 0; i + 1 < cleaned.length; i += 2) {
      final hexByte = cleaned.substring(i, i + 2);
      final byteVal = int.tryParse(hexByte, radix: 16);
      if (byteVal != null) {
        bytes.add(byteVal);
      }
    }
    return bytes;
  }

  /// Parses Mode $01 response bytes into a [DecodedPidMeasurement].
  static DecodedPidMeasurement? parseMode01Response(List<int> responseBytes, DiagnosticPid pid) {
    if (responseBytes.length < 2) return null;

    // Byte 0: Service Response (0x41)
    // Byte 1: PID
    // Byte 2+: Payload
    if (responseBytes[0] != ObdMode.mode01_currentData.responseServiceByte) return null;
    if (responseBytes[1] != pid.pid) return null;

    final payload = responseBytes.sublist(2);
    if (payload.length < pid.expectedBytes) return null;

    try {
      final value = pid.decode(payload);
      return DecodedPidMeasurement(
        pid: pid,
        value: value,
        unit: pid.unit,
        timestamp: DateTime.now(),
        isValid: true,
      );
    } catch (_) {
      return null;
    }
  }

  /// Parses Mode $03 / $07 / $0A DTC response bytes into a list of [DiagnosticFaultRecord].
  static List<DiagnosticFaultRecord> parseDtcResponse(
    List<int> responseBytes, {
    EcuModule module = EcuModule.engineControlModule_ECM,
    DtcSeverity severity = DtcSeverity.confirmedActive,
  }) {
    if (responseBytes.length < 2) return const [];

    // Byte 0: Service Response (0x43 for Mode 3, 0x47 for Mode 7, 0x4A for Mode 0A)
    // In ELM327 format, bytes are delivered in 2-byte pairs following the service header
    final dtcs = <DiagnosticFaultRecord>[];
    const startIndex = 1; // start after service response byte

    for (int i = startIndex; i + 1 < responseBytes.length; i += 2) {
      final byteA = responseBytes[i];
      final byteB = responseBytes[i + 1];

      // 0x00 0x00 indicates no more faults or empty slot
      if (byteA == 0x00 && byteB == 0x00) continue;

      final dtc = DiagnosticFaultRecord.fromRawBytes(
        byteA,
        byteB,
        module: module,
        severity: severity,
      );
      if (!dtcs.contains(dtc)) {
        dtcs.add(dtc);
      }
    }
    return dtcs;
  }

  /// Parses Mode $09 PID $02 response bytes into a 17-character VIN string.
  static String? parseVinResponse(List<int> responseBytes) {
    if (responseBytes.length < 3) return null;
    // Service byte 0x49, PID 0x02
    if (responseBytes[0] != 0x49 || responseBytes[1] != 0x02) return null;

    // Skip sequence numbers / block headers and take ASCII bytes
    final asciiBytes = responseBytes.sublist(2).where((b) => b >= 0x20 && b <= 0x7E).toList();
    if (asciiBytes.isEmpty) return null;

    final vin = utf8.decode(asciiBytes, allowMalformed: true).trim();
    return vin.length >= 17 ? vin.substring(vin.length - 17) : vin;
  }
}
