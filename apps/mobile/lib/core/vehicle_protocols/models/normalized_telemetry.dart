import 'telemetry_value.dart';

class NormalizedTelemetry {
  final TelemetryValue<double> speed; // km/h
  final TelemetryValue<int> rpm;
  final TelemetryValue<int> engineTemperature; // Celsius
  final TelemetryValue<int> coolantTemperature; // Celsius
  final TelemetryValue<int> ambientTemperature; // Celsius
  final TelemetryValue<int> batteryPercentage; // 0-100%
  final TelemetryValue<double> batteryVoltage; // Volts
  final TelemetryValue<int> fuelLevel; // 0-100%
  final TelemetryValue<double> throttlePosition; // 0-100%
  final TelemetryValue<double> odometer; // km
  final TelemetryValue<double> tripDistance; // km
  final TelemetryValue<int> gear; // 0 = Neutral, 1-6
  
  // Dynamics & Inertial IMU
  final TelemetryValue<double> leanAngle; // Degrees (-60 to +60)
  final TelemetryValue<double> pitch; // Degrees
  final TelemetryValue<double> roll; // Degrees
  final TelemetryValue<double> heading; // Degrees (0-360)
  final TelemetryValue<double> wheelSpeed; // km/h

  // States & Actuators
  final TelemetryValue<String> engineState; // OFF, IDLE, RUNNING
  final TelemetryValue<String> ignitionState; // OFF, ACC, ON
  final TelemetryValue<bool> brakeState; 
  final TelemetryValue<bool> indicatorLeft;
  final TelemetryValue<bool> indicatorRight;
  final TelemetryValue<bool> headlight;
  final TelemetryValue<bool> abs; // ABS engaged or status
  final TelemetryValue<int> tractionControl; // TC Level
  final TelemetryValue<String> ridingMode; // e.g., SPORT, TOURING, RAIN, ECO
  final TelemetryValue<String> chargingState; // DISCHARGING, CHARGING, FULL
  final TelemetryValue<String> gps; // Lat,Lng string
  final TelemetryValue<double> deviceVoltage; // Phone/Device battery voltage
  final TelemetryValue<List<String>> faultCodes;
  final TelemetryValue<int> connectionQuality; // 0-100 signal strength

  NormalizedTelemetry({
    required this.speed,
    required this.rpm,
    required this.engineTemperature,
    required this.coolantTemperature,
    required this.ambientTemperature,
    required this.batteryPercentage,
    required this.batteryVoltage,
    required this.fuelLevel,
    required this.throttlePosition,
    required this.odometer,
    required this.tripDistance,
    required this.gear,
    required this.leanAngle,
    required this.pitch,
    required this.roll,
    required this.heading,
    required this.wheelSpeed,
    required this.engineState,
    required this.ignitionState,
    required this.brakeState,
    required this.indicatorLeft,
    required this.indicatorRight,
    required this.headlight,
    required this.abs,
    required this.tractionControl,
    required this.ridingMode,
    required this.chargingState,
    required this.gps,
    required this.deviceVoltage,
    required this.faultCodes,
    required this.connectionQuality,
  });

  factory NormalizedTelemetry.empty() {
    return NormalizedTelemetry(
      speed: TelemetryValue.unavailable(),
      rpm: TelemetryValue.unavailable(),
      engineTemperature: TelemetryValue.unavailable(),
      coolantTemperature: TelemetryValue.unavailable(),
      ambientTemperature: TelemetryValue.unavailable(),
      batteryPercentage: TelemetryValue.unavailable(),
      batteryVoltage: TelemetryValue.unavailable(),
      fuelLevel: TelemetryValue.unavailable(),
      throttlePosition: TelemetryValue.unavailable(),
      odometer: TelemetryValue.unavailable(),
      tripDistance: TelemetryValue.unavailable(),
      gear: TelemetryValue.unavailable(),
      leanAngle: TelemetryValue.unavailable(),
      pitch: TelemetryValue.unavailable(),
      roll: TelemetryValue.unavailable(),
      heading: TelemetryValue.unavailable(),
      wheelSpeed: TelemetryValue.unavailable(),
      engineState: TelemetryValue.unavailable(),
      ignitionState: TelemetryValue.unavailable(),
      brakeState: TelemetryValue.unavailable(),
      indicatorLeft: TelemetryValue.unavailable(),
      indicatorRight: TelemetryValue.unavailable(),
      headlight: TelemetryValue.unavailable(),
      abs: TelemetryValue.unavailable(),
      tractionControl: TelemetryValue.unavailable(),
      ridingMode: TelemetryValue.unavailable(),
      chargingState: TelemetryValue.unavailable(),
      gps: TelemetryValue.unavailable(),
      deviceVoltage: TelemetryValue.unavailable(),
      faultCodes: TelemetryValue.unavailable(),
      connectionQuality: TelemetryValue.unavailable(),
    );
  }

