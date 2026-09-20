import 'dart:async';
import '../models/metric_types.dart';
import '../models/telemetry_metric.dart';
import '../models/telemetry_snapshot.dart';
import '../policies/freshness_policy.dart';
import '../policies/deadband_policy.dart';
import '../policies/source_precedence_policy.dart';
import 'telemetry_normalizer.dart';
import '../../diagnostics/models/diagnostic_types.dart';
import '../../diagnostics/models/pid_definition.dart';
import '../../diagnostics/services/ecu_diagnostic_manager.dart';

/// Central Live Telemetry Pipeline.
///
/// Ingests raw/decoded diagnostic measurements from [EcuDiagnosticManager],
/// normalizes units, enforces freshness and deadband policies, handles multi-ECU
/// provenance, and exposes high-frequency telemetry streams to the UI/HUD.
class TelemetryPipeline {
  static final TelemetryPipeline instance = TelemetryPipeline._internal();
  factory TelemetryPipeline({
    EcuDiagnosticManager? diagnosticManager,
    TelemetryNormalizer? normalizer,
    TelemetryFreshnessPolicy? freshnessPolicy,
    TelemetryDeadbandPolicy? deadbandPolicy,
    SourcePrecedencePolicy? precedencePolicy,
  }) {
    if (diagnosticManager != null ||
        normalizer != null ||
        freshnessPolicy != null ||
        deadbandPolicy != null ||
        precedencePolicy != null) {
      return TelemetryPipeline._custom(
        diagnosticManager: diagnosticManager ?? EcuDiagnosticManager.instance,
        normalizer: normalizer ?? TelemetryNormalizer.instance,
        freshnessPolicy: freshnessPolicy ?? TelemetryFreshnessPolicy.standard,
        deadbandPolicy: deadbandPolicy ?? TelemetryDeadbandPolicy.standard,
        precedencePolicy: precedencePolicy ?? SourcePrecedencePolicy.standard,
      );
    }
    return instance;
  }

  TelemetryPipeline._internal()
      : _diagnosticManager = EcuDiagnosticManager.instance,
        _normalizer = TelemetryNormalizer.instance,
        freshnessPolicy = TelemetryFreshnessPolicy.standard,
        deadbandPolicy = TelemetryDeadbandPolicy.standard,
        precedencePolicy = SourcePrecedencePolicy.standard {
    _init();
  }

  TelemetryPipeline._custom({
    required EcuDiagnosticManager diagnosticManager,
    required TelemetryNormalizer normalizer,
    required this.freshnessPolicy,
    required this.deadbandPolicy,
    required this.precedencePolicy,
  })  : _diagnosticManager = diagnosticManager,
        _normalizer = normalizer {
    _init();
  }

  final EcuDiagnosticManager _diagnosticManager;
  final TelemetryNormalizer _normalizer;
  TelemetryFreshnessPolicy freshnessPolicy;
  TelemetryDeadbandPolicy deadbandPolicy;
  SourcePrecedencePolicy precedencePolicy;

  // Stream Controllers
  final _snapshotController = StreamController<NormalizedTelemetrySnapshot>.broadcast();
  Stream<NormalizedTelemetrySnapshot> get snapshotStream => _snapshotController.stream;

  final _metricController = StreamController<NormalizedTelemetryMetric>.broadcast();
  Stream<NormalizedTelemetryMetric> get metricStream => _metricController.stream;

  // State
  NormalizedTelemetrySnapshot _currentSnapshot = NormalizedTelemetrySnapshot.initial();
  NormalizedTelemetrySnapshot get currentSnapshot => _currentSnapshot;

  StreamSubscription? _pidSubscription;
  Timer? _freshnessWatchdogTimer;
  NormalizedTelemetryMetric? _previousSpeedMetric;

