import 'dart:async';
import 'package:flutter/foundation.dart';
import 'generic_vehicle_connectivity_engine.dart';
import '../adapters/vehicle_connectivity_adapter.dart';

enum ConnectionRecoveryState {
  idle,
  monitoring,
  connectionLost,
  reconnecting,
  verifying,
  reconnected,
  recoveryFailed,
}

@immutable
class RecoveryStatusSnapshot {
  final ConnectionRecoveryState state;
  final int attemptCount;
  final int maxAttempts;
  final Duration nextRetryDelay;
  final String? lastError;
  final DateTime? lastLostTimestamp;

  const RecoveryStatusSnapshot({
    required this.state,
    required this.attemptCount,
    required this.maxAttempts,
    required this.nextRetryDelay,
    this.lastError,
    this.lastLostTimestamp,
  });
}

class ConnectionRecoveryEngine {
  static final ConnectionRecoveryEngine _instance = ConnectionRecoveryEngine._internal();
  factory ConnectionRecoveryEngine() => _instance;

  final _engine = GenericVehicleConnectivityEngine();
  final _statusController = StreamController<RecoveryStatusSnapshot>.broadcast();

  ConnectionRecoveryState _currentState = ConnectionRecoveryState.idle;
  int _attemptCount = 0;
  final int _maxAttempts = 5;
  Timer? _recoveryTimer;
  StreamSubscription? engineStateSubscription;

  String? _targetIdentifier;
  String? _protocolAdapterId;

  ConnectionRecoveryEngine._internal() {
    _initListener();
  }

  Stream<RecoveryStatusSnapshot> get statusStream => _statusController.stream;
  RecoveryStatusSnapshot get currentSnapshot => RecoveryStatusSnapshot(
        state: _currentState,
        attemptCount: _attemptCount,
        maxAttempts: _maxAttempts,
        nextRetryDelay: Duration(seconds: _calculateBackoffSeconds(_attemptCount)),
        lastLostTimestamp: _lastLostTimestamp,
      );

  DateTime? _lastLostTimestamp;

  void _initListener() {
    engineStateSubscription = _engine.stateStream.listen((state) {
      if (state == AdapterConnectionState.connected) {
        _onConnected();
      } else if (state == AdapterConnectionState.disconnected || state == AdapterConnectionState.error) {
        _onDisconnected();
      }
    });
  }

  void trackActiveConnection({
    required String targetIdentifier,
    required String protocolAdapterId,
  }) {
    _targetIdentifier = targetIdentifier;
    _protocolAdapterId = protocolAdapterId;
    _currentState = ConnectionRecoveryState.monitoring;
    _attemptCount = 0;
    _emitStatus();
  }

  void _onConnected() {
    _recoveryTimer?.cancel();
    _attemptCount = 0;
    _currentState = ConnectionRecoveryState.monitoring;
    _emitStatus();
  }

  void _onDisconnected() {
    if (_targetIdentifier == null || _protocolAdapterId == null) return;
    if (_currentState == ConnectionRecoveryState.reconnecting || _currentState == ConnectionRecoveryState.verifying) return;

    _lastLostTimestamp = DateTime.now();
    _currentState = ConnectionRecoveryState.connectionLost;
    _emitStatus();

    _scheduleNextRecoveryAttempt();
  }

  void _scheduleNextRecoveryAttempt() {
    if (_attemptCount >= _maxAttempts) {
      _currentState = ConnectionRecoveryState.recoveryFailed;
      _emitStatus();
      return;
    }

    _attemptCount++;
    final backoffSeconds = _calculateBackoffSeconds(_attemptCount);
    _currentState = ConnectionRecoveryState.reconnecting;
    _emitStatus();

    _recoveryTimer?.cancel();
    _recoveryTimer = Timer(Duration(seconds: backoffSeconds), () async {
      await _executeReconnectionAttempt();
    });
  }

  Future<void> _executeReconnectionAttempt() async {
    if (_targetIdentifier == null || _protocolAdapterId == null) return;

    _currentState = ConnectionRecoveryState.verifying;
    _emitStatus();

    final success = await _engine.connectVehicle(
      targetIdentifier: _targetIdentifier!,
      protocolAdapterId: _protocolAdapterId!,
    );

    if (success) {
      _currentState = ConnectionRecoveryState.reconnected;
      _emitStatus();
      _currentState = ConnectionRecoveryState.monitoring;
      _attemptCount = 0;
      _emitStatus();
    } else {
      _scheduleNextRecoveryAttempt();
    }
  }

  int _calculateBackoffSeconds(int attempt) {
    switch (attempt) {
      case 1:
        return 1;
      case 2:
        return 2;
      case 3:
        return 4;
      case 4:
        return 8;
      default:
        return 12;
    }
  }

  void reset() {
    _recoveryTimer?.cancel();
    _targetIdentifier = null;
    _protocolAdapterId = null;
    _attemptCount = 0;
    _currentState = ConnectionRecoveryState.idle;
    _emitStatus();
  }

  void _emitStatus() {
    _statusController.add(currentSnapshot);
  }
}
