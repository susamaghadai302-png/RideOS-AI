import 'dart:async';
import '../interfaces/device_provider.dart';
import '../models/normalized_telemetry_models.dart';
import '../providers/simulator_provider.dart';
import '../providers/ble_diagnostic_provider.dart';
import '../providers/obd2_provider.dart';

class FleetTelematicsEngine {
  static final FleetTelematicsEngine _instance = FleetTelematicsEngine._internal();
  factory FleetTelematicsEngine() => _instance;

  /// Production starts with NO active provider.
  /// A provider is activated only when explicitly selected via [switchProvider].
  DeviceProvider? _activeProvider;
  DeviceProvider? get activeProvider => _activeProvider;

  final Map<String, DeviceProvider> _registeredProviders = {
    'simulator': SimulatorProvider(),
    'ble_generic': BleDiagnosticProvider(),
    'obd2_can': Obd2Provider(),
  };

  StreamSubscription? _telemetrySub;
  StreamSubscription? _dtcSub;
  NormalizedTelemetrySnapshot? _latestSnapshot;
  NormalizedTelemetrySnapshot? get latestSnapshot => _latestSnapshot;

  final _telemetryController = StreamController<NormalizedTelemetrySnapshot>.broadcast();
  Stream<NormalizedTelemetrySnapshot> get telemetryStream => _telemetryController.stream;

  final _dtcController = StreamController<List<DiagnosticTroubleCode>>.broadcast();
  Stream<List<DiagnosticTroubleCode>> get diagnosticCodesStream => _dtcController.stream;

  List<DiagnosticTroubleCode> _latestDtcs = [];
  List<DiagnosticTroubleCode> get latestDtcs => List.unmodifiable(_latestDtcs);

  // Session Recording
  bool _isRecordingSession = false;
  bool get isRecordingSession => _isRecordingSession;

  final List<NormalizedTelemetrySnapshot> _recordedSessionSamples = [];
  List<NormalizedTelemetrySnapshot> get recordedSessionSamples => List.unmodifiable(_recordedSessionSamples);

  DateTime? _sessionStartTime;
  DateTime? get sessionStartTime => _sessionStartTime;

  FleetTelematicsEngine._internal();

  /// Returns the link state of the active provider, or disconnected if none.
  DeviceLinkState get linkState => _activeProvider?.linkState ?? DeviceLinkState.disconnected;

  void switchProvider(String providerKey) {
    if (_registeredProviders.containsKey(providerKey)) {
      _unbindActiveProvider();
      _activeProvider = _registeredProviders[providerKey]!;
      _bindActiveProvider();
    }
  }

  Future<bool> connectDevice(String targetIdentifier) async {
    if (_activeProvider == null) return false;
    return _activeProvider!.connect(targetIdentifier);
  }

  Future<void> disconnectDevice() async {
    if (_activeProvider == null) return;
    return _activeProvider!.disconnect();
  }

  void startRecordingSession() {
    _isRecordingSession = true;
    _sessionStartTime = DateTime.now();
    _recordedSessionSamples.clear();
  }

  Map<String, dynamic> stopRecordingSession() {
    _isRecordingSession = false;
    final totalSamples = _recordedSessionSamples.length;
    double maxSpeed = 0.0;
    double speedSum = 0.0;

    for (final s in _recordedSessionSamples) {
      final spd = s.vehicleSpeedKmh.value ?? 0.0;
      if (spd > maxSpeed) maxSpeed = spd;
      speedSum += spd;
    }

    final avgSpeed = totalSamples > 0 ? (speedSum / totalSamples) : 0.0;

    return {
      'startTime': _sessionStartTime?.toIso8601String(),
      'endTime': DateTime.now().toIso8601String(),
      'totalSamples': totalSamples,
      'averageSpeedKmh': avgSpeed,
      'maxSpeedKmh': maxSpeed,
      'dataSource': _activeProvider?.dataSourceClassification.name ?? 'none',
    };
  }

  void _bindActiveProvider() {
    if (_activeProvider == null) return;
    _telemetrySub = _activeProvider!.telemetryStream.listen((snapshot) {
      _latestSnapshot = snapshot;
      if (_isRecordingSession) {
        _recordedSessionSamples.add(snapshot);
      }
      if (!_telemetryController.isClosed) {
        _telemetryController.add(snapshot);
      }
    });
    _dtcSub = _activeProvider!.diagnosticCodesStream.listen((dtcs) {
      _latestDtcs = dtcs;
      if (!_dtcController.isClosed) {
        _dtcController.add(dtcs);
      }
    });
  }

  void _unbindActiveProvider() {
    _telemetrySub?.cancel();
    _telemetrySub = null;
    _dtcSub?.cancel();
    _dtcSub = null;
  }

  Future<void> dispose() async {
    _unbindActiveProvider();
    await _telemetryController.close();
    await _dtcController.close();
    for (final p in _registeredProviders.values) {
      await p.dispose();
    }
  }

  void injectSimulatedSnapshotForTesting(NormalizedTelemetrySnapshot snapshot) {
    _latestSnapshot = snapshot;
    if (!_telemetryController.isClosed) {
      _telemetryController.add(snapshot);
    }
  }

  void injectDiagnosticsForTesting(List<DiagnosticTroubleCode> dtcs) {
    _latestDtcs = dtcs;
    if (!_dtcController.isClosed) {
      _dtcController.add(dtcs);
    }
  }
}

