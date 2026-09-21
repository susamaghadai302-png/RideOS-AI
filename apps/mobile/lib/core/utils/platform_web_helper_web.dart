// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class PlatformWebHelperImpl {
  static void openUrl(String url) {
    try {
      html.window.open(url, '_blank');
    } catch (_) {}
  }

  static void speakText(String text, {String lang = 'en-US'}) {
    try {
      if (html.window.speechSynthesis != null) {
        final utterance = html.SpeechSynthesisUtterance(text);
        utterance.lang = lang;
        utterance.rate = 1.0;
        utterance.pitch = 1.0;
        utterance.volume = 1.0;
        html.window.speechSynthesis!.speak(utterance);
      }
    } catch (_) {}
  }

  static void cancelSpeech() {
    try {
      html.window.speechSynthesis?.cancel();
    } catch (_) {}
  }
}