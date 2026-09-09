// ignore_for_file: constant_identifier_names

/// Supported Automotive & Motorcycle Diagnostic Protocols.
enum DiagnosticProtocol {
  iso15765_4_Can_11bit_500k,
  iso15765_4_Can_29bit_500k,
  iso15765_4_Can_11bit_250k,
  iso14229_1_UdsOverCan,
  iso14230_4_Kwp2000Fast,
  iso9141_2_KLine,
  saeJ1939_HeavyDuty,
  saeJ1850_Pwm,
  saeJ1850_Vpw,
  proprietaryYamahaCcu,
  proprietaryDucatiBbs;

  String get displayName {
    switch (this) {
      case DiagnosticProtocol.iso15765_4_Can_11bit_500k:
        return 'ISO 15765-4 (CAN 11-bit 500k)';
      case DiagnosticProtocol.iso15765_4_Can_29bit_500k:
        return 'ISO 15765-4 (CAN 29-bit 500k)';
      case DiagnosticProtocol.iso15765_4_Can_11bit_250k:
        return 'ISO 15765-4 (CAN 11-bit 250k)';
      case DiagnosticProtocol.iso14229_1_UdsOverCan:
        return 'ISO 14229-1 (UDS on CAN)';
      case DiagnosticProtocol.iso14230_4_Kwp2000Fast:
        return 'ISO 14230-4 (KWP2000 Fast)';
      case DiagnosticProtocol.iso9141_2_KLine:
        return 'ISO 9141-2 (K-Line)';
      case DiagnosticProtocol.saeJ1939_HeavyDuty:
        return 'SAE J1939 (Commercial CAN)';
      case DiagnosticProtocol.saeJ1850_Pwm:
        return 'SAE J1850 (PWM 41.6 kbps)';
      case DiagnosticProtocol.saeJ1850_Vpw:
        return 'SAE J1850 (VPW 10.4 kbps)';
      case DiagnosticProtocol.proprietaryYamahaCcu:
        return 'Yamaha CCU Telematics Bus';
      case DiagnosticProtocol.proprietaryDucatiBbs:
        return 'Ducati Black Box System (BBS)';
    }
  }

  bool get isCanBased =>
      this == DiagnosticProtocol.iso15765_4_Can_11bit_500k ||
      this == DiagnosticProtocol.iso15765_4_Can_29bit_500k ||
      this == DiagnosticProtocol.iso15765_4_Can_11bit_250k ||
      this == DiagnosticProtocol.iso14229_1_UdsOverCan ||
      this == DiagnosticProtocol.saeJ1939_HeavyDuty;
}

/// Target Electronic Control Units (ECUs) on the Vehicle Network.
enum EcuModule {
  engineControlModule_ECM,
  transmissionControlUnit_TCU,
  antiLockBraking_ABS,
  batteryManagementSystem_BMS,
  instrumentCluster_IPC,
  bodyControlModule_BCM,
  electronicSuspension_DES,
  tractionControl_IMU,
  telematicsBox_TCU;

  int get requestAddress {
    switch (this) {
      case EcuModule.engineControlModule_ECM:
        return 0x7E0;
      case EcuModule.transmissionControlUnit_TCU:
        return 0x7E1;
      case EcuModule.antiLockBraking_ABS:
        return 0x7E2;
      case EcuModule.batteryManagementSystem_BMS:
        return 0x7E3;
      case EcuModule.instrumentCluster_IPC:
        return 0x7E4;
      case EcuModule.bodyControlModule_BCM:
        return 0x7E5;
      case EcuModule.electronicSuspension_DES:
        return 0x7E6;
      case EcuModule.tractionControl_IMU:
        return 0x7E7;
      case EcuModule.telematicsBox_TCU:
        return 0x7E8;
    }
  }

  int get responseAddress => requestAddress + 8; // e.g. 0x7E0 -> 0x7E8

  String get hexAddress => '0x${requestAddress.toRadixString(16).toUpperCase()}';

