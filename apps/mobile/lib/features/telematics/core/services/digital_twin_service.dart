import 'dart:async';

class DigitalTwinStateData {
  final String bikeModel;
  final double engineHealthScore;
  final double batteryPct;
  final double fuelPct;
  final double frontTirePsi;
  final double rearTirePsi;
  final double oilLifePct;
  final double brakePadLifePct;
  final bool isEngineActive;
  final List<String> activeSensors;

  const DigitalTwinStateData({
    required this.bikeModel,
    required this.engineHealthScore,
    required this.batteryPct,
    required this.fuelPct,
    required this.frontTirePsi,
    required this.rearTirePsi,
    required this.oilLifePct,
    required this.brakePadLifePct,
    required this.isEngineActive,
    required this.activeSensors,
  });
}

class DigitalTwinService {
  final _twinController = StreamController<DigitalTwinStateData>.broadcast();

  Stream<DigitalTwinStateData> get twinStateStream => _twinController.stream;

  DigitalTwinStateData getTwinState() {
    return const DigitalTwinStateData(
      bikeModel: 'Ducati Panigale V4 R Digital Twin',
      engineHealthScore: 98.4,
      batteryPct: 94.0,
      fuelPct: 78.0,
      frontTirePsi: 36.0,
      rearTirePsi: 42.0,
      oilLifePct: 88.0,
      brakePadLifePct: 82.0,
      isEngineActive: true,
      activeSensors: ['6-Axis IMU', 'CAN-BUS OBD-II', 'BLE TPMS', 'GPS Satellite', 'AI Camera'],
    );
  }

  void startStreaming() {
    Timer.periodic(const Duration(seconds: 2), (t) {
      if (_twinController.isClosed) {
        t.cancel();
        return;
      }
      _twinController.add(getTwinState());
    });
  }

  void dispose() {
    _twinController.close();
  }
}
