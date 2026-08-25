import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'voice_hud_state.dart';

class VoiceHudNotifier extends StateNotifier<VoiceHudState> {
  VoiceHudNotifier() : super(const VoiceHudState());

  void startListening() {
    state = state.copyWith(status: VoiceHudStatus.listening);
  }

  Future<void> processVoiceInput(String transcript) async {
    state = state.copyWith(
      status: VoiceHudStatus.processing,
      lastTranscript: transcript,
    );

    await Future.delayed(const Duration(milliseconds: 500));

    String intent = 'UNKNOWN';
    if (transcript.toLowerCase().contains('fuel') || transcript.toLowerCase().contains('gas')) {
      intent = 'FIND_FUEL';
    } else if (transcript.toLowerCase().contains('sos')) {
      intent = 'TRIGGER_SOS';
    }

    state = state.copyWith(
      status: VoiceHudStatus.speaking,
      activeIntent: intent,
    );

    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(status: VoiceHudStatus.idle);
  }
}

final voiceHudNotifierProvider =
    StateNotifierProvider<VoiceHudNotifier, VoiceHudState>((ref) {
  return VoiceHudNotifier();
});
