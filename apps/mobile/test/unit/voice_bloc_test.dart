import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/core/contracts/voice_models.dart';
import '../core/fakes/fake_voice_input_adapter.dart';
import 'package:rideos_mobile/features/voice_assistant/presentation/bloc/voice_bloc.dart';

void main() {
  group('VoiceBloc Tests', () {
    late FakeVoiceInputAdapter mockAdapter;
    late VoiceBloc bloc;

    setUp(() {
      mockAdapter = FakeVoiceInputAdapter();
      bloc = VoiceBloc(gateway: mockAdapter);
    });

    tearDown(() async {
      await bloc.close();
      mockAdapter.dispose();
    });

    test('initial state is idle', () {
      expect(bloc.state.inputState, VoiceInputState.idle);
      expect(bloc.state.currentTranscript, isNull);
    });

    test('StartVoiceListening triggers adapter and updates state', () async {
      bloc.add(StartVoiceListening());
      
      await Future.delayed(const Duration(milliseconds: 600));
      
      expect(bloc.state.inputState, VoiceInputState.listening);
    });

    test('SimulateResult updates transcript', () async {
      bloc.add(StartVoiceListening());
      await Future.delayed(const Duration(milliseconds: 600));
      
      mockAdapter.simulateResult('Find gas', isFinal: true);
      await Future.delayed(const Duration(milliseconds: 100));
      
      expect(bloc.state.currentTranscript, isNotNull);
      expect(bloc.state.currentTranscript!.text, 'Find gas');
      expect(bloc.state.currentTranscript!.isFinal, true);
    });
  });
}
