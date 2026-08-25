import 'package:flutter/material.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../core/services/voice_command_engine.dart';

class VoiceAssistantHudScreen extends StatefulWidget {
  const VoiceAssistantHudScreen({super.key});

  @override
  State<VoiceAssistantHudScreen> createState() => _VoiceAssistantHudScreenState();
}

class _VoiceAssistantHudScreenState extends State<VoiceAssistantHudScreen> {
  final VoiceCommandEngine _engine = VoiceCommandEngine();
  final TextEditingController _voiceInputController = TextEditingController(text: 'Navigate to nearest Petrol Pump');
  VoiceCommandResult? _lastResult;
  bool _isListening = false;

  void _processVoiceInput() {
    LuxAudioHapticsService.mediumImpact();
    setState(() {
      _isListening = false;
      _lastResult = _engine.parseCommand(_voiceInputController.text);
    });
  }

  void _triggerWakeWord() {
    LuxAudioHapticsService.heavyImpact();
    setState(() {
      _isListening = true;
      _voiceInputController.text = 'Hey RideOS, navigate Home';
      _lastResult = _engine.parseCommand('navigate home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      body: CinematicBackground(child: CinematicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Glowing Animated Microphone Orb
                GestureDetector(
                  onTap: _triggerWakeWord,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: _isListening ? RoadOSGradients.hyperOrange : RoadOSGradients.brandCyan,
                      boxShadow: [
                        BoxShadow(
                          color: _isListening ? RoadOSColors.hyperOrange.withValues(alpha: 0.6) : RoadOSColors.cyberCyan.withValues(alpha: 0.6),
                          blurRadius: 30,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                      color: Colors.black,
                      size: 56,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isListening ? 'LISTENING FOR VOICE COMMAND...' : 'SAY "HEY RIDEOS"',
                  style: const TextStyle(color: RoadOSColors.cyberCyan, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5),
                ),
                const SizedBox(height: 24),

                // Speech Input Test Field
                RoadOSCard(
                  // padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      TextField(
                        controller: _voiceInputController,
                        style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          labelText: 'Voice Command Input',
                          prefixIcon: Icon(Icons.record_voice_over_rounded),
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

                // Result Output Card
                if (_lastResult != null)
                  Expanded(
                    child: RoadOSCard(
                      // padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.smart_toy_rounded, color: RoadOSColors.apexEmerald, size: 20),
                              SizedBox(width: 8),
                              Text('AI COPILOT RESPONSE', style: TextStyle(color: RoadOSColors.apexEmerald, fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '"${_lastResult!.aiResponse}"',
                            style: const TextStyle(color: RoadOSColors.platinumWhite, fontSize: 16, height: 1.4, fontWeight: FontWeight.w600),
                          ),
                          const Spacer(),
                          Text(
                            'Command parsed: ${_lastResult!.commandType.name} (Offline Engine Active)',
                            style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const Spacer(),
              ],
            ),
          ),
        ),
      )),
    );
  }
}
