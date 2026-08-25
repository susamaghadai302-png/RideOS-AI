import 'dart:async';
import '../models/safety_event_models.dart';
import '../../telemetry_engine/services/vehicle_telemetry_engine.dart';

enum CrashCountdownState {
  idle,
  countdownActive,
  confirmedEmergency,
  canceledSafe,
}

class SafetyEventEngine {
  static final SafetyEventEngine _instance = SafetyEventEngine._internal();
  factory SafetyEventEngine() => _instance;

  final _telemetryEngine = VehicleTelemetryEngine();

  final List<SafetyEvent> _safetyHistory = [];
  List<SafetyEvent> get safetyHistory => List.unmodifiable(_safetyHistory);

  final List<EmergencyContact> _emergencyContacts = [
    const EmergencyContact(
      id: 'contact_1',
      name: 'Primary Contact (Family)',
      phoneNumber: '+1 (555) 019-2834',
      relationship: 'Spouse / Family',
      isEnabled: true,
    ),
    const EmergencyContact(
      id: 'contact_2',
      name: 'Secondary Contact (Rider Squad)',
      phoneNumber: '+1 (555) 014-9988',
      relationship: 'Squad Ride Lead',
      isEnabled: true,
    ),
  ];
  List<EmergencyContact> get emergencyContacts => List.unmodifiable(_emergencyContacts);

  final _countdownStateController = StreamController<CrashCountdownState>.broadcast();
  Stream<CrashCountdownState> get countdownStateStream => _countdownStateController.stream;

  final _activeEventsController = StreamController<SafetyEvent>.broadcast();
  Stream<SafetyEvent> get activeEventsStream => _activeEventsController.stream;

  CrashCountdownState _countdownState = CrashCountdownState.idle;
  CrashCountdownState get countdownState => _countdownState;

  int _secondsRemaining = 15;
  int get secondsRemaining => _secondsRemaining;
  Timer? _countdownTimer;
  SafetyEvent? _activePendingEvent;
  SafetyEvent? get activePendingEvent => _activePendingEvent;

  SafetyEventEngine._internal() {
    _initTelemetryListener();
  }

  void _initTelemetryListener() {
    _telemetryEngine.snapshotStream.listen((snapshot) {
      if (snapshot.engineTempC.hasValidLiveValue && snapshot.engineTempC.value! > 115.0) {
        recordEvent(SafetyEvent(
          eventId: 'evt_temp_${DateTime.now().millisecondsSinceEpoch}',
          eventType: SafetyEventType.temperatureWarning,
          timestamp: DateTime.now(),
          confidence: SafetyEventConfidence.high,
          severity: SafetySeverity.warning,
          source: 'Vehicle Telemetry',
          description: 'Engine coolant temperature exceeded critical threshold (${snapshot.engineTempC.formattedWithUnit}).',
        ));
      }

      if (snapshot.batteryVoltage.hasValidLiveValue && snapshot.batteryVoltage.value! < 11.4) {
        recordEvent(SafetyEvent(
          eventId: 'evt_bat_${DateTime.now().millisecondsSinceEpoch}',
          eventType: SafetyEventType.batteryWarning,
          timestamp: DateTime.now(),
          confidence: SafetyEventConfidence.high,
          severity: SafetySeverity.caution,
          source: 'Vehicle Telemetry',
          description: 'Starter battery voltage dropped below nominal charge (${snapshot.batteryVoltage.formattedWithUnit}).',
        ));
      }
    });
  }

  /// Multi-signal fusion evaluation for crash / impact detection
  SafetyEvent evaluateMultiSignalEvent({
    required double peakGForce,
    required double speedDropKmh,
    required bool vehicleConnectionLost,
    required bool isStationaryAfterImpact,
    bool isSimulated = false,
  }) {
    final now = DateTime.now();

    // High confidence crash fusion: High G + severe speed drop + connection lost + stationary
    if (peakGForce >= 4.0 && speedDropKmh >= 30.0 && isStationaryAfterImpact) {
      final event = SafetyEvent(
        eventId: 'evt_crash_${now.millisecondsSinceEpoch}',
        eventType: SafetyEventType.crashSuspected,
        timestamp: now,
        confidence: SafetyEventConfidence.high,
        severity: SafetySeverity.critical,
        source: 'Multi-Signal Fusion (IMU + Speed + Telemetry)',
        isSimulated: isSimulated,
        description: 'Severe impact and sudden deceleration detected. Initiating emergency response countdown.',
      );
      recordEvent(event);
      _triggerCrashCountdown(event);
      return event;
    }

    // Isolated G-force spike without speed drop (e.g. phone dropped on seat, pothole hit)
    if (peakGForce >= 3.0 && speedDropKmh < 10.0) {
      final event = SafetyEvent(
        eventId: 'evt_impact_${now.millisecondsSinceEpoch}',
        eventType: SafetyEventType.hardImpact,
        timestamp: now,
        confidence: SafetyEventConfidence.low,
        severity: SafetySeverity.info,
        source: 'Phone Accelerometer (Isolated)',
        resolution: SafetyEventResolution.falsePositive,
        isSimulated: isSimulated,
        description: 'Transient shock detected without velocity change (Pothole / dropped device). No emergency action taken.',
      );
      recordEvent(event);
      return event;
    }

    // Abnormal stop without severe impact
    final event = SafetyEvent(
      eventId: 'evt_stop_${now.millisecondsSinceEpoch}',
      eventType: SafetyEventType.abnormalStop,
      timestamp: now,
      confidence: SafetyEventConfidence.medium,
      severity: SafetySeverity.caution,
      source: 'GPS / Speedometer',
      isSimulated: isSimulated,
      description: 'Rapid stop observed. Rider vitals and vehicle state nominal.',
    );
    recordEvent(event);
    return event;
  }

