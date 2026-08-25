import 'dart:async';
import 'dart:math' as math;
import '../../../../core/services/lux_haptics_audio_service.dart';

// Conditional import for Web Audio API synthesis
import 'garage_audio_web_stub.dart'
    if (dart.library.html) 'garage_audio_web_impl.dart';

/// Engine State Machine for 3D Garage
enum EngineStateType {
  off,
  cranking,
  idle,
  revving,
  cooling,
}

/// Synthesizes and controls realistic multi-harmonic engine audio and telemetry sound effects
class GarageAudioEngineService {
  static final GarageAudioEngineService _instance = GarageAudioEngineService._internal();
  factory GarageAudioEngineService() => _instance;
  GarageAudioEngineService._internal();

  EngineStateType _currentState = EngineStateType.off;
  EngineStateType get currentState => _currentState;

  double _currentRpm = 0.0;
  double get currentRpm => _currentRpm;

  bool _isAudioMuted = false;
  bool get isAudioMuted => _isAudioMuted;

  final _stateController = StreamController<EngineStateType>.broadcast();
  Stream<EngineStateType> get stateStream => _stateController.stream;

  final _rpmController = StreamController<double>.broadcast();
  Stream<double> get rpmStream => _rpmController.stream;

  Timer? _simulationTimer;
  double _targetRpm = 0.0;
  double _throttleInput = 0.0; // 0.0 - 1.0

  void toggleAudioMute() {
    _isAudioMuted = !_isAudioMuted;
    if (_isAudioMuted) {
      GarageAudioWebHelper.stopAllEngineAudio();
    } else if (_currentState != EngineStateType.off) {
      GarageAudioWebHelper.startEngineRumble(_currentRpm);
    }
  }

  /// Initiates realistic motorcycle engine starter cranking sequence
  Future<void> startEngine({double idleRpm = 1250.0}) async {
    if (_currentState != EngineStateType.off) return;

    _currentState = EngineStateType.cranking;
    _stateController.add(_currentState);
    LuxAudioHapticsService.heavyImpact();

    // Play starter motor crank audio
    if (!_isAudioMuted) {
      GarageAudioWebHelper.playStarterCrank();
    }

    // Cranking phase (700ms)
    await Future.delayed(const Duration(milliseconds: 700));

    // Engine catches and revs to starter flare then settles to idle
    _currentState = EngineStateType.idle;
    _stateController.add(_currentState);
    _currentRpm = idleRpm * 1.8; // Initial fire flare
    _targetRpm = idleRpm;
    _startPhysicsLoop(idleRpm);

    if (!_isAudioMuted) {
      GarageAudioWebHelper.startEngineRumble(_currentRpm);
    }
  }

  /// Stops motorcycle engine with smooth RPM decay
  Future<void> stopEngine() async {
    if (_currentState == EngineStateType.off) return;

    _currentState = EngineStateType.cooling;
    _stateController.add(_currentState);
    LuxAudioHapticsService.mediumImpact();

    _targetRpm = 0.0;
    _throttleInput = 0.0;

    // Decay to 0
    await Future.delayed(const Duration(milliseconds: 900));
    _currentState = EngineStateType.off;
    _currentRpm = 0.0;
    _stateController.add(_currentState);
    _rpmController.add(0.0);
    _simulationTimer?.cancel();

    if (!_isAudioMuted) {
      GarageAudioWebHelper.stopAllEngineAudio();
    }
  }

  /// Sets user throttle input (0.0 to 1.0)
  void setThrottle(double throttle, {double maxRpm = 14500.0, double idleRpm = 1250.0}) {
    if (_currentState == EngineStateType.off || _currentState == EngineStateType.cranking) {
      return;
    }

    _throttleInput = throttle.clamp(0.0, 1.0);
    if (_throttleInput > 0.05) {
      _currentState = EngineStateType.revving;
      _targetRpm = idleRpm + (_throttleInput * (maxRpm - idleRpm));
      LuxAudioHapticsService.lightImpact();
    } else {
      _currentState = EngineStateType.idle;
      _targetRpm = idleRpm;
    }
    _stateController.add(_currentState);
  }

  /// 60 FPS physics loop for smooth RPM needle sweeps and audio pitch modulation
  void _startPhysicsLoop(double idleRpm) {
    _simulationTimer?.cancel();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_currentState == EngineStateType.off) {
        timer.cancel();
        return;
      }

      // Smooth inertia approach to target RPM
      final double lerpFactor = _targetRpm > _currentRpm ? 0.22 : 0.12; // Revs up faster than decays
      _currentRpm += (_targetRpm - _currentRpm) * lerpFactor;

      // Add subtle combustion vibration jitter at idle
      if (_currentState == EngineStateType.idle) {
        final jitter = (math.sin(DateTime.now().millisecondsSinceEpoch / 45.0) * 25.0);
        _rpmController.add((_currentRpm + jitter).clamp(0.0, 16000.0));
      } else {
        _rpmController.add(_currentRpm.clamp(0.0, 16000.0));
      }

      // Update Web Audio oscillator pitch in real time
      if (!_isAudioMuted) {
        GarageAudioWebHelper.updateEnginePitch(_currentRpm);
      }
    });
  }

  void dispose() {
    _simulationTimer?.cancel();
    GarageAudioWebHelper.stopAllEngineAudio();
    _stateController.close();
    _rpmController.close();
  }
}
