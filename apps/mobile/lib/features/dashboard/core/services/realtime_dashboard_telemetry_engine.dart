import 'dart:async';
import '../../domain/models/advanced_dashboard_models.dart';
import '../../../../core/device_providers/services/fleet_telematics_engine.dart';
import '../../../../core/device_providers/models/normalized_telemetry_models.dart';
import '../../../../core/device_providers/interfaces/device_provider.dart';

class RealtimeDashboardTelemetryEngine {
  static final RealtimeDashboardTelemetryEngine _instance = RealtimeDashboardTelemetryEngine._internal();
  factory RealtimeDashboardTelemetryEngine() => _instance;
  RealtimeDashboardTelemetryEngine._internal();

  final _telematics = FleetTelematicsEngine();
  RideState _rideState = RideState.ready;
  DateTime? _rideStartTime;
  double _accumulatedDistanceKm = 0.0;
  DateTime? _lastProcessedTimestamp;
  
  StreamController<LiveRideMetrics>? _metricsController;
  StreamSubscription<NormalizedTelemetrySnapshot>? _snapshotSub;

  Stream<LiveRideMetrics> get metricsStream {
    if (_metricsController == null || _metricsController!.isClosed) {
      _metricsController = StreamController<LiveRideMetrics>.broadcast(
        onListen: () {
          _startListening();
        },
        onCancel: () {
          _stopListening();
        },
      );
    }
    return _metricsController!.stream;
  }

  Stream<List<DiagnosticTroubleCode>> get diagnosticCodesStream => _telematics.diagnosticCodesStream;
  List<DiagnosticTroubleCode> get latestDtcs => _telematics.latestDtcs;

  void _startListening() {
    _snapshotSub?.cancel();
    _snapshotSub = _telematics.telemetryStream.listen((snapshot) {
      if (_metricsController != null && !_metricsController!.isClosed) {
        _metricsController!.add(getLiveMetrics());
      }
    });
  }

  void _stopListening() {
    _snapshotSub?.cancel();
    _snapshotSub = null;
  }

  RideState get rideState => _rideState;

  /// Returns current connection state from the active provider
  TelemetryConnectionStatus getConnectionStatus() {
    final linkState = _telematics.linkState;
    switch (linkState) {
      case DeviceLinkState.connected:
        return TelemetryConnectionStatus.connected;
      case DeviceLinkState.connecting:
      case DeviceLinkState.reconnecting:
        return TelemetryConnectionStatus.connecting;
      case DeviceLinkState.error:
        return TelemetryConnectionStatus.error;
      default:
        return TelemetryConnectionStatus.disconnected;
    }
  }

  /// Transitions ride state
  void startRide() {
    _rideState = RideState.riding;
    _rideStartTime = DateTime.now();
    _accumulatedDistanceKm = 0.0;
    _lastProcessedTimestamp = null;
  }

  void pauseRide() {
    if (_rideState == RideState.riding) {
      _rideState = RideState.paused;
    }
  }

  void resumeRide() {
    if (_rideState == RideState.paused) {
      _rideState = RideState.riding;
    }
  }

  void endRide() {
    _rideState = RideState.completed;
  }