  NormalizedTelemetry copyWith({
    TelemetryValue<double>? speed,
    TelemetryValue<int>? rpm,
    TelemetryValue<int>? engineTemperature,
    TelemetryValue<int>? coolantTemperature,
    TelemetryValue<int>? ambientTemperature,
    TelemetryValue<int>? batteryPercentage,
    TelemetryValue<double>? batteryVoltage,
    TelemetryValue<int>? fuelLevel,
    TelemetryValue<double>? throttlePosition,
    TelemetryValue<double>? odometer,
    TelemetryValue<double>? tripDistance,
    TelemetryValue<int>? gear,
    TelemetryValue<double>? leanAngle,
    TelemetryValue<double>? pitch,
    TelemetryValue<double>? roll,
    TelemetryValue<double>? heading,
    TelemetryValue<double>? wheelSpeed,
    TelemetryValue<String>? engineState,
    TelemetryValue<String>? ignitionState,
    TelemetryValue<bool>? brakeState,
    TelemetryValue<bool>? indicatorLeft,
    TelemetryValue<bool>? indicatorRight,
    TelemetryValue<bool>? headlight,
    TelemetryValue<bool>? abs,
    TelemetryValue<int>? tractionControl,
    TelemetryValue<String>? ridingMode,
    TelemetryValue<String>? chargingState,
    TelemetryValue<String>? gps,
    TelemetryValue<double>? deviceVoltage,
    TelemetryValue<List<String>>? faultCodes,
    TelemetryValue<int>? connectionQuality,
  }) {
    return NormalizedTelemetry(
      speed: speed ?? this.speed,
      rpm: rpm ?? this.rpm,
      engineTemperature: engineTemperature ?? this.engineTemperature,
      coolantTemperature: coolantTemperature ?? this.coolantTemperature,
      ambientTemperature: ambientTemperature ?? this.ambientTemperature,
      batteryPercentage: batteryPercentage ?? this.batteryPercentage,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      throttlePosition: throttlePosition ?? this.throttlePosition,
      odometer: odometer ?? this.odometer,
      tripDistance: tripDistance ?? this.tripDistance,
      gear: gear ?? this.gear,
      leanAngle: leanAngle ?? this.leanAngle,
      pitch: pitch ?? this.pitch,
      roll: roll ?? this.roll,
      heading: heading ?? this.heading,
      wheelSpeed: wheelSpeed ?? this.wheelSpeed,
      engineState: engineState ?? this.engineState,
      ignitionState: ignitionState ?? this.ignitionState,
      brakeState: brakeState ?? this.brakeState,
      indicatorLeft: indicatorLeft ?? this.indicatorLeft,
      indicatorRight: indicatorRight ?? this.indicatorRight,
      headlight: headlight ?? this.headlight,
      abs: abs ?? this.abs,
      tractionControl: tractionControl ?? this.tractionControl,
      ridingMode: ridingMode ?? this.ridingMode,
      chargingState: chargingState ?? this.chargingState,
      gps: gps ?? this.gps,
      deviceVoltage: deviceVoltage ?? this.deviceVoltage,
      faultCodes: faultCodes ?? this.faultCodes,
      connectionQuality: connectionQuality ?? this.connectionQuality,
    );
  }

  Map<String, dynamic> toJson() => {
        'speed': speed.toJson(),
        'rpm': rpm.toJson(),
        'engineTemperature': engineTemperature.toJson(),
        'coolantTemperature': coolantTemperature.toJson(),
        'ambientTemperature': ambientTemperature.toJson(),
        'batteryPercentage': batteryPercentage.toJson(),
        'batteryVoltage': batteryVoltage.toJson(),
        'fuelLevel': fuelLevel.toJson(),
        'throttlePosition': throttlePosition.toJson(),
        'odometer': odometer.toJson(),
        'tripDistance': tripDistance.toJson(),
        'gear': gear.toJson(),
        'leanAngle': leanAngle.toJson(),
        'pitch': pitch.toJson(),
        'roll': roll.toJson(),
        'heading': heading.toJson(),
        'wheelSpeed': wheelSpeed.toJson(),
        'engineState': engineState.toJson(),
        'ignitionState': ignitionState.toJson(),
        'brakeState': brakeState.toJson(),
        'indicatorLeft': indicatorLeft.toJson(),
        'indicatorRight': indicatorRight.toJson(),
        'headlight': headlight.toJson(),
        'abs': abs.toJson(),
        'tractionControl': tractionControl.toJson(),
        'ridingMode': ridingMode.toJson(),
        'chargingState': chargingState.toJson(),
        'gps': gps.toJson(),
        'deviceVoltage': deviceVoltage.toJson(),
        'faultCodes': faultCodes.toJson(),
        'connectionQuality': connectionQuality.toJson(),
      };
}
