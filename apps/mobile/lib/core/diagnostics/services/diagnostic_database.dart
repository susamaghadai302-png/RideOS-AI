import '../models/diagnostic_types.dart';
import '../models/dtc_record.dart';

/// Standardized SAE J2012 / ISO 15031-6 Automotive & Motorcycle Fault Code Dictionary.
class DiagnosticDatabase {
  static final DiagnosticDatabase instance = DiagnosticDatabase._internal();
  factory DiagnosticDatabase() => instance;
  DiagnosticDatabase._internal();

  /// Enriches a raw [DiagnosticFaultRecord] with detailed titles, descriptions,
  /// causes, and repair actions from the knowledge base.
  DiagnosticFaultRecord lookup(
    String code, {
    EcuModule module = EcuModule.engineControlModule_ECM,
    DtcSeverity severity = DtcSeverity.confirmedActive,
    Map<String, dynamic> freezeFrame = const {},
  }) {
    final entry = _dtcDictionary[code.toUpperCase()];
    if (entry != null) {
      return DiagnosticFaultRecord(
        code: code.toUpperCase(),
        module: module,
        severity: entry.severityOverride ?? severity,
        category: _resolveCategory(code),
        title: entry.title,
        description: entry.description,
        probableCause: entry.probableCause,
        recommendedRemedy: entry.recommendedRemedy,
        freezeFrameSnapshot: freezeFrame,
        detectedAt: DateTime.now(),
        isMilLampTriggered: severity == DtcSeverity.confirmedActive ||
            severity == DtcSeverity.criticalStopEngine ||
            (entry.severityOverride == DtcSeverity.criticalStopEngine),
      );
    }

    // Generic fallback for uncataloged codes
    final cat = _resolveCategory(code);
    return DiagnosticFaultRecord(
      code: code.toUpperCase(),
      module: module,
      severity: severity,
      category: cat,
      title: '${cat.prefix}-Code $code (${cat.name.toUpperCase()})',
      description: 'Manufacturer / standard diagnostic trouble code reported by ${module.displayName}.',
      probableCause: 'Electrical circuit, component sensor, or physical actuator out of calibration limits.',
      recommendedRemedy: 'Perform visual inspection of harness, verify supply voltage, and check sensor impedance.',
      freezeFrameSnapshot: freezeFrame,
      detectedAt: DateTime.now(),
      isMilLampTriggered: severity == DtcSeverity.confirmedActive,
    );
  }

  static DtcSystemCategory _resolveCategory(String code) {
    if (code.isEmpty) return DtcSystemCategory.powertrain;
    final firstChar = code[0].toUpperCase();
    return switch (firstChar) {
      'P' => DtcSystemCategory.powertrain,
      'C' => DtcSystemCategory.chassis,
      'B' => DtcSystemCategory.body,
      'U' => DtcSystemCategory.network,
      _ => DtcSystemCategory.powertrain,
    };
  }