  /// Retrieves live normalized telemetry from the actual provider
  LiveRideMetrics getLiveMetrics({String vehicleId = 'v_yamaha_r1m'}) {
    final tele = _telematics.latestSnapshot;
    final now = DateTime.now();

    final durationSec = _rideStartTime != null ? now.difference(_rideStartTime!).inSeconds : 0;
    
    // Integrate real speed over time for genuine distance accumulation
    if (tele != null && tele.vehicleSpeedKmh.isAvailable) {
      if (_rideState == RideState.riding) {
        if (_lastProcessedTimestamp != null && tele.timestamp.isAfter(_lastProcessedTimestamp!)) {
          final timeDeltaSec = tele.timestamp.difference(_lastProcessedTimestamp!).inMilliseconds / 1000.0;
          final speed = tele.vehicleSpeedKmh.value ?? 0.0;
          if (speed > 0) {
            _accumulatedDistanceKm += (speed / 3600.0) * timeDeltaSec;
          }
        }
      }
      // Always advance the processed timestamp to prevent jumping after pause/resume
      if (_lastProcessedTimestamp == null || tele.timestamp.isAfter(_lastProcessedTimestamp!)) {
        _lastProcessedTimestamp = tele.timestamp;
      }
    }

    if (tele == null) {
      return LiveRideMetrics(
        speedKmh: null,
        rpm: null,
        gear: null,
        coolantTempC: null,
        batteryVoltage: null,
        fuelLevelPercent: null,
        leanAngleDeg: null,
        distanceKm: _accumulatedDistanceKm,
        durationSeconds: durationSec,
        timestamp: now,
        isStale: true,
      );
    }

    // Determine if stale (e.g. older than 5 seconds)
    final bool isStale = now.difference(tele.timestamp).inSeconds > 5;

    // Validate sensor bounds, but return NULL if invalid/missing - NEVER fallback to fake values
    final speed = _validateSensorValue(tele.vehicleSpeedKmh.value, 0.0, 400.0);
    final rpm = _validateSensorValue(tele.engineRpm.value?.toDouble(), 0.0, 18000.0)?.round();
    final coolant = _validateSensorValue(tele.coolantTempC.value, -40.0, 150.0);
    final battery = _validateSensorValue(tele.batteryVoltage.value, 6.0, 18.0);
    final lean = _validateSensorValue(tele.leanAngleDeg.value, -70.0, 70.0);
    final gear = tele.gearPosition.value;

    return LiveRideMetrics(
      speedKmh: speed,
      rpm: rpm,
      gear: gear,
      coolantTempC: coolant,
      batteryVoltage: battery,
      fuelLevelPercent: tele.fuelLevelPct.value,
      leanAngleDeg: lean,
      distanceKm: _accumulatedDistanceKm,
      durationSeconds: durationSec,
      timestamp: tele.timestamp,
      isStale: isStale,
    );
  }

  double? _validateSensorValue(double? val, double min, double max) {
    if (val == null || val.isNaN || val.isInfinite) return null;
    if (val < min || val > max) return null;
    return val;
  }

  /// Returns historical telemetry chart points
  List<HistoricalChartPoint> getHistoricalChartPoints({String vehicleId = 'v_yamaha_r1m'}) {
    // Return empty or actual recorded session samples. We MUST NOT return fake data.
    final samples = _telematics.recordedSessionSamples;
    if (samples.isEmpty) return [];

    return samples.map((s) => HistoricalChartPoint(
      timestamp: s.timestamp,
      speedKmh: s.vehicleSpeedKmh.value,
      rpm: s.engineRpm.value,
      coolantTempC: s.coolantTempC.value,
      batteryVoltage: s.batteryVoltage.value,
    )).toList();
  }

  /// Answers dashboard queries offline
  String processDashboardAiQuery(String query) {
    final lower = query.toLowerCase();
    final metrics = getLiveMetrics();

    if (lower.contains('speed') || lower.contains('velocity') || lower.contains('rpm')) {
      final spd = metrics.speedKmh != null ? '${metrics.speedKmh!.round()} km/h' : 'Unavailable';
      final r = metrics.rpm != null ? '${metrics.rpm} RPM' : 'Unavailable';
      final g = metrics.gear != null ? 'Gear ${metrics.gear}' : 'Neutral';
      return 'Drivetrain Telemetry: Speed: $spd, Engine: $r, Transmission: $g.';
    }

    if (lower.contains('temperature') || lower.contains('coolant') || lower.contains('thermal')) {
      final temp = metrics.coolantTempC != null ? '${metrics.coolantTempC!.round()} degC' : 'Unavailable';
      return 'Thermal State: Coolant temperature is $temp.';
    }

    if (lower.contains('battery') || lower.contains('voltage') || lower.contains('electrical')) {
      final volt = metrics.batteryVoltage != null ? '${metrics.batteryVoltage!.toStringAsFixed(1)}V' : 'Unavailable';
      return 'Electrical Bus: Battery is at $volt.';
    }

    if (lower.contains('ride state') || lower.contains('trip state') || lower.contains('status')) {
      return 'Ride State: ${_rideState.label}. Duration: ${metrics.durationSeconds}s, Distance: ${metrics.distanceKm.toStringAsFixed(2)} km.';
    }

    return 'Dashboard Telemetry Engine: Real-time sensor stream connected. Eyes on the apex!';
  }

  void dispose() {
    _stopListening();
    if (_metricsController != null && !_metricsController!.isClosed) {
      _metricsController!.close();
    }
  }
}
