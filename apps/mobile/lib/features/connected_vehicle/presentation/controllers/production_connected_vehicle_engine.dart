import 'dart:async';
import 'dart:developer' as developer;

enum ObdProtocolStandard {
  iso157654Can,
  iso91412,
  kwp2000,
  saeJ1850Pwm,
  saeJ1850Vpw,
}

class TelemetryHardwareState {
  final double vehicleSpeedKmh;
  final double engineRpm;
  final double coolantTempCelsius;
  final double frontTyrePressurePsi;
  final double rearTyrePressurePsi;
  final double batteryVoltage;
  final bool isBleConnected;
  final bool isVirtualSimulationActive;

  const TelemetryHardwareState({
    required this.vehicleSpeedKmh,
    required this.engineRpm,
    required this.coolantTempCelsius,
    required this.frontTyrePressurePsi,
    required this.rearTyrePressurePsi,
    required this.batteryVoltage,
    required this.isBleConnected,
    required this.isVirtualSimulationActive,
  });
}

class ProductionConnectedVehicleEngine {
  static final ProductionConnectedVehicleEngine instance = ProductionConnectedVehicleEngine._internal();
  ProductionConnectedVehicleEngine._internal();

  final _hardwareTelemetryStreamController = StreamController<TelemetryHardwareState>.broadcast();

  Stream<TelemetryHardwareState> get hardwareTelemetryStream => _hardwareTelemetryStreamController.stream;

  void startHardwareScanAndStream({
    bool forceSimulation = true,
    ObdProtocolStandard protocol = ObdProtocolStandard.iso157654Can,
  }) {
    developer.log('Initializing Connected Vehicle HAL [Simulation: $forceSimulation, Protocol: $protocol]...', name: 'RideOS.ConnectedVehicleHAL');
    _hardwareTelemetryStreamController.add(
      TelemetryHardwareState(
        vehicleSpeedKmh: 74.2,
        engineRpm: 7800.0,
        coolantTempCelsius: 88.5,
        frontTyrePressurePsi: 36.0,
        rearTyrePressurePsi: 42.0,
        batteryVoltage: 14.1,
        isBleConnected: !forceSimulation,
        isVirtualSimulationActive: forceSimulation,
      ),
    );
  }

  void triggerEmergencySosCountdown({required String crashReason}) {
    developer.log('EMERGENCY CRASH DETECTED: [$crashReason]. Triggering 30s SOS Countdown...', name: 'RideOS.CrashSOS');
  }

  void dispose() {
    _hardwareTelemetryStreamController.close();
  }
}
