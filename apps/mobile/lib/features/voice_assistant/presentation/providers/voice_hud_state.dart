import 'package:equatable/equatable.dart';

enum VoiceHudStatus { listening, processing, speaking, idle }

class VoiceHudState extends Equatable {
  final VoiceHudStatus status;
  final String? lastTranscript;
  final String? activeIntent;
  final bool isBluetoothHeadsetConnected;

  const VoiceHudState({
    this.status = VoiceHudStatus.idle,
    this.lastTranscript,
    this.activeIntent,
    this.isBluetoothHeadsetConnected = true,
  });

  VoiceHudState copyWith({
    VoiceHudStatus? status,
    String? lastTranscript,
    String? activeIntent,
    bool? isBluetoothHeadsetConnected,
  }) {
    return VoiceHudState(
      status: status ?? this.status,
      lastTranscript: lastTranscript ?? this.lastTranscript,
      activeIntent: activeIntent ?? this.activeIntent,
      isBluetoothHeadsetConnected:
          isBluetoothHeadsetConnected ?? this.isBluetoothHeadsetConnected,
    );
  }

  @override
  List<Object?> get props => [
        status,
        lastTranscript,
        activeIntent,
        isBluetoothHeadsetConnected,
      ];
}
