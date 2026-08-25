import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/telemetry_metric_entry.dart';
import 'vehicle_telemetry_engine.dart';
import '../../vehicle_connectivity/services/connection_recovery_engine.dart';

enum RideSessionState {
  idle,
  connecting,
  connected,
  rideReady,
  riding,
  paused,
  connectionLost,
  reconnecting,
  ended,
}

@immutable
class RideSessionSummary {
  final String sessionId;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final double totalDistanceKm;
  final double averageSpeedKmh;
  final double maxSpeedKmh;
  final double? energyOrFuelConsumed;
  final int samplesRecorded;
  final int connectionDropsCount;
  final bool isOfflineRecorded;

  const RideSessionSummary({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.totalDistanceKm,
    required this.averageSpeedKmh,
    required this.maxSpeedKmh,
    this.energyOrFuelConsumed,
    required this.samplesRecorded,
    required this.connectionDropsCount,
    this.isOfflineRecorded = false,
  });
}

class RideSessionManager {
  static final RideSessionManager _instance = RideSessionManager._internal();
  factory RideSessionManager() => _instance;

  final _telemetryEngine = VehicleTelemetryEngine();
  final _recoveryEngine = ConnectionRecoveryEngine();
  final _stateController = StreamController<RideSessionState>.broadcast();

  RideSessionState _currentState = RideSessionState.idle;
  RideSessionState get currentState => _currentState;
  Stream<RideSessionState> get stateStream => _stateController.stream;

  DateTime? _rideStartTime;
  double _distanceKm = 0.0;
  double _maxSpeed = 0.0;
  double _speedSum = 0.0;
  int _speedCount = 0;
  int _connectionDrops = 0;
  final List<LiveVehicleCockpitSnapshot> _bufferedTelemetryBatch = [];

  StreamSubscription? _telemetrySub;
  StreamSubscription? _recoverySub;
  Timer? _sessionTimer;
  Duration _elapsed = Duration.zero;

  RideSessionManager._internal() {
    _initRecoveryListener();
  }

  void _initRecoveryListener() {
    _recoverySub = _recoveryEngine.statusStream.listen((status) {
      if (_currentState == RideSessionState.riding || _currentState == RideSessionState.paused) {
        if (status.state == ConnectionRecoveryState.connectionLost || status.state == ConnectionRecoveryState.reconnecting) {
          _connectionDrops++;
          _currentState = RideSessionState.connectionLost;
          _emitState();
        } else if (status.state == ConnectionRecoveryState.reconnected || status.state == ConnectionRecoveryState.monitoring) {
          _currentState = RideSessionState.riding;
          _emitState();
        }
      }
    });
  }

  void startRideSession() {
    _rideStartTime = DateTime.now();
    _distanceKm = 0.0;
    _maxSpeed = 0.0;
    _speedSum = 0.0;
    _speedCount = 0;
    _connectionDrops = 0;
    _elapsed = Duration.zero;
    _bufferedTelemetryBatch.clear();

    _currentState = RideSessionState.riding;
    _emitState();

    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_currentState == RideSessionState.riding) {
        _elapsed += const Duration(seconds: 1);
      }
    });

    _telemetrySub?.cancel();
    _telemetrySub = _telemetryEngine.snapshotStream.listen((snapshot) {
      if (_currentState == RideSessionState.riding) {
        _processTelemetrySample(snapshot);
      }
    });
  }

  void pauseRideSession() {
    if (_currentState == RideSessionState.riding) {
      _currentState = RideSessionState.paused;
      _emitState();
    }
  }

  void resumeRideSession() {
    if (_currentState == RideSessionState.paused) {
      _currentState = RideSessionState.riding;
      _emitState();
    }
  }

  RideSessionSummary endRideSession({bool isOffline = false}) {
    _currentState = RideSessionState.ended;
    _emitState();
    _sessionTimer?.cancel();
    _telemetrySub?.cancel();

    final summary = RideSessionSummary(
      sessionId: 'ride_${_rideStartTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch}',
      startTime: _rideStartTime ?? DateTime.now(),
      endTime: DateTime.now(),
      duration: _elapsed,
      totalDistanceKm: _distanceKm,
      averageSpeedKmh: _speedCount > 0 ? (_speedSum / _speedCount) : 0.0,
      maxSpeedKmh: _maxSpeed,
      samplesRecorded: _bufferedTelemetryBatch.length,
      connectionDropsCount: _connectionDrops,
      isOfflineRecorded: isOffline,
    );

    _currentState = RideSessionState.idle;
    _emitState();
    return summary;
  }

  void _processTelemetrySample(LiveVehicleCockpitSnapshot snapshot) {
    if (snapshot.speedKmh.hasValidLiveValue) {
      final speed = snapshot.speedKmh.value!;
      if (speed > _maxSpeed) _maxSpeed = speed;
      _speedSum += speed;
      _speedCount++;
    }

    if (snapshot.tripDistanceKm.hasValidLiveValue) {
      _distanceKm = snapshot.tripDistanceKm.value!;
    } else if (snapshot.speedKmh.hasValidLiveValue) {
      // 1-second sample distance integration (speed / 3600)
      _distanceKm += (snapshot.speedKmh.value! / 3600.0);
    }

    // Buffer sampled records (1 per second max to conserve memory and battery)
    if (_bufferedTelemetryBatch.length < 3600) {
      _bufferedTelemetryBatch.add(snapshot);
    }
  }

  void _emitState() {
    if (!_stateController.isClosed) {
      _stateController.add(_currentState);
    }
  }

  void dispose() {
    _sessionTimer?.cancel();
    _telemetrySub?.cancel();
    _recoverySub?.cancel();
  }
}