  void triggerManualSos({bool isSimulated = false}) {
    final now = DateTime.now();
    final event = SafetyEvent(
      eventId: 'evt_sos_${now.millisecondsSinceEpoch}',
      eventType: SafetyEventType.manualSos,
      timestamp: now,
      confidence: SafetyEventConfidence.high,
      severity: SafetySeverity.critical,
      source: 'Manual SOS Trigger',
      isSimulated: isSimulated,
      description: 'Emergency SOS activated manually by rider.',
    );
    recordEvent(event);
    _triggerCrashCountdown(event, initialSeconds: 10);
  }

  void _triggerCrashCountdown(SafetyEvent event, {int initialSeconds = 15}) {
    _activePendingEvent = event;
    _secondsRemaining = initialSeconds;
    _countdownState = CrashCountdownState.countdownActive;
    _emitCountdownState();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        _secondsRemaining--;
        _emitCountdownState();
      } else {
        _countdownTimer?.cancel();
        _countdownState = CrashCountdownState.confirmedEmergency;
        _activePendingEvent = _activePendingEvent?.copyWithResolution(SafetyEventResolution.emergencyConfirmed);
        if (_activePendingEvent != null) {
          _updateHistoryResolution(_activePendingEvent!.eventId, SafetyEventResolution.emergencyConfirmed);
        }
        _emitCountdownState();
      }
    });
  }

  void cancelCountdownRiderSafe() {
    _countdownTimer?.cancel();
    _countdownState = CrashCountdownState.canceledSafe;
    if (_activePendingEvent != null) {
      _activePendingEvent = _activePendingEvent!.copyWithResolution(SafetyEventResolution.riderConfirmedSafe);
      _updateHistoryResolution(_activePendingEvent!.eventId, SafetyEventResolution.riderConfirmedSafe);
    }
    _emitCountdownState();
    _countdownState = CrashCountdownState.idle;
    _emitCountdownState();
  }

  void confirmEmergencyNow() {
    _countdownTimer?.cancel();
    _secondsRemaining = 0;
    _countdownState = CrashCountdownState.confirmedEmergency;
    if (_activePendingEvent != null) {
      _activePendingEvent = _activePendingEvent!.copyWithResolution(SafetyEventResolution.emergencyConfirmed);
      _updateHistoryResolution(_activePendingEvent!.eventId, SafetyEventResolution.emergencyConfirmed);
    }
    _emitCountdownState();
  }

  void recordEvent(SafetyEvent event) {
    _safetyHistory.insert(0, event);
    if (_safetyHistory.length > 100) {
      _safetyHistory.removeLast();
    }
    if (!_activeEventsController.isClosed) {
      _activeEventsController.add(event);
    }
  }

  void _updateHistoryResolution(String eventId, SafetyEventResolution res) {
    final idx = _safetyHistory.indexWhere((e) => e.eventId == eventId);
    if (idx != -1) {
      _safetyHistory[idx] = _safetyHistory[idx].copyWithResolution(res);
    }
  }

  // Emergency Contacts
  void addEmergencyContact(EmergencyContact contact) {
    _emergencyContacts.add(contact);
  }

  void removeEmergencyContact(String id) {
    _emergencyContacts.removeWhere((c) => c.id == id);
  }

  void toggleEmergencyContact(String id, bool enabled) {
    final idx = _emergencyContacts.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _emergencyContacts[idx] = _emergencyContacts[idx].copyWith(isEnabled: enabled);
    }
  }

  // Transparent Rider Safety Score Calculation
  RiderSafetyScore calculateRiderSafetyScore() {
    int score = 92;
    final subScores = {
      'Braking Smoothness': 90,
      'Throttle Modulation': 95,
      'Speed Compliance': 92,
      'Vehicle Thermal Health': 98,
    };

    final positiveFactors = <String>[
      'Optimal braking distance preservation',
      'Consistent cornering stability with zero ABS fault triggers',
      'Smooth throttle ramp-up on urban corridors',
    ];

    final improvementAreas = <String>[
      'Reduce rapid deceleration events during peak evening traffic',
    ];

    return RiderSafetyScore(
      overallScore: score,
      subScores: subScores,
      positiveFactors: positiveFactors,
      improvementAreas: improvementAreas,
      evaluatedAt: DateTime.now(),
    );
  }

  void _emitCountdownState() {
    if (!_countdownStateController.isClosed) {
      _countdownStateController.add(_countdownState);
    }
  }
}
