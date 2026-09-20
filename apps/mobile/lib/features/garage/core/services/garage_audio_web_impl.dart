/*
// ignore: avoid_web_libraries_in_flutter
import 'dart:js' as js;

/// Web Audio API synthesized multi-harmonic motorcycle engine sound via standard JS interop
class GarageAudioWebHelper {
  static dynamic _audioCtx;
  static dynamic _oscBase;
  static dynamic _oscSub;
  static dynamic _oscHarmonic;
  static dynamic _mainGain;
  static bool _isPlaying = false;

  static void _ensureContext() {
    try {
      if (_audioCtx == null) {
        final window = js.context;
        final audioCtxClass = window['AudioContext'] ?? window['webkitAudioContext'];
        if (audioCtxClass != null) {
          _audioCtx = js.JsObject(audioCtxClass as js.JsFunction, []);
        }
      }
      if (_audioCtx != null && _audioCtx['state'] == 'suspended') {
        _audioCtx.callMethod('resume', []);
      }
    } catch (_) {}
  }

  /// Plays realistic mechanical starter motor crank sequence
  static void playStarterCrank() {
    try {
      _ensureContext();
      if (_audioCtx == null) return;

      final osc = _audioCtx.callMethod('createOscillator', []);
      final gain = _audioCtx.callMethod('createGain', []);
      final currentTime = _audioCtx['currentTime'] as num;

      osc['type'] = 'sawtooth';
      final freq = osc['frequency'];
      freq.callMethod('setValueAtTime', [45.0, currentTime]);
      freq.callMethod('exponentialRampToValueAtTime', [75.0, currentTime + 0.6]);

      final gainParam = gain['gain'];
      gainParam.callMethod('setValueAtTime', [0.25, currentTime]);
      gainParam.callMethod('exponentialRampToValueAtTime', [0.01, currentTime + 0.7]);

      osc.callMethod('connect', [gain]);
      gain.callMethod('connect', [_audioCtx['destination']]);

      osc.callMethod('start', [currentTime]);
      osc.callMethod('stop', [currentTime + 0.7]);
    } catch (_) {}
  }

  /// Starts real-time synthesized engine exhaust roar & idle rumble
  static void startEngineRumble(double rpm) {
    try {
      if (_isPlaying) stopAllEngineAudio();
      _ensureContext();
      if (_audioCtx == null) return;

      _mainGain = _audioCtx.callMethod('createGain', []);
      final currentTime = _audioCtx['currentTime'] as num;
      _mainGain['gain'].callMethod('setValueAtTime', [0.18, currentTime]);
      _mainGain.callMethod('connect', [_audioCtx['destination']]);

      final baseFreq = (rpm / 60.0) * 2.0;

      // 1. Base engine firing
      _oscBase = _audioCtx.callMethod('createOscillator', []);
      _oscBase['type'] = 'sawtooth';
      _oscBase['frequency'].callMethod('setValueAtTime', [baseFreq.clamp(30.0, 600.0), currentTime]);

      // 2. Sub-harmonic exhaust thud
      _oscSub = _audioCtx.callMethod('createOscillator', []);
      _oscSub['type'] = 'triangle';
      _oscSub['frequency'].callMethod('setValueAtTime', [(baseFreq * 0.5).clamp(20.0, 300.0), currentTime]);

      // 3. High-rev whine
      _oscHarmonic = _audioCtx.callMethod('createOscillator', []);
      _oscHarmonic['type'] = 'sine';
      _oscHarmonic!.callMethod('setValueAtTime', [(baseFreq * 3.5).clamp(80.0, 1800.0), currentTime]);

      _oscBase.callMethod('connect', [_mainGain]);
      _oscSub.callMethod('connect', [_mainGain]);
      _oscHarmonic.callMethod('connect', [_mainGain]);

      _oscBase.callMethod('start', []);
      _oscSub.callMethod('start', []);
      _oscHarmonic.callMethod('start', []);

      _isPlaying = true;
    } catch (_) {}
  }

  /// Modulates engine pitch and volume based on live RPM in real time
  static void updateEnginePitch(double rpm) {
    if (!_isPlaying || _audioCtx == null) return;
    try {
      final currentTime = _audioCtx['currentTime'] as num;
      final baseFreq = (rpm / 60.0) * 2.0;

      _oscBase?['frequency']?.callMethod('setTargetAtTime', [baseFreq.clamp(35.0, 650.0), currentTime, 0.05]);
      _oscSub?['frequency']?.callMethod('setTargetAtTime', [(baseFreq * 0.5).clamp(20.0, 350.0), currentTime, 0.05]);
      _oscHarmonic?['frequency']?.callMethod('setTargetAtTime', [(baseFreq * 3.5).clamp(90.0, 2200.0), currentTime, 0.05]);

      final gainFactor = (0.15 + (rpm / 15000.0) * 0.20).clamp(0.1, 0.4);
      _mainGain?['gain']?.callMethod('setTargetAtTime', [gainFactor, currentTime, 0.05]);
    } catch (_) {}
  }

  /// Stops all oscillators cleanly
  static void stopAllEngineAudio() {
    try {
      if (_oscBase != null) {
        _oscBase.callMethod('stop', []);
        _oscBase.callMethod('disconnect', []);
        _oscBase = null;
      }
      if (_oscSub != null) {
        _oscSub.callMethod('stop', []);
        _oscSub.callMethod('disconnect', []);
        _oscSub = null;
      }
      if (_oscHarmonic != null) {
        _oscHarmonic.callMethod('stop', []);
        _oscHarmonic.callMethod('disconnect', []);
        _oscHarmonic = null;
      }
      if (_mainGain != null) {
        _mainGain.callMethod('disconnect', []);
        _mainGain = null;
      }
      _isPlaying = false;
    } catch (_) {}
  }
}

*/