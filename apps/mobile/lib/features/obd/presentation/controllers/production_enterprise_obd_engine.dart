import 'dart:async';
import 'dart:developer' as developer;

enum ObdConnectionType {
  bluetoothLe,
  wifiSocket,
  usbSerial,
  canBusRaw,
}

enum ObdProtocolType {
  iso157654Can,
  iso91412,
  iso14230Kwp2000,
  saeJ1850Pwm,
  saeJ1850Vpw,
}

class ObdLiveMetrics {
  final int engineRpm;
  final double vehicleSpeedKmh;
  final double throttlePositionPct;
  final double coolantTempCelsius;
  final double batteryVoltage;
  final double engineLoadPct;

  const ObdLiveMetrics({
    required this.engineRpm,
    required this.vehicleSpeedKmh,
    required this.throttlePositionPct,
    required this.coolantTempCelsius,
    required this.batteryVoltage,
    required this.engineLoadPct,
  });
}

abstract class IObdHardwareAdapter {
  ObdConnectionType get connectionType;
  Future<bool> connectAdapter({required String deviceId});
  Stream<ObdLiveMetrics> streamTelemetryPids();
  Future<void> disconnect();
}


class ProductionEnterpriseObdEngine {
  static final ProductionEnterpriseObdEngine instance = ProductionEnterpriseObdEngine._internal();
  ProductionEnterpriseObdEngine._internal();



  ObdConnectionType activeConnectionType = ObdConnectionType.bluetoothLe;
  ObdProtocolType detectedProtocol = ObdProtocolType.iso157654Can;

  Stream<ObdLiveMetrics> startHighFrequencyPidStream({String deviceId = 'OBD_BLE_9942'}) async* {
    developer.log('Initiating High-Frequency PID Stream via [$activeConnectionType / $detectedProtocol]...', name: 'RideOS.ObdHAL');
    throw Exception('OBD hardware not connected/available');
  }

  Map<String, dynamic> evaluateVehicleHealthDiagnostics() {
    return {
      'health_score': null,
      'status': 'UNKNOWN',
      'dtc_count': 0,
      'battery_health': 'UNKNOWN',
      'maintenance_recommended': 'Not available',
    };
  }
}