  String get displayName {
    switch (this) {
      case EcuModule.engineControlModule_ECM:
        return 'Engine Control Module (ECM)';
      case EcuModule.transmissionControlUnit_TCU:
        return 'Transmission / Quickshifter (TCU)';
      case EcuModule.antiLockBraking_ABS:
        return 'Anti-Lock Braking System (ABS)';
      case EcuModule.batteryManagementSystem_BMS:
        return 'Battery Management (BMS)';
      case EcuModule.instrumentCluster_IPC:
        return 'Digital Cockpit / Cluster (IPC)';
      case EcuModule.bodyControlModule_BCM:
        return 'Body Control Module (BCM)';
      case EcuModule.electronicSuspension_DES:
        return 'Dynamic Electronic Suspension (DES)';
      case EcuModule.tractionControl_IMU:
        return '6-Axis IMU & Traction Unit';
      case EcuModule.telematicsBox_TCU:
        return 'Connected Telematics Hub (T-Box)';
    }
  }
}

/// Severity classification for Diagnostic Trouble Codes.
enum DtcSeverity {
  info,
  pending,
  confirmedActive,
  criticalStopEngine,
  permanentHistory;

  String get label {
    switch (this) {
      case DtcSeverity.info:
        return 'INFORMATIONAL';
      case DtcSeverity.pending:
        return 'PENDING';
      case DtcSeverity.confirmedActive:
        return 'CONFIRMED ACTIVE';
      case DtcSeverity.criticalStopEngine:
        return 'CRITICAL — STOP VEHICLE';
      case DtcSeverity.permanentHistory:
        return 'PERMANENT LOG';
    }
  }
}

/// Standardized Diagnostic Trouble Code Categories per SAE J2012.
enum DtcSystemCategory {
  powertrain, // P-codes
  chassis,    // C-codes
  body,       // B-codes
  network;    // U-codes

  String get prefix {
    switch (this) {
      case DtcSystemCategory.powertrain:
        return 'P';
      case DtcSystemCategory.chassis:
        return 'C';
      case DtcSystemCategory.body:
        return 'B';
      case DtcSystemCategory.network:
        return 'U';
    }
  }
}

/// SAE J1979 OBD-II Diagnostic Service Modes.
enum ObdMode {
  mode01_currentData(0x01, 'Current Powertrain Diagnostic Data'),
  mode02_freezeFrame(0x02, 'Powertrain Freeze Frame Data'),
  mode03_confirmedDtc(0x03, 'Emission-Related Confirmed DTCs'),
  mode04_clearDtc(0x04, 'Clear / Reset Emission Diagnostic Data'),
  mode06_onBoardMonitors(0x06, 'On-Board Diagnostic Monitor Test Results'),
  mode07_pendingDtc(0x07, 'Pending DTCs Detected During Current Driving Cycle'),
  mode09_vehicleInfo(0x09, 'Vehicle Information (VIN, CALID, CVN)'),
  mode0A_permanentDtc(0x0A, 'Permanent Diagnostic Trouble Codes');

  final int serviceByte;
  final String description;
  const ObdMode(this.serviceByte, this.description);

  int get responseServiceByte => serviceByte + 0x40; // e.g. 0x01 -> 0x41
}

/// ISO 14229-1 Unified Diagnostic Services (UDS).
enum UdsService {
  diagnosticSessionControl(0x10, 'Diagnostic Session Control'),
  ecuReset(0x11, 'ECU Reset'),
  clearDiagnosticInformation(0x14, 'Clear Diagnostic Information'),
  readDtcInformation(0x19, 'Read DTC Information'),
  readDataByIdentifier(0x22, 'Read Data By Identifier (DID)'),
  writeDataByIdentifier(0x2E, 'Write Data By Identifier (DID)'),
  securityAccess(0x27, 'Security Access'),
  routineControl(0x31, 'Routine Control'),
  testerPresent(0x3E, 'Tester Present Keep-Alive');

  final int serviceId;
  final String description;
  const UdsService(this.serviceId, this.description);

  int get positiveResponseId => serviceId + 0x40; // e.g. 0x22 -> 0x62
}

/// UDS Diagnostic Session Types.
enum UdsSessionType {
  defaultSession(0x01),
  programmingSession(0x02),
  extendedDiagnosticSession(0x03),
  safetySystemDiagnosticSession(0x04);

  final int typeByte;
  const UdsSessionType(this.typeByte);
}
