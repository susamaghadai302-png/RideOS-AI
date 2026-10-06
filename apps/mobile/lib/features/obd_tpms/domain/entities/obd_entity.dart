import 'package:equatable/equatable.dart';

class ObdSensorEntity extends Equatable {
  final double rpm;
  final double speedKmh;
  final double engineLoadPct;
  final double coolantTempC;
  final double intakeAirTempC;
  final double throttlePct;
  final double fuelLevelPct;
  final double batteryVoltage;
  final List<String> diagnosticCodes;

  // TPMS
  final double frontTirePsi;
  final double rearTirePsi;
  final double frontTireTempC;
  final double rearTireTempC;

  final bool isTpmsWarning;
  final String? tpmsMessage;

  const ObdSensorEntity({
    required this.rpm,
    this.speedKmh = 68.0,
    this.engineLoadPct = 0.0,
    required this.coolantTempC,
    this.intakeAirTempC = 28.0,
    required this.throttlePct,
    this.fuelLevelPct = 78.0,
    required this.batteryVoltage,
    required this.diagnosticCodes,
    required this.frontTirePsi,
    required this.rearTirePsi,
    this.frontTireTempC = 35.0,
    this.rearTireTempC = 38.0,
    this.isTpmsWarning = false,
    this.tpmsMessage,
  });

  // Alias for backward compatibility
  double get engineTempC => coolantTempC;

  bool get isLowPressureWarning => frontTirePsi < 32.0 || rearTirePsi < 32.0;
  bool get isHighPressureWarning => frontTirePsi > 42.0 || rearTirePsi > 42.0;
  bool get isHighTempWarning => frontTireTempC > 70.0 || rearTireTempC > 70.0;

  @override
  List<Object?> get props => [
        rpm,
        speedKmh,
        engineLoadPct,
        coolantTempC,
        intakeAirTempC,
        throttlePct,
        fuelLevelPct,
        batteryVoltage,
        diagnosticCodes,
        frontTirePsi,
        rearTirePsi,
        frontTireTempC,
        rearTireTempC,
        isTpmsWarning,
        tpmsMessage,
      ];
}
