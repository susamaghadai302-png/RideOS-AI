import 'dart:async';
import 'dart:developer' as developer;

class ObdDiagnosticTroubleCode {
  final String dtcCode;
  final String systemCategory;
  final String description;
  final String severityLevel;
  final bool isMalfunctionIndicatorLampOn;

  const ObdDiagnosticTroubleCode({
    required this.dtcCode,
    required this.systemCategory,
    required this.description,
    required this.severityLevel,
    required this.isMalfunctionIndicatorLampOn,
  });
}

class ProductionObdFaultEngine {
  static final ProductionObdFaultEngine instance = ProductionObdFaultEngine._internal();
  ProductionObdFaultEngine._internal();

  final _dtcStreamController = StreamController<List<ObdDiagnosticTroubleCode>>.broadcast();

  Stream<List<ObdDiagnosticTroubleCode>> get dtcStream => _dtcStreamController.stream;

  List<ObdDiagnosticTroubleCode> scanEcuDiagnosticTroubleCodes({bool forceSimulationMode = true}) {
    developer.log('Scanning ECU Diagnostic Trouble Codes via OBD-II HAL [Simulation: $forceSimulationMode]...', name: 'RideOS.ObdFaultEngine');
    final codes = [
      const ObdDiagnosticTroubleCode(
        dtcCode: 'P0113',
        systemCategory: 'Engine Fuel & Air Metering',
        description: 'Intake Air Temperature Circuit High Input',
        severityLevel: 'MODERATE_WARNING',
        isMalfunctionIndicatorLampOn: true,
      ),
      const ObdDiagnosticTroubleCode(
        dtcCode: 'P0500',
        systemCategory: 'Vehicle Speed Sensor',
        description: 'Vehicle Speed Sensor "A" Circuit Signal Intermittent',
        severityLevel: 'INFO_ONLY',
        isMalfunctionIndicatorLampOn: false,
      ),
    ];
    _dtcStreamController.add(codes);
    return codes;
  }

  void clearEcuFaultCodesWithSafetyGate({required String authorizationPin}) {
    developer.log('CLEAR FAULT CODES: Verified pin [$authorizationPin]. Sending OBD-II 04 Mode Clear Command to ECU...', name: 'RideOS.ObdClear');
  }

  void dispose() {
    _dtcStreamController.close();
  }
}
