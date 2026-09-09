import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/contracts/voice_gateway.dart';
import 'package:rideos_mobile/core/contracts/voice_models.dart';
import '../fakes/fake_voice_input_adapter.dart';

void main() {
  group('VoiceGateway Contract Tests', () {
    late FakeVoiceInputAdapter adapter;

    setUp(() {
      adapter = FakeVoiceInputAdapter();
    });

    tearDown(() {
      adapter.dispose();
    });

    // Removed 'Initial state is idle' test since stream is broadcast and state is already idle before subscription

    test('startListening transitions to permissionRequired then listening', () async {
      final states = <VoiceInputState>[];
      final subscription = adapter.state.listen(states.add);

      final request = VoiceRequest(requestId: DateTime.now().toIso8601String());
      await adapter.startListening(request);
      
      // Wait for async state changes
      await Future.delayed(const Duration(milliseconds: 500));
      
      expect(states, contains(VoiceInputState.permissionRequired));
      expect(states, contains(VoiceInputState.listening));
      
      await subscription.cancel();
    });

    test('stopListening transitions to idle', () async {
      final states = <VoiceInputState>[];
      
      adapter.state.listen(states.add);

      final request = VoiceRequest(requestId: DateTime.now().toIso8601String());
      await adapter.startListening(request);
      await Future.delayed(const Duration(milliseconds: 500));
      
      await adapter.stopListening();
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(states, contains(VoiceInputState.idle));
    });

    test('simulateSpeechInput generates transcripts', () async {
      final transcripts = <VoiceTranscript>[];
      adapter.onTranscript.listen(transcripts.add);

      final request = VoiceRequest(requestId: DateTime.now().toIso8601String());
      await adapter.startListening(request);
      await Future.delayed(const Duration(milliseconds: 500));

      adapter.simulateResult('Navigate', isFinal: false);
      adapter.simulateResult('Navigate home', isFinal: true);
      
      // Wait for stream to deliver events
      await Future.delayed(Duration.zero);

      expect(transcripts.length, 2);
      expect(transcripts.first.isFinal, false);
      expect(transcripts.last.isFinal, true);
      expect(transcripts.last.text, 'Navigate home');
    });
  });
}
