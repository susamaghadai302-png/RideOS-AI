import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import '../../../ai_assistant/presentation/bloc/ai_assistant_event.dart';
import '../../../ai_assistant/presentation/bloc/ai_assistant_state.dart';
import '../bloc/voice_bloc.dart';
import '../../../../core/contracts/voice_models.dart';

class VoiceAssistantHudScreen extends StatefulWidget {
  const VoiceAssistantHudScreen({super.key});

  @override
  State<VoiceAssistantHudScreen> createState() => _VoiceAssistantHudScreenState();
}

class _VoiceAssistantHudScreenState extends State<VoiceAssistantHudScreen> {
  final TextEditingController _voiceInputController = TextEditingController(text: 'Navigate to nearest Petrol Pump');

  void _processVoiceInput() {
    LuxAudioHapticsService.mediumImpact();
    // Route manual text input directly to AI instead of faking Voice STT
    context.read<AiAssistantBloc>().add(SendAiPromptEvent(prompt: _voiceInputController.text));
  }

  void _triggerWakeWord() {
    LuxAudioHapticsService.heavyImpact();
    context.read<VoiceBloc>().add(StartVoiceListening());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<VoiceBloc, VoiceState>(
          listenWhen: (previous, current) =>
              previous.currentTranscript != current.currentTranscript &&
              current.currentTranscript != null &&
              current.currentTranscript!.isFinal,
          listener: (context, state) {
            // When voice returns a final transcript, forward to AI Assistant Bloc
            context.read<AiAssistantBloc>().add(SendAiPromptEvent(prompt: state.currentTranscript!.text));
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: RoadOSColors.deepSpaceBlack,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RoadOSColors.platinumWhite, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'JARVIS AI VOICE COPILOT',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: RoadOSColors.cyberCyan),
          ),
        ),
        body: CinematicBackground(
          child: CinematicBackground(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    // Glowing Animated Microphone Orb
                    BlocBuilder<VoiceBloc, VoiceState>(
                      builder: (context, state) {
                        final isListening = state.inputState == VoiceInputState.listening;
                        return GestureDetector(
                          onTap: isListening
                              ? () => context.read<VoiceBloc>().add(StopVoiceListening())
                              : _triggerWakeWord,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: isListening ? RoadOSGradients.hyperOrange : RoadOSGradients.brandCyan,
                              boxShadow: [
                                BoxShadow(
                                  color: isListening
                                      ? RoadOSColors.hyperOrange.withValues(alpha: 0.6)
                                      : RoadOSColors.cyberCyan.withValues(alpha: 0.6),
                                  blurRadius: 30,
                                  spreadRadius: 8,
                                ),
                              ],
                            ),
                            child: Icon(
                              isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                              color: Colors.black,
                              size: 56,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    BlocBuilder<VoiceBloc, VoiceState>(
                      builder: (context, state) {
                        String text = 'TAP TO SPEAK (Manual Trigger)';
                        if (state.inputState == VoiceInputState.listening) text = 'LISTENING...';
                        if (state.inputState == VoiceInputState.processing) text = 'PROCESSING AUDIO...';
                        return Text(
                          text,
                          style: const TextStyle(
                              color: RoadOSColors.cyberCyan, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Speech Input Test Field
                    RoadOSCard(
                      child: Column(
                        children: [
                          TextField(
                            controller: _voiceInputController,
                            style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Voice Command Input',
                              prefixIcon: const Icon(Icons.record_voice_over_rounded),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.send_rounded, color: RoadOSColors.cyberCyan),
                                onPressed: _processVoiceInput,
                              ),
                              filled: true,
                              fillColor: Colors.black45,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onSubmitted: (_) => _processVoiceInput(),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            children: [
                              'Navigate Home',
                              'Nearest Petrol Pump',
                              'Nearest EV Charger',
                              'Nearest Hospital',
                              'Call Emergency',
                              'Stop Navigation',
                            ].map((cmd) {
                              return ActionChip(
                                label: Text(cmd, style: const TextStyle(fontSize: 10, color: RoadOSColors.platinumWhite)),
                                backgroundColor: Colors.black45,
                                onPressed: () {
                                  _voiceInputController.text = cmd;
                                  _processVoiceInput();
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Result Output Card from AI Bloc
                    Expanded(
                      child: BlocBuilder<AiAssistantBloc, AiAssistantState>(
                        builder: (context, aiState) {
                          if (aiState is AiAssistantLoadingState) {
                            return const RoadOSCard(
                              child: Center(
                                child: CircularProgressIndicator(color: RoadOSColors.cyberCyan),
                              ),
                            );
                          } else if (aiState is AiAssistantLoadedState && aiState.messages.isNotEmpty) {
                            final lastMsg = aiState.messages.last;
                            return RoadOSCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.smart_toy_rounded, color: RoadOSColors.apexEmerald, size: 20),
                                      SizedBox(width: 8),
                                      Text('AI COPILOT RESPONSE',
                                          style: TextStyle(
                                              color: RoadOSColors.apexEmerald,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '"${lastMsg.text}"',
                                    style: const TextStyle(
                                        color: RoadOSColors.platinumWhite,
                                        fontSize: 16,
                                        height: 1.4,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'Command parsed via Tier 5 Intent Resolver',
                                    style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            return const Spacer();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
