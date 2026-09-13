import 'dart:async';
import '../models/normalized_telemetry_models.dart';
import '../models/field_bench_models.dart';
import 'fleet_telematics_engine.dart';

class PhysicalFieldBenchService {
  static final PhysicalFieldBenchService _instance = PhysicalFieldBenchService._internal();
  factory PhysicalFieldBenchService() => _instance;

  final _telematicsEngine = FleetTelematicsEngine();

  StreamSubscription? _telemetrySub;

  int _packetsInCurrentWindow = 0;
  double _currentPacketRateHz = 10.0;
  final double _packetLossPct = 0.0;
  int _reconnectCount = 0;
  DateTime _lastPacketTime = DateTime.now();

  Timer? _rateCalculatorTimer;

  final _linkHealthController = StreamController<FieldLinkHealthSnapshot>.broadcast();
  Stream<FieldLinkHealthSnapshot> get linkHealthStream => _linkHealthController.stream;

  FieldLinkHealthSnapshot? _latestHealthSnapshot;
  FieldLinkHealthSnapshot? get latestHealthSnapshot => _latestHealthSnapshot;

  // Active Field Session Recording
  bool _isRideSessionActive = false;
  bool get isRideSessionActive => _isRideSessionActive;

  DateTime? _rideStartTime;
  final List<NormalizedTelemetrySnapshot> _rideTelemetryBuffer = [];
  final List<DiagnosticTroubleCode> _detectedDtcs = [];
  int _connectionDropsDuringRide = 0;

  PhysicalFieldBenchService._internal() {
    _startLinkHealthMonitor();
  }

  void startLiveRideSession() {
    _isRideSessionActive = true;
    _rideStartTime = DateTime.now();
    _rideTelemetryBuffer.clear();
    _detectedDtcs.clear();
    _connectionDropsDuringRide = 0;
    _telematicsEngine.startRecordingSession();
  }

  RecordedRideSession stopLiveRideSession() {
    _isRideSessionActive = false;
    _telematicsEngine.stopRecordingSession();

    final now = DateTime.now();
    final startTime = _rideStartTime ?? now.subtract(const Duration(minutes: 1));
    final durationMins = now.difference(startTime).inSeconds / 60.0;

    double maxSpeed = 0.0;
    double speedSum = 0.0;
    int maxRpm = 0;
    int rpmSum = 0;
    double maxLean = 0.0;
    double minVolt = 12.6;
    double maxVolt = 14.2;

    for (final s in _rideTelemetryBuffer) {
      final spd = s.vehicleSpeedKmh.value ?? 0.0;
      if (spd > maxSpeed) maxSpeed = spd;
      speedSum += spd;

      final r = s.engineRpm.value ?? 0;
      if (r > maxRpm) maxRpm = r;
      rpmSum += r;

      final l = (s.leanAngleDeg.value ?? 0.0).abs();
      if (l > maxLean) maxLean = l;

      final v = s.batteryVoltage.value ?? 12.6;
      if (v < minVolt) minVolt = v;
      if (v > maxVolt) maxVolt = v;
    }

    final count = _rideTelemetryBuffer.length;
    final avgSpeed = count > 0 ? (speedSum / count) : 0.0;
    final avgRpm = count > 0 ? (rpmSum ~/ count) : 0;
    final distanceKm = (avgSpeed * (durationMins / 60.0));

    return RecordedRideSession(
      sessionId: 'field_sess_${DateTime.now().millisecondsSinceEpoch}',
      startTime: startTime,
      endTime: now,
      totalDistanceKm: distanceKm,
      durationMinutes: durationMins,
      maxSpeedKmh: maxSpeed,
      averageSpeedKmh: avgSpeed,
      maxRpm: maxRpm,
      averageRpm: avgRpm,
      maxLeanAngleDeg: maxLean,
      batteryMinVoltage: minVolt,
      batteryMaxVoltage: maxVolt,
      totalPacketsReceived: count,
      averagePacketLossPct: _packetLossPct,
      connectionInterruptions: _connectionDropsDuringRide,
      detectedDtcs: List.unmodifiable(_detectedDtcs),
      dataSource: _telematicsEngine.activeProvider?.dataSourceClassification ?? TelemetryDataSource.simulated,
    );
  }

  void recordConnectionDrop() {
    _reconnectCount++;
    if (_isRideSessionActive) {
      _connectionDropsDuringRide++;
    }
  }

  void _startLinkHealthMonitor() {
    _rateCalculatorTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _currentPacketRateHz = _packetsInCurrentWindow.toDouble();
      _packetsInCurrentWindow = 0;

      final freshness = DateTime.now().difference(_lastPacketTime).inMilliseconds / 1000.0;
      final qualityScore = _calculateQualityScore(_currentPacketRateHz, _packetLossPct, freshness);

      _latestHealthSnapshot = FieldLinkHealthSnapshot(
        packetRateHz: _currentPacketRateHz,
        packetLossPercentage: _packetLossPct,
        latencyMs: (_currentPacketRateHz > 0 ? (1000 / _currentPacketRateHz).round() : 999),
        reconnectCount: _reconnectCount,
        sensorFreshnessSeconds: freshness,
        dataQualityScore: qualityScore,
        source: _telematicsEngine.activeProvider?.dataSourceClassification ?? TelemetryDataSource.simulated,
        rssi: _telematicsEngine.latestSnapshot?.rssi ?? -60,
      );

      if (!_linkHealthController.isClosed) {
        _linkHealthController.add(_latestHealthSnapshot!);
      }
    });

    _telemetrySub = _telematicsEngine.telemetryStream.listen((snapshot) {
      _packetsInCurrentWindow++;
      _lastPacketTime = DateTime.now();

      if (_isRideSessionActive) {
        _rideTelemetryBuffer.add(snapshot);
      }
    });
  }

  int _calculateQualityScore(double hz, double lossPct, double freshness) {
    if (freshness > 3.0) return 10;
    int score = 100;
    if (hz < 5.0) score -= 20;
    score -= (lossPct * 4).round();
    if (freshness > 1.0) score -= 15;
    return score.clamp(0, 100);
  }

  Future<void> dispose() async {
    _rateCalculatorTimer?.cancel();
    _telemetrySub?.cancel();
    await _linkHealthController.close();
  }
}
