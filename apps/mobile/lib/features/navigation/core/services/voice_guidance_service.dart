import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import '../../../../core/utils/platform_web_helper.dart';

enum VoicePack { jarvisAi, apexRacer, cyberSynth, britishTourer }

enum NavigationLanguage {
  english('English', 'en-US', '🇬🇧'),
  hindi('Hindi (हिंदी)', 'hi-IN', '🇮🇳'),
  odia('Odia (ଓଡ଼ିଆ)', 'hi-IN', '🇮🇳'); // Indian locale speech fallback

  final String label;
  final String code;
  final String flag;
  const NavigationLanguage(this.label, this.code, this.flag);
}

class VoiceGuidanceService {
  static final VoiceGuidanceService _instance = VoiceGuidanceService._internal();
  factory VoiceGuidanceService() => _instance;
  VoiceGuidanceService._internal();

  bool isMuted = false;
  VoicePack currentVoicePack = VoicePack.jarvisAi;
  NavigationLanguage currentLanguage = NavigationLanguage.english;
  String? _lastAnnouncement;

  // Voice Search / Speech Recognition State
  bool isListening = false;

  /// Speaks turn-by-turn guidance aloud via Web/Platform SpeechSynthesis
  Future<void> speak(String text) async {
    if (isMuted || text.isEmpty) return;
    if (_lastAnnouncement == text) return;

    _lastAnnouncement = text;
    final prefix = _getVoicePackPrefix(currentVoicePack);
    final langLabel = currentLanguage.label;
    debugPrint('[$prefix - $langLabel] 🔊 "$text"');

    PlatformWebHelper.speakText(text, lang: currentLanguage.code);
  }

  Future<void> speakGuidance(String text) async {
    return speak(text);
  }

  void setVoicePack(VoicePack pack) {
    currentVoicePack = pack;
  }

  void setLanguage(NavigationLanguage language) {
    currentLanguage = language;
    speak(getGreetingMessage());
  }

  void toggleMute() {
    isMuted = !isMuted;
    if (isMuted) {
      PlatformWebHelper.cancelSpeech();
    }
  }

  final SpeechToText _speechToText = SpeechToText();

  /// Starts live voice recognition listener for voice search
  Future<bool> startVoiceSearch({
    required Function(String recognizedText) onResult,
    required Function(String error) onError,
  }) async {
    isListening = true;
    
    bool available = await _speechToText.initialize(
      onError: (val) {
        isListening = false;
        onError(val.errorMsg);
      },
      onStatus: (val) {
        if (val == 'done' || val == 'notListening') {
          isListening = false;
        }
      },
    );

    if (available) {
      _speechToText.listen(
        onResult: (SpeechRecognitionResult result) {
          if (result.finalResult) {
            isListening = false;
            onResult(result.recognizedWords);
          }
        },
        localeId: currentLanguage.code,
        cancelOnError: true,
        partialResults: false,
      );
      return true;
    } else {
      isListening = false;
      onError('Speech recognition not available');
      return false;
    }
  }

  void stopListening() {
    isListening = false;
    _speechToText.stop();
  }

  String getGreetingMessage() {
    switch (currentLanguage) {
      case NavigationLanguage.hindi:
        return 'राइडओएस नेविगेशन सक्रिय है। सुरक्षित यात्रा करें।';
      case NavigationLanguage.odia:
        return 'ରାଇଡଓଏସ ନେଭିଗେସନ ସକ୍ରିୟ ଅଛି। ଶୁଭ ଯାତ୍ରା।';
      case NavigationLanguage.english:
        return 'RideOS Navigation active. Drive safely.';
    }
  }

  String getTurnInstruction({
    required String maneuver,
    required String distance,
    required String roadName,
  }) {
    switch (currentLanguage) {
      case NavigationLanguage.hindi:
        switch (maneuver.toUpperCase()) {
          case 'TURN_RIGHT':
            return '$distance में $roadName पर दाएं मुड़ें';
          case 'TURN_LEFT':
            return '$distance में $roadName पर बाएं मुड़ें';
          case 'U_TURN':
            return '$distance में यू-टर्न लें';
          case 'ARRIVE':
            return 'आप अपनी मंजिल पर पहुंच गए हैं';
          default:
            return '$distance में $roadName की ओर सीधे चलें';
        }
      case NavigationLanguage.odia:
        switch (maneuver.toUpperCase()) {
          case 'TURN_RIGHT':
            return '$distance ପରେ $roadName ରେ ଡାହାଣକୁ ବୁଲନ୍ତୁ';
          case 'TURN_LEFT':
            return '$distance ପରେ $roadName ରେ ବାମକୁ ବୁଲନ୍ତୁ';
          case 'U_TURN':
            return '$distance ପରେ ୟୁ-ଟର୍ନ ନିଅନ୍ତୁ';
          case 'ARRIVE':
            return 'ଆପଣ ଆପଣଙ୍କ ଗନ୍ତବ୍ୟ ସ୍ଥଳରେ ପହଞ୍ଚିଗଲେ';
          default:
            return '$distance ପରେ $roadName ଆଡକୁ ସିଧା ଯାଆନ୍ତୁ';
        }
      case NavigationLanguage.english:
        switch (maneuver.toUpperCase()) {
          case 'TURN_RIGHT':
            return 'In $distance, turn right onto $roadName';
          case 'TURN_LEFT':
            return 'In $distance, turn left onto $roadName';
          case 'U_TURN':
            return 'In $distance, make a U-turn';
          case 'ARRIVE':
            return 'You have arrived at your destination';
          default:
            return 'In $distance, continue straight onto $roadName';
        }
    }
  }

  String getRerouteMessage() {
    switch (currentLanguage) {
      case NavigationLanguage.hindi:
        return 'नया रास्ता चुना जा रहा है...';
      case NavigationLanguage.odia:
        return 'ନୂତନ ରାସ୍ତା ଖୋଜାଯାଉଛି...';
      case NavigationLanguage.english:
        return 'Recalculating route...';
    }
  }

  String getHazardWarning(String hazard) {
    switch (currentLanguage) {
      case NavigationLanguage.hindi:
        return 'सावधानी: आगे $hazard की सूचना है';
      case NavigationLanguage.odia:
        return 'ସାବଧାନ: ଆଗରେ $hazard ଅଛି';
      case NavigationLanguage.english:
        return 'Caution: $hazard reported ahead';
    }
  }

  String _getVoicePackPrefix(VoicePack pack) {
    switch (pack) {
      case VoicePack.jarvisAi:
        return 'Jarvis AI';
      case VoicePack.apexRacer:
        return 'Apex Voice';
      case VoicePack.cyberSynth:
        return 'Cyber Synth';
      case VoicePack.britishTourer:
        return 'Tourer Guidance';
    }
  }
}
