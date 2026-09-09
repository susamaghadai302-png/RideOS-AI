import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/contracts/text_to_speech_gateway.dart';

class PlatformTextToSpeechAdapter implements TextToSpeechGateway {
  final FlutterTts _flutterTts = FlutterTts();
  final StreamController<bool> _isSpeakingController = StreamController<bool>.broadcast();
  bool _isCurrentlySpeaking = false;

  PlatformTextToSpeechAdapter() {
    _initTts();
  }

  Future<void> _initTts() async {
    _flutterTts.setStartHandler(() {
      _setSpeakingState(true);
    });

    _flutterTts.setCompletionHandler(() {
      _setSpeakingState(false);
    });

    _flutterTts.setErrorHandler((msg) {
      debugPrint('TTS Error: $msg');
      _setSpeakingState(false);
    });
    
    _flutterTts.setCancelHandler(() {
      _setSpeakingState(false);
    });
  }

  void _setSpeakingState(bool state) {
    if (_isCurrentlySpeaking != state) {
      _isCurrentlySpeaking = state;
      _isSpeakingController.add(state);
    }
  }

  @override
  Stream<bool> get isSpeaking => _isSpeakingController.stream;

  @override
  Future<void> speak(String text) async {
    if (text.isEmpty) return;
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
      _setSpeakingState(false);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (e) {
      debugPrint('TTS stop failed: $e');
    } finally {
      _setSpeakingState(false);
    }
  }
}
