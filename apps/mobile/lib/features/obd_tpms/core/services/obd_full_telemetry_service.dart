import 'dart:async';

enum TelemetryDataSource {
  realHardwareBle,
  simulatorDemo,
  unconnectedOffline,
}

class ObdFullTelemetryData {
  final TelemetryDataSource source;
  final DateTime timestamp;
  final double? engineRpm;
  final double? coolantTempC;
  final double? batteryVoltage;
  final double? throttlePositionPct;
  final double? fuelLevelPct;
  final double? fuelConsumptionLitersPer100Km;
  final double? engineLoadPct;
  final double? oilTempC;
  final double? airIntakeTempC;
  final double? oxygenSensorVolts;
  final bool checkEngineLight;
  final List<String> dtcCodes;

  // TPMS
  final double? frontTirePsi;
  final double? rearTirePsi;
  final double? tireTempC;
  final bool lowPressureWarning;

  const ObdFullTelemetryData({
    required this.source,
    required this.timestamp,
    this.engineRpm,
    this.coolantTempC,
    this.batteryVoltage,
    this.throttlePositionPct,
    this.fuelLevelPct,
    this.fuelConsumptionLitersPer100Km,
    this.engineLoadPct,
    this.oilTempC,
    this.airIntakeTempC,
    this.oxygenSensorVolts,
    this.checkEngineLight = false,
    this.dtcCodes = const [],
    this.frontTirePsi,
    this.rearTirePsi,
    this.tireTempC,
    this.lowPressureWarning = false,
  });

  bool get isSimulated => source == TelemetryDataSource.simulatorDemo;

  bool isStale({Duration maxAge = const Duration(seconds: 3)}) {
    return DateTime.now().difference(timestamp) > maxAge;
  }

  String getDisplayValue(double? val, String unit, {String fallback = 'Not available from vehicle'}) {
    if (val == null) return fallback;
    return '${val.toStringAsFixed(1)} $unit';
  }
}

class ObdFullTelemetryService {
  static final ObdFullTelemetryService _instance = ObdFullTelemetryService._internal();
  factory ObdFullTelemetryService() => _instance;
  ObdFullTelemetryService._internal();

  final _controller = StreamController<ObdFullTelemetryData>.broadcast();
  Stream<ObdFullTelemetryData> get telemetryStream => _controller.stream;

  bool isSimulatorMode = false;
  ObdFullTelemetryData? _latestTelemetry;

  ObdFullTelemetryData getLatestTelemetry() {
    if (_latestTelemetry != null) return _latestTelemetry!;

    if (isSimulatorMode) {
      return ObdFullTelemetryData(
        source: TelemetryDataSource.simulatorDemo,
        timestamp: DateTime.now(),
        engineRpm: 4850,
        coolantTempC: 88.5,
        batteryVoltage: 13.8,
        throttlePositionPct: 42.0,
        fuelLevelPct: 78.0,
        fuelConsumptionLitersPer100Km: 4.8,
        engineLoadPct: 56.0,
        oilTempC: 92.0,
        airIntakeTempC: 24.5,
        oxygenSensorVolts: 0.85,
        checkEngineLight: false,
        dtcCodes: const [],
        frontTirePsi: 36.0,
        rearTirePsi: 42.0,
        tireTempC: 32.0,
        lowPressureWarning: false,
      );
    }

    return ObdFullTelemetryData(
      source: TelemetryDataSource.unconnectedOffline,
      timestamp: DateTime.now(),
    );
  }

  void updateTelemetry(ObdFullTelemetryData data) {
    _latestTelemetry = data;
    if (!_controller.isClosed) {
      _controller.add(data);
    }
  }

  void startStreaming() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_controller.isClosed) {
        timer.cancel();
        return;
      }
      _controller.add(getLatestTelemetry());
    });
  }

  void dispose() {
    _controller.close();
  }
}
