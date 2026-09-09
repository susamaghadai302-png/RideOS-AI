import 'package:flutter/foundation.dart';

/// Standard SAE J1979 OBD-II Parameter Identification (PID) definition.
@immutable
class DiagnosticPid {
  final int pid; // 1-byte hex PID (e.g. 0x0C for Engine RPM)
  final String code; // e.g. "0C"
  final String name;
  final String category;
  final String unit;
  final int expectedBytes;
  final double minValidValue;
  final double maxValidValue;
  final double Function(List<int> bytes) decoder;

  const DiagnosticPid({
    required this.pid,
    required this.code,
    required this.name,
    required this.category,
    required this.unit,
    required this.expectedBytes,
    required this.minValidValue,
    required this.maxValidValue,
    required this.decoder,
  });

  /// Decodes raw PID payload bytes into a numeric engineering value.
  double decode(List<int> payload) {
    if (payload.length < expectedBytes) {
      throw ArgumentError(
        'PID 0x$code requires $expectedBytes bytes, but received ${payload.length}',
      );
    }
    return decoder(payload);
  }

  // =========================================================================
  // Standard OBD-II Mode $01 PID Registry
  // =========================================================================

  /// PID 0x04: Calculated Engine Load Value (%)
  static final engineLoad = DiagnosticPid(
    pid: 0x04,
    code: '04',
    name: 'Calculated Engine Load',
    category: 'Powertrain',
    unit: '%',
    expectedBytes: 1,
    minValidValue: 0.0,
    maxValidValue: 100.0,
    decoder: (bytes) => (bytes[0] * 100.0) / 255.0,
  );

  /// PID 0x05: Engine Coolant Temperature (°C)
  static final coolantTemperature = DiagnosticPid(
    pid: 0x05,
    code: '05',
    name: 'Engine Coolant Temperature',
    category: 'Thermal',
    unit: '°C',
    expectedBytes: 1,
    minValidValue: -40.0,
    maxValidValue: 215.0,
    decoder: (bytes) => bytes[0] - 40.0,
  );

  /// PID 0x0B: Intake Manifold Absolute Pressure (kPa)
  static final intakeManifoldPressure = DiagnosticPid(
    pid: 0x0B,
    code: '0B',
    name: 'Intake Manifold Pressure',
    category: 'Airflow',
    unit: 'kPa',
    expectedBytes: 1,
    minValidValue: 0.0,
    maxValidValue: 255.0,
    decoder: (bytes) => bytes[0].toDouble(),
  );

  /// PID 0x0C: Engine Speed / RPM (rpm)
  /// Formula: ((A * 256) + B) / 4
  static final engineRpm = DiagnosticPid(
    pid: 0x0C,
    code: '0C',
    name: 'Engine Speed',
    category: 'Powertrain',
    unit: 'RPM',
    expectedBytes: 2,
    minValidValue: 0.0,
    maxValidValue: 16383.75,
    decoder: (bytes) => ((bytes[0] * 256.0) + bytes[1]) / 4.0,
  );

  /// PID 0x0D: Vehicle Speed (km/h)
  static final vehicleSpeed = DiagnosticPid(
    pid: 0x0D,
    code: '0D',
    name: 'Vehicle Speed',
    category: 'Dynamics',
    unit: 'km/h',
    expectedBytes: 1,
    minValidValue: 0.0,
    maxValidValue: 255.0,
    decoder: (bytes) => bytes[0].toDouble(),
  );

  /// PID 0x0F: Intake Air Temperature (°C)
  static final intakeAirTemperature = DiagnosticPid(
    pid: 0x0F,
    code: '0F',
    name: 'Intake Air Temperature',
    category: 'Thermal',
    unit: '°C',
    expectedBytes: 1,
    minValidValue: -40.0,
    maxValidValue: 215.0,
    decoder: (bytes) => bytes[0] - 40.0,
  );

  /// PID 0x10: Mass Air Flow (MAF) Sensor Rate (g/s)
  /// Formula: ((A * 256) + B) / 100
  static final massAirFlow = DiagnosticPid(
    pid: 0x10,
    code: '10',
    name: 'Mass Air Flow (MAF)',
    category: 'Airflow',
    unit: 'g/s',
    expectedBytes: 2,
    minValidValue: 0.0,
    maxValidValue: 655.35,
    decoder: (bytes) => ((bytes[0] * 256.0) + bytes[1]) / 100.0,
  );

  /// PID 0x11: Throttle Position (%)
  static final throttlePosition = DiagnosticPid(
    pid: 0x11,
    code: '11',
    name: 'Throttle Position',
    category: 'Powertrain',
    unit: '%',
    expectedBytes: 1,
    minValidValue: 0.0,
    maxValidValue: 100.0,
    decoder: (bytes) => (bytes[0] * 100.0) / 255.0,
  );

  /// PID 0x2F: Fuel Tank Level Input (%)
  static final fuelTankLevel = DiagnosticPid(
    pid: 0x2F,
    code: '2F',
    name: 'Fuel Level Input',
    category: 'Fuel',
    unit: '%',
    expectedBytes: 1,
    minValidValue: 0.0,
    maxValidValue: 100.0,
    decoder: (bytes) => (bytes[0] * 100.0) / 255.0,
  );

  /// PID 0x42: Control Module / Battery Voltage (V)
  /// Formula: ((A * 256) + B) / 1000
  static final controlModuleVoltage = DiagnosticPid(
    pid: 0x42,
    code: '42',
    name: 'Control Module Voltage',
    category: 'Electrical',
    unit: 'V',
    expectedBytes: 2,
    minValidValue: 0.0,
    maxValidValue: 65.535,
    decoder: (bytes) => ((bytes[0] * 256.0) + bytes[1]) / 1000.0,
  );

  /// PID 0x5C: Engine Oil Temperature (°C)
  static final engineOilTemperature = DiagnosticPid(
    pid: 0x5C,
    code: '5C',
    name: 'Engine Oil Temperature',
    category: 'Thermal',
    unit: '°C',
    expectedBytes: 1,
    minValidValue: -40.0,
    maxValidValue: 215.0,
    decoder: (bytes) => bytes[0] - 40.0,
  );

  /// All standard registered Mode $01 PIDs.
  static final List<DiagnosticPid> standardPids = [
    engineLoad,
    coolantTemperature,
    intakeManifoldPressure,
    engineRpm,
    vehicleSpeed,
    intakeAirTemperature,
    massAirFlow,
    throttlePosition,
    fuelTankLevel,
    controlModuleVoltage,
    engineOilTemperature,
  ];

  static final Map<int, DiagnosticPid> pidMap = {
    for (final p in standardPids) p.pid: p,
  };
}

/// Decoded live PID measurement with metadata.
@immutable
class DecodedPidMeasurement {
  final DiagnosticPid pid;
  final double value;
  final String unit;
  final DateTime timestamp;
  final bool isValid;

  const DecodedPidMeasurement({
    required this.pid,
    required this.value,
    required this.unit,
    required this.timestamp,
    this.isValid = true,
  });

  Map<String, dynamic> toJson() => {
        'pidCode': pid.code,
        'name': pid.name,
        'value': value,
        'unit': unit,
        'timestamp': timestamp.toIso8601String(),
        'isValid': isValid,
      };

  @override
  String toString() => '${pid.name}: ${value.toStringAsFixed(1)} $unit';
}
