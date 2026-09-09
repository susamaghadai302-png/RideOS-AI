import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/contracts/voice_gateway.dart';
import '../../../../core/contracts/voice_models.dart';
import 'voice_event.dart';
import 'voice_state.dart';

export 'voice_event.dart';
export 'voice_state.dart';

class VoiceBloc extends Bloc<VoiceEvent, VoiceState> {
  final VoiceGateway gateway;
  StreamSubscription? _stateSubscription;
  StreamSubscription? _transcriptSubscription;

  VoiceBloc({required this.gateway}) : super(const VoiceState()) {
    on<StartVoiceListening>(_onStartListening);
    on<StopVoiceListening>(_onStopListening);
    on<CancelVoiceListening>(_onCancelListening);
    on<VoiceStateUpdated>(_onStateUpdated);
    on<VoiceTranscriptUpdated>(_onTranscriptUpdated);

    _stateSubscription = gateway.state.listen((s) {
      add(VoiceStateUpdated(s));
    });

    _transcriptSubscription = gateway.onTranscript.listen((t) {
      add(VoiceTranscriptUpdated(t));
    });
  }

  Future<void> _onStartListening(StartVoiceListening event, Emitter<VoiceState> emit) async {
    try {
      final req = VoiceRequest(requestId: DateTime.now().toIso8601String());
      await gateway.startListening(req);
    } catch (e) {
      emit(state.copyWith(
        inputState: VoiceInputState.error,
        error: VoiceRecognitionError(type: VoiceErrorType.unknown, message: e.toString()),
      ));
    }
  }

  Future<void> _onStopListening(StopVoiceListening event, Emitter<VoiceState> emit) async {
    await gateway.stopListening();
  }

  Future<void> _onCancelListening(CancelVoiceListening event, Emitter<VoiceState> emit) async {
    await gateway.cancelListening();
  }



  void _onStateUpdated(VoiceStateUpdated event, Emitter<VoiceState> emit) {
    if (event.inputState == VoiceInputState.idle || event.inputState == VoiceInputState.error) {
      // Clear transcript on terminal states
      emit(state.copyWith(inputState: event.inputState, currentTranscript: null));
    } else {
      emit(state.copyWith(inputState: event.inputState));
    }
  }

  void _onTranscriptUpdated(VoiceTranscriptUpdated event, Emitter<VoiceState> emit) {
    emit(state.copyWith(currentTranscript: event.transcript));
  }

  @override
  Future<void> close() {
    _stateSubscription?.cancel();
    _transcriptSubscription?.cancel();
    return super.close();
  }
}