  void _init() {
    // Listen to Phase 18 diagnostic PID updates
    _pidSubscription = _diagnosticManager.pidStream.listen(_handleDiagnosticPidBatch);

    // Periodic freshness watchdog (checks staleness every 500ms)
    _freshnessWatchdogTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _evaluateSnapshotFreshness();
    });
  }

  /// Ingests a raw or decoded PID measurement into the normalization pipeline.
  void ingestPidMeasurement(
    DecodedPidMeasurement measurement, {
    EcuModule sourceEcu = EcuModule.engineControlModule_ECM,
    bool isSimulated = false,
  }) {
    final normalized = _normalizer.normalizePidMeasurement(
      measurement,
      sourceEcu: sourceEcu,
      isSimulated: isSimulated,
    );

    _processNormalizedMetric(normalized);
  }

  /// Ingests a direct [NormalizedTelemetryMetric] (e.g. from tests or CAN sensors).
  void ingestMetric(NormalizedTelemetryMetric metric) {
    _processNormalizedMetric(metric);
  }

  void _handleDiagnosticPidBatch(Map<int, DecodedPidMeasurement> batch) {
    const isSim = false;

    for (final measurement in batch.values) {
      ingestPidMeasurement(
        measurement,
        sourceEcu: EcuModule.engineControlModule_ECM,
        isSimulated: isSim,
      );
    }
  }

  void _processNormalizedMetric(NormalizedTelemetryMetric candidate) {
    final metricId = candidate.metricId;
    final currentMetric = _currentSnapshot.getMetric(metricId);

    // 1. Multi-ECU Precedence Check
    if (currentMetric != null && currentMetric.isLive) {
      final shouldOverride = precedencePolicy.shouldOverride(
        metricId,
        currentMetric.sourceEcu,
        candidate.sourceEcu,
      );
      if (!shouldOverride) {
        // Lower precedence ECU -> ignore
        return;
      }
    }

    // 2. Deadband Filtering (suppress negligible noise)
    final shouldEmit = deadbandPolicy.shouldEmit(
      metricId,
      currentMetric?.value,
      candidate.value,
    );

    if (!shouldEmit && currentMetric?.freshness == candidate.freshness) {
      // Delta below deadband threshold and freshness unchanged -> do not emit
      return;
    }

    // 3. Derived Metrics Calculation (e.g. Longitudinal Acceleration)
    if (metricId == TelemetryMetricId.vehicleSpeed && candidate.value != null) {
      if (_previousSpeedMetric != null) {
        final accel = _normalizer.computeDerivedAcceleration(
          previousSpeed: _previousSpeedMetric!,
          currentSpeed: candidate,
        );
        if (accel != null) {
          _currentSnapshot = _currentSnapshot.withUpdatedMetric(accel);
          _metricController.add(accel);
        }
      }
      _previousSpeedMetric = candidate;
    }

    // 4. Update Snapshot and Emit
    _currentSnapshot = _currentSnapshot.withUpdatedMetric(candidate);
    _metricController.add(candidate);
    _snapshotController.add(_currentSnapshot);
  }

  void _evaluateSnapshotFreshness() {
    final updated = _currentSnapshot.evaluateFreshness(
      freshnessPolicy.defaultFreshnessThreshold,
      freshnessPolicy.defaultUnavailableThreshold,
    );

    if (!identical(updated, _currentSnapshot)) {
      _currentSnapshot = updated;
      _snapshotController.add(_currentSnapshot);
    }
  }

  /// Resets all live metrics to UNAVAILABLE (e.g. on transport disconnect).
  void handleTransportDisconnect() {
    _currentSnapshot = NormalizedTelemetrySnapshot.initial();
    _previousSpeedMetric = null;
    _snapshotController.add(_currentSnapshot);
  }

  /// Cleans up subscriptions and timers.
  Future<void> dispose() async {
    await _pidSubscription?.cancel();
    _freshnessWatchdogTimer?.cancel();
    await _snapshotController.close();
    await _metricController.close();
  }
}