  static final Map<String, _DtcDefinition> _dtcDictionary = {
    // =========================================================================
    // POWERTRAIN — Fuel & Air Metering (P0100 - P0199)
    // =========================================================================
    'P0100': const _DtcDefinition(
      title: 'Mass or Volume Air Flow Circuit Malfunction',
      description: 'The MAF sensor voltage signal is out of expected operating range.',
      probableCause: 'Dirty MAF sensor element, intake air leak, or faulty wiring harness.',
      recommendedRemedy: 'Clean MAF element with dedicated cleaner; check intake ducting for unmetered air leaks.',
    ),
    'P0101': const _DtcDefinition(
      title: 'Mass Air Flow Sensor Circuit Range/Performance',
      description: 'MAF sensor signal does not correlate with calculated engine airflow.',
      probableCause: 'Clogged intake air filter, vacuum leak, or cracked airbox duct.',
      recommendedRemedy: 'Replace air filter, inspect vacuum lines with smoke tester.',
    ),
    'P0106': const _DtcDefinition(
      title: 'Manifold Absolute Pressure (MAP) Sensor Range/Performance',
      description: 'MAP sensor reading does not match expected atmospheric barometric baseline.',
      probableCause: 'Split vacuum hose to throttle body or contaminated MAP sensor port.',
      recommendedRemedy: 'Inspect vacuum hose to MAP sensor; clean carbon buildup from manifold port.',
    ),
    'P0110': const _DtcDefinition(
      title: 'Intake Air Temperature (IAT) Sensor Circuit Malfunction',
      description: 'IAT thermistor circuit voltage is either open or shorted to ground.',
      probableCause: 'Disconnected IAT sensor plug, damaged wire, or internal sensor failure.',
      recommendedRemedy: 'Check resistance across IAT sensor terminals (nominally 2.0k-2.5k ohms at 20°C).',
    ),
    'P0115': const _DtcDefinition(
      title: 'Engine Coolant Temperature (ECT) Circuit Malfunction',
      description: 'ECT sensor signal voltage indicates impossible temperature reading.',
      probableCause: 'Corroded ECT sensor connector, low coolant level, or failed sensor.',
      recommendedRemedy: 'Verify coolant level; test ECT sensor resistance across thermal operating curve.',
    ),
    'P0118': const _DtcDefinition(
      title: 'Engine Coolant Temperature Circuit High Input',
      description: 'ECT sensor circuit open, indicating -40°C temperature to ECM.',
      probableCause: 'Open circuit in ECT signal line or unplugged sensor.',
      recommendedRemedy: 'Check continuity of ECT wiring harness to ECM pin; replace faulty sensor.',
    ),
    'P0120': const _DtcDefinition(
      title: 'Throttle Position Sensor (TPS) Circuit Malfunction',
      description: 'TPS potentiometer voltage is erratic or outside standard 0.5V - 4.5V range.',
      probableCause: 'Worn TPS potentiometer track, loose mounting screw, or throttle cable tension.',
      recommendedRemedy: 'Check TPS voltage sweep on oscilloscope; calibrate zero-throttle baseline.',
    ),
    'P0130': const _DtcDefinition(
      title: 'O2 Sensor Circuit Malfunction (Bank 1 Sensor 1)',
      description: 'Lambda oxygen sensor circuit voltage is unresponsive.',
      probableCause: 'Exhaust leak before sensor, contaminated O2 sensor tip, or broken heater circuit.',
      recommendedRemedy: 'Inspect exhaust header joints for leaks; test O2 sensor heater resistance.',
    ),
    'P0171': const _DtcDefinition(
      title: 'Fuel Trim System Too Lean (Bank 1)',
      description: 'Long-Term Fuel Trim exceeds positive enrichment limit (> +25%).',
      probableCause: 'Intake air leak, clogged fuel injector, low fuel pressure, or fuel pump weakness.',
      recommendedRemedy: 'Perform fuel pressure delivery test; inspect intake manifold rubber boots for cracks.',
    ),
    'P0172': const _DtcDefinition(
      title: 'Fuel Trim System Too Rich (Bank 1)',
      description: 'Long-Term Fuel Trim exceeds negative leaning limit (< -25%).',
      probableCause: 'Leaking fuel injector, stuck fuel pressure regulator, or contaminated engine oil.',
      recommendedRemedy: 'Inspect spark plugs for fuel fouling; test injector flow balance and leakdown.',
    ),

    // =========================================================================
    // POWERTRAIN — Ignition & Misfire (P0300 - P0399)
    // =========================================================================
    'P0300': const _DtcDefinition(
      title: 'Random / Multiple Cylinder Misfire Detected',
      description: 'Crankshaft acceleration variations indicate irregular combustion in multiple cylinders.',
      probableCause: 'Fouled spark plugs, aged ignition coils, contaminated fuel, or low compression.',
      recommendedRemedy: 'Replace spark plugs; inspect ignition coil stick packs; verify fuel quality.',
      severityOverride: DtcSeverity.criticalStopEngine,
    ),
    'P0301': const _DtcDefinition(
      title: 'Cylinder 1 Misfire Detected',
      description: 'ECM detected combustion misfire on Cylinder 1.',
      probableCause: 'Cylinder 1 spark plug gap, ignition coil degradation, or injector blockage.',
      recommendedRemedy: 'Swap ignition coil to cylinder 2 to isolate fault; inspect spark plug #1.',
    ),
    'P0302': const _DtcDefinition(
      title: 'Cylinder 2 Misfire Detected',
      description: 'ECM detected combustion misfire on Cylinder 2.',
      probableCause: 'Cylinder 2 spark plug or ignition stick coil failure.',
      recommendedRemedy: 'Test coil resistance; replace spark plug #2.',
    ),
    'P0335': const _DtcDefinition(
      title: 'Crankshaft Position (CKP) Sensor "A" Circuit Malfunction',
      description: 'ECM lost synchronous timing pulses from the crankshaft reluctor wheel.',
      probableCause: 'Air gap deviation, metallic debris on magnetic pickup, or open harness.',
      recommendedRemedy: 'Clean CKP sensor pickup tip; verify air gap (typically 0.7mm - 1.2mm).',
      severityOverride: DtcSeverity.criticalStopEngine,
    ),
    'P0340': const _DtcDefinition(
      title: 'Camshaft Position (CMP) Sensor Circuit Malfunction',
      description: 'Camshaft phase signal missing during engine rotation.',
      probableCause: 'Damaged CMP sensor, timing chain/belt stretch, or loose reluctor pin.',
      recommendedRemedy: 'Verify valve timing marks; check CMP 5V reference supply and ground.',
    ),

    // =========================================================================
    // POWERTRAIN — Auxiliary & Transmission (P0500 - P0999)
    // =========================================================================
    'P0500': const _DtcDefinition(
      title: 'Vehicle Speed Sensor (VSS) Malfunction',
      description: 'ECM received erratic or missing road speed pulses.',
      probableCause: 'Failed countershaft speed sensor, ABS hub tone ring damage, or severed wire.',
      recommendedRemedy: 'Inspect tone ring teeth on wheel hub; verify speed sensor pulse signal.',
    ),
    'P0562': const _DtcDefinition(
      title: 'System Voltage Low',
      description: 'Battery / charging system voltage fell below 11.0V during engine operation.',
      probableCause: 'Failing stator / alternator, blown regulator/rectifier, or sulfated battery.',
      recommendedRemedy: 'Measure charging voltage at 3000 RPM (should be 14.2V - 14.6V); test stator AC output.',
    ),
    'P0563': const _DtcDefinition(
      title: 'System Voltage High',
      description: 'Charging voltage exceeded 15.5V, risking electronic module damage.',
      probableCause: 'Shorted voltage regulator/rectifier or loose ground terminal.',
      recommendedRemedy: 'Immediately replace voltage regulator/rectifier before riding.',
      severityOverride: DtcSeverity.criticalStopEngine,
    ),
    'P0700': const _DtcDefinition(
      title: 'Transmission Control System (MIL Request)',
      description: 'TCU requested MIL illumination due to internal transmission or quickshifter fault.',
      probableCause: 'Quickshifter load cell variance, gear position sensor misalignment, or clutch switch.',
      recommendedRemedy: 'Connect to TCU diagnostic module address 0x7E1 to extract sub-faults.',
    ),

    // =========================================================================
    // CHASSIS & BRAKES — ABS & IMU (C0000 - C0800)
    // =========================================================================
    'C0035': const _DtcDefinition(
      title: 'Left / Front Wheel Speed Circuit Malfunction',
      description: 'ABS control module detected missing pulses from front wheel speed sensor.',
      probableCause: 'Debris lodged in front ABS tone ring, bent sensor bracket, or open sensor coil.',
      recommendedRemedy: 'Clean front tone ring slots; inspect ABS sensor cable routing along front fork.',
    ),
    'C0040': const _DtcDefinition(
      title: 'Right / Rear Wheel Speed Circuit Malfunction',
      description: 'ABS control module detected missing pulses from rear wheel speed sensor.',
      probableCause: 'Rear ABS sensor air gap incorrect after chain adjustment or tire replacement.',
      recommendedRemedy: 'Adjust rear wheel alignment and check rear sensor air gap (0.5mm - 1.5mm).',
    ),
    'C0045': const _DtcDefinition(
      title: 'Brake Pressure Sensor Circuit Variance',
      description: 'ABS hydraulic pressure sensor reading differs from lever switch actuation.',
      probableCause: 'Air in ABS hydraulic unit, contaminated brake fluid, or faulty pressure transducer.',
      recommendedRemedy: 'Perform complete ABS diagnostic fluid bleed routine using service tool.',
    ),
    'C0128': const _DtcDefinition(
      title: '6-Axis IMU (Inertial Measurement Unit) Pitch/Roll Calibration Error',
      description: 'Traction control unit detected zero-point drift in 6-axis gyro/accelerometer.',
      probableCause: 'IMU mounting bracket loose, vehicle was moved during startup self-test.',
      recommendedRemedy: 'Park vehicle upright on level ground and execute IMU Static Zero-Calibration.',
    ),

    // =========================================================================
    // NETWORK & BUS COMMUNICATION (U0000 - U0400)
    // =========================================================================
    'U0100': const _DtcDefinition(
      title: 'Lost Communication With Engine Control Module (ECM)',
      description: 'CAN-bus heartbeat timeout from main ECM module (0x7E0).',
      probableCause: 'CAN-High or CAN-Low wire severed, main engine fuse blown, or ECM unpowered.',
      recommendedRemedy: 'Measure CAN bus terminating resistance across pins 6 & 14 (should be 60 ohms).',
      severityOverride: DtcSeverity.criticalStopEngine,
    ),
    'U0121': const _DtcDefinition(
      title: 'Lost Communication With Anti-Lock Brake System (ABS) Control Module',
      description: 'CAN communication loss with ABS unit (0x7E2).',
      probableCause: 'Blown ABS power fuse, damaged CAN bus branch harness, or ABS module internal failure.',
      recommendedRemedy: 'Check 20A/30A ABS main fuse; verify 12V power supply at ABS harness plug.',
    ),
    'U0129': const _DtcDefinition(
      title: 'Lost Communication With Brake System Control Module',
      description: 'Brake system master controller not responding on CAN bus.',
      probableCause: 'Electronic Combined Braking System (eCBS) module offline.',
      recommendedRemedy: 'Inspect eCBS module connector pins for corrosion or bent terminals.',
    ),
    'U0140': const _DtcDefinition(
      title: 'Lost Communication With Body Control Module (BCM)',
      description: 'CAN communication loss with lighting/security body controller (0x7E5).',
      probableCause: 'BCM power relay open or CAN transceiver failure.',
      recommendedRemedy: 'Check ignition relay output to BCM; inspect main grounding stud.',
    ),
    'U0155': const _DtcDefinition(
      title: 'Lost Communication With Instrument Panel Cluster (IPC)',
      description: 'CAN message timeout from digital TFT cockpit display (0x7E4).',
      probableCause: 'Cluster harness pinch near steering headstock or blown cluster fuse.',
      recommendedRemedy: 'Inspect wiring harness flexing around steering stem during full lock turns.',
    ),
  };
}

class _DtcDefinition {
  final String title;
  final String description;
  final String probableCause;
  final String recommendedRemedy;
  final DtcSeverity? severityOverride;

  const _DtcDefinition({
    required this.title,
    required this.description,
    required this.probableCause,
    required this.recommendedRemedy,
    this.severityOverride,
  });
}
