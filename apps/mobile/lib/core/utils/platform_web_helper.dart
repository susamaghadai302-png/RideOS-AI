import 'platform_web_helper_stub.dart'
    if (dart.library.html) 'platform_web_helper_web.dart';

abstract class PlatformWebHelper {
  static void openUrl(String url) => PlatformWebHelperImpl.openUrl(url);
  static void speakText(String text, {String lang = 'en-US'}) =>
      PlatformWebHelperImpl.speakText(text, lang: lang);
  static void cancelSpeech() => PlatformWebHelperImpl.cancelSpeech();
}
