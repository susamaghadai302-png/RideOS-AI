import 'dart:async';
import '../../telemetry/services/telemetry_pipeline.dart';
import '../../telemetry/models/telemetry_snapshot.dart';
import '../../diagnostics/services/ecu_diagnostic_manager.dart';
import '../../diagnostics/models/dtc_record.dart';
import '../models/predictive_health_score.dart';
import '../models/predictive_alert.dart';
import '../models/component_wear.dart';
import 'wear_calculator.dart';

class PredictiveHealthEngine {
  static final PredictiveHealthEngine _instance = PredictiveHealthEngine._internal();
  static PredictiveHealthEngine get instance => _instance;

  final WearCalculator _wearCalculator = WearCalculator();
  
  StreamSubscription<NormalizedTelemetrySnapshot>? _telemetrySub;
  StreamSubscription<List<DiagnosticFaultRecord>>? _dtcSub;

  DateTime? _lastEvaluationTime;
  
  Map<HealthSubsystem, ComponentWear> _wearState = {
    for (var sub in HealthSubsystem.values) sub: ComponentWear.initial(sub)
  };

  PredictiveHealthScore _currentScore = PredictiveHealthScore.initial();
  final List<PredictiveAlert> _activeAlerts = [];

  final _scoreController = StreamController<PredictiveHealthScore>.broadcast();
  final _alertsController = StreamController<List<PredictiveAlert>>.broadcast();

  Stream<PredictiveHealthScore> get scoreStream => _scoreController.stream;
  Stream<List<PredictiveAlert>> get alertsStream => _alertsController.stream;

  PredictiveHealthScore get currentScore => _currentScore;
  List<PredictiveAlert> get activeAlerts => List.unmodifiable(_activeAlerts);

  List<DiagnosticFaultRecord> _currentDtcs = [];

  PredictiveHealthEngine._internal();

  void start(TelemetryPipeline telemetryPipeline, EcuDiagnosticManager diagnosticManager) {
    _lastEvaluationTime = DateTime.now();

    _telemetrySub = telemetryPipeline.snapshotStream.listen(_onTelemetrySnapshot);
    _dtcSub = diagnosticManager.faultsStream.listen(_onDtcsUpdated);
  }

  void stop() {
    _telemetrySub?.cancel();
    _dtcSub?.cancel();
  }

  void _onDtcsUpdated(List<DiagnosticFaultRecord> dtcs) {
    _currentDtcs = dtcs;
    _evaluateHealth(null); // Recalculate with current telemetry but new DTCs
  }

  void _onTelemetrySnapshot(NormalizedTelemetrySnapshot snapshot) {
    _evaluateHealth(snapshot);
  }

  void _evaluateHealth(NormalizedTelemetrySnapshot? snapshot) {
    final now = DateTime.now();
    final deltaMs = _lastEvaluationTime != null ? now.difference(_lastEvaluationTime!).inMilliseconds : 0;
    _lastEvaluationTime = now;

    if (snapshot != null && deltaMs > 0) {
      // 1. Accumulate Wear based on snapshot
      _wearState[HealthSubsystem.engine] = _wearCalculator.evaluateEngineWear(_wearState[HealthSubsystem.engine]!, snapshot, deltaMs);
      _wearState[HealthSubsystem.thermal] = _wearCalculator.evaluateThermalWear(_wearState[HealthSubsystem.thermal]!, snapshot, deltaMs);
      _wearState[HealthSubsystem.battery] = _wearCalculator.evaluateBatteryWear(_wearState[HealthSubsystem.battery]!, snapshot, deltaMs);
    }

    // 2. Generate Subsystem Scores
    final newSubsystems = <HealthSubsystem, SubsystemHealth>{};
    double totalScore = 0.0;

    for (final sub in HealthSubsystem.values) {
      double score = 100.0 - (_wearState[sub]?.wearAccumulation ?? 0.0);

      // Apply DTC penalties (simplified logic for Phase 20)
      if (sub == HealthSubsystem.engine && _currentDtcs.any((d) => d.code.startsWith('P0'))) {
        score -= 20.0;
      } else if (sub == HealthSubsystem.battery && _currentDtcs.any((d) => d.code.startsWith('P0A'))) {
        score -= 20.0;
      }

      score = score.clamp(0.0, 100.0);
      newSubsystems[sub] = SubsystemHealth(subsystem: sub, score: score);
      totalScore += score;
    }

    final overall = totalScore / HealthSubsystem.values.length;

    _currentScore = _currentScore.copyWith(
      overallScore: overall,
      subsystems: newSubsystems,
      timestamp: now,
    );

    _scoreController.add(_currentScore);

    // 3. Generate Alerts based on new score
    _evaluateAlerts();
  }

  void _evaluateAlerts() {
    bool alertsChanged = false;

    // Check Battery
    final batteryScore = _currentScore.subsystems[HealthSubsystem.battery]!.score;
    if (batteryScore < 40.0 && !_hasAlertForSubsystem(HealthSubsystem.battery)) {
      _activeAlerts.add(PredictiveAlert(
        id: 'batt_${DateTime.now().millisecondsSinceEpoch}',
        subsystem: HealthSubsystem.battery,
        title: 'Critical Battery Decay',
        description: 'Battery health has degraded below 40%. Repeated deep discharges detected.',
        recommendedAction: 'Replace 12V battery soon to avoid being stranded.',
        severity: AlertSeverity.critical,
        estimatedTimeToFailure: const Duration(days: 3),
        timestamp: DateTime.now(),
      ));
      alertsChanged = true;
    }

    // Check Thermal
    final thermalScore = _currentScore.subsystems[HealthSubsystem.thermal]!.score;
    if (thermalScore < 60.0 && !_hasAlertForSubsystem(HealthSubsystem.thermal)) {
      _activeAlerts.add(PredictiveAlert(
        id: 'therm_${DateTime.now().millisecondsSinceEpoch}',
        subsystem: HealthSubsystem.thermal,
        title: 'Cooling System Stress',
        description: 'Frequent overheating events are degrading the cooling system.',
        recommendedAction: 'Check coolant levels and radiator fan operation.',
        severity: AlertSeverity.warning,
        estimatedTimeToFailure: const Duration(days: 14),
        timestamp: DateTime.now(),
      ));
      alertsChanged = true;
    }

    // Check Engine
    final engineScore = _currentScore.subsystems[HealthSubsystem.engine]!.score;
    if (engineScore < 50.0 && !_hasAlertForSubsystem(HealthSubsystem.engine)) {
      _activeAlerts.add(PredictiveAlert(
        id: 'eng_${DateTime.now().millisecondsSinceEpoch}',
        subsystem: HealthSubsystem.engine,
        title: 'Engine Wear Warning',
        description: 'Excessive high-RPM operation detected. Engine health is compromised.',
        recommendedAction: 'Schedule engine inspection and oil change immediately.',
        severity: AlertSeverity.critical,
        estimatedTimeToFailure: const Duration(days: 30),
        timestamp: DateTime.now(),
      ));
      alertsChanged = true;
    }

    if (alertsChanged) {
      _alertsController.add(List.unmodifiable(_activeAlerts));
    }
  }

  bool _hasAlertForSubsystem(HealthSubsystem subsystem) {
    return _activeAlerts.any((a) => a.subsystem == subsystem);
  }

  // Exposed for tests to reset state
  void reset() {
    _wearState = {
      for (var sub in HealthSubsystem.values) sub: ComponentWear.initial(sub)
    };
    _currentScore = PredictiveHealthScore.initial();
    _activeAlerts.clear();
    _currentDtcs = [];
  }
}
