import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/contracts/voice_gateway.dart';
import '../../../../core/contracts/voice_models.dart';

class PlatformVoiceInputAdapter implements VoiceGateway {
  final SpeechToText _speechToText = SpeechToText();
  final StreamController<VoiceInputState> _stateController = StreamController<VoiceInputState>.broadcast();
  final StreamController<VoiceTranscript> _transcriptController = StreamController<VoiceTranscript>.broadcast();
  
  VoiceInputState _currentState = VoiceInputState.idle;
  bool _isInitialized = false;

  PlatformVoiceInputAdapter() {
    _emitState(VoiceInputState.idle);
  }

  @override
  Stream<VoiceInputState> get state => _stateController.stream;

  @override
  Stream<VoiceTranscript> get onTranscript => _transcriptController.stream;

  void _emitState(VoiceInputState newState) {
    if (_currentState != newState) {
      _currentState = newState;
      _stateController.add(newState);
    }
  }

  Future<bool> _initSpeech() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speechToText.initialize(
        onError: (errorNotification) {
          debugPrint('STT Error: ${errorNotification.errorMsg}');
          if (errorNotification.errorMsg.contains('error_no_match')) {
             // Silence, no speech detected. Just return to idle.
             _emitState(VoiceInputState.idle);
          } else {
             _emitState(VoiceInputState.error);
          }
        },
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            if (_currentState == VoiceInputState.listening) {
              _emitState(VoiceInputState.idle);
            }
          } else if (status == 'listening') {
             _emitState(VoiceInputState.listening);
          }
        },
      );
      return _isInitialized;
    } catch (e) {
      debugPrint('Failed to initialize speech: $e');
      return false;
    }
  }

  @override
  Future<void> startListening(VoiceRequest request) async {
    if (_currentState == VoiceInputState.listening || _currentState == VoiceInputState.processing) {
      return;
    }

    _emitState(VoiceInputState.permissionRequired);
    
    // Check permissions safely across platforms
    if (!kIsWeb) {
      final permissionStatus = await Permission.microphone.request();
      if (permissionStatus.isDenied || permissionStatus.isPermanentlyDenied) {
        debugPrint('Microphone permission denied');
        _emitState(VoiceInputState.error);
        return;
      }
    }

    final initSuccess = await _initSpeech();
    if (!initSuccess) {
      debugPrint('Speech recognition unavailable');
      _emitState(VoiceInputState.error);
      return;
    }

    _emitState(VoiceInputState.listening);
    
    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        _transcriptController.add(
          VoiceTranscript(
            text: result.recognizedWords,
            isFinal: result.finalResult,
            confidence: result.confidence > 0 ? result.confidence : 1.0,
          ),
        );
        
        if (result.finalResult) {
          _emitState(VoiceInputState.processing);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_currentState == VoiceInputState.processing) {
              _emitState(VoiceInputState.idle);
            }
          });
        }
      },
      listenOptions: SpeechListenOptions(
        localeId: request.locale,
        cancelOnError: true,
        partialResults: true,
      ),
    );
  }

  @override
  Future<void> stopListening() async {
    if (_currentState == VoiceInputState.listening) {
       await _speechToText.stop();
       _emitState(VoiceInputState.idle);
    }
  }

  @override
  Future<void> cancelListening() async {
    if (_currentState == VoiceInputState.listening) {
       await _speechToText.cancel();
       _emitState(VoiceInputState.idle);
    }
  }

  void dispose() {
    _stateController.close();
    _transcriptController.close();
  }
}
