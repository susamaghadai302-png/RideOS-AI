import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../ai_assistant/presentation/screens/ai_assistant_screen.dart';
import '../../../voice_assistant/core/services/voice_command_engine.dart';
import '../../../garage/presentation/screens/luxury_garage_showroom_screen.dart';
import '../../../navigation/presentation/screens/three_d_navigation_screen.dart';
import '../../../obd_tpms/presentation/screens/obd_diagnostics_screen.dart';

/// Floating Corner Voice AI Assistant Widget for the Home Dashboard.
///
/// Features a compact cyberpunk glowing capsule in the corner that expands
/// into a floating glass mini-chat terminal with real-time AI responses,
/// animated voice waveforms, quick command chips, and 1-tap full-screen expansion.
class FloatingCornerVoiceAiWidget extends StatefulWidget {
  const FloatingCornerVoiceAiWidget({super.key});

  @override
  State<FloatingCornerVoiceAiWidget> createState() => _FloatingCornerVoiceAiWidgetState();
}

class _FloatingCornerVoiceAiWidgetState extends State<FloatingCornerVoiceAiWidget>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  bool _isListening = false;
  bool _isAiResponding = false;
  final TextEditingController _promptController = TextEditingController();
  final VoiceCommandEngine _voiceEngine = VoiceCommandEngine();

  late AnimationController _waveController;
  final List<Map<String, String>> _quickChatLog = [
    {
      'sender': 'RIDEO AI',
      'text': 'Voice AI online. "Hey Rideo" listening. How can I assist your ride?',
    },
  ];

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    _promptController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    LuxAudioHapticsService.mediumImpact();
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  void _sendPrompt(String prompt) {
    final text = prompt.trim();
    if (text.isEmpty) return;

    LuxAudioHapticsService.lightImpact();
    _promptController.clear();

    setState(() {
      _quickChatLog.add({'sender': 'RIDER', 'text': text});
      _isAiResponding = true;
      _isListening = false;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final parsed = _voiceEngine.parseCommand(text);

      setState(() {
        _isAiResponding = false;
        _quickChatLog.add({
          'sender': 'RIDEO AI',
          'text': parsed.aiResponse,
        });
      });

      // Intent routing
      _routeCommand(parsed.commandType);
    });
  }

  void _routeCommand(VoiceCommandType type) {
    switch (type) {
      case VoiceCommandType.openGarage:
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            Navigator.push(context, premiumRoute(const LuxuryGarageShowroomScreen()));
          }
        });
        break;
      case VoiceCommandType.startNavigation:
      case VoiceCommandType.navigateHome:
      case VoiceCommandType.navigateWork:
      case VoiceCommandType.findPetrolPump:
      case VoiceCommandType.findEvCharger:
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            Navigator.push(context, premiumRoute(const ThreeDNavigationScreen()));
          }
        });
        break;
      case VoiceCommandType.showBikeHealth:
        Future.delayed(const Duration(milliseconds: 700), () {
          if (mounted) {
            Navigator.push(context, premiumRoute(const ObdDiagnosticsScreen()));
          }
        });
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      constraints: BoxConstraints(
        maxWidth: _isExpanded ? 340 : 190,
      ),
      child: _isExpanded ? _buildExpandedMiniChat() : _buildCollapsedCapsule(),
    );
  }

  /// Compact Glowing Corner Capsule
  Widget _buildCollapsedCapsule() {
    return GestureDetector(
      onTap: _toggleExpanded,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xE6080C1A),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.7),
            width: 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
              blurRadius: 16,
              spreadRadius: -2,
            ),
            BoxShadow(
              color: RoadOSColors.cyberCyan.withValues(alpha: 0.15),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing AI Orb Icon with Waveform
            Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LuxGradients.cyberPurple,
              ),
              child: const Center(
                child: Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 13),
              ),
            ),
            const SizedBox(width: 7),
            // Text Label
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'RIDEO AI',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: RoadOSColors.apexEmerald,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI READY',
                      style: GoogleFonts.outfit(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: RoadOSColors.cyberCyan,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 6),
            // Animated Audio Waveform Bars
            AnimatedBuilder(
              animation: _waveController,
              builder: (context, _) {
                final v = _waveController.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildWaveBar(5 + v * 7, RoadOSColors.cyberCyan),
                    const SizedBox(width: 2),
                    _buildWaveBar(12 - v * 5, const Color(0xFF8B5CF6)),
                    const SizedBox(width: 2),
                    _buildWaveBar(7 + v * 5, RoadOSColors.cyberCyan),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveBar(double height, Color color) {
    return Container(
      width: 2.2,
      height: height.clamp(4.0, 16.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  /// Expanded Floating Glass Mini Chat Window
  Widget _buildExpandedMiniChat() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xF2070B18),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                blurRadius: 28,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LuxGradients.cyberPurple,
                        ),
                        child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RIDEO AI ASSISTANT',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            _isAiResponding ? 'AI REASONING...' : 'LIVE VOICE COPILOT',
                            style: GoogleFonts.outfit(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                              color: _isAiResponding ? RoadOSColors.hyperOrange : RoadOSColors.cyberCyan,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      // Full screen expand
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.open_in_full_rounded, color: RoadOSColors.cyberCyan, size: 16),
                        tooltip: 'Open Full AI Screen',
                        onPressed: () {
                          LuxAudioHapticsService.lightImpact();
                          Navigator.push(context, premiumRoute(const AiAssistantScreen()));
                        },
                      ),
                      const SizedBox(width: 10),
                      // Close / Minimize
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(Icons.close_rounded, color: RoadOSColors.textMuted, size: 18),
                        onPressed: _toggleExpanded,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Divider(color: Color(0x331F293D), height: 1),
              const SizedBox(height: 10),

              // Chat Message Stream Box
              Container(
                constraints: const BoxConstraints(maxHeight: 140),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _quickChatLog.length,
                  itemBuilder: (context, index) {
                    final msg = _quickChatLog[index];
                    final isAi = msg['sender'] == 'RIDEO AI';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isAi ? Icons.auto_awesome_rounded : Icons.person_rounded,
                            size: 12,
                            color: isAi ? const Color(0xFF8B5CF6) : RoadOSColors.cyberCyan,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              msg['text']!,
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.35,
                                color: isAi ? RoadOSColors.platinumWhite : RoadOSColors.cyberCyan,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Quick Action Chips
              const SizedBox(height: 6),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildMiniChip('Find Petrol', Icons.local_gas_station_rounded),
                    _buildMiniChip('Show Health', Icons.favorite_rounded),
                    _buildMiniChip('Navigate Home', Icons.home_rounded),
                    _buildMiniChip('Open Garage', Icons.garage_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Input Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F1528),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(
                        _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                        color: _isListening ? RoadOSColors.hyperOrange : RoadOSColors.cyberCyan,
                        size: 18,
                      ),
                      onPressed: () {
                        LuxAudioHapticsService.lightImpact();
                        setState(() => _isListening = !_isListening);
                        if (_isListening) {
                          _sendPrompt('Show bike health');
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _promptController,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                        onSubmitted: _sendPrompt,
                        decoration: InputDecoration(
                          hintText: 'Ask Rideo AI or tap chip...',
                          hintStyle: TextStyle(
                            color: RoadOSColors.textMuted.withValues(alpha: 0.6),
                            fontSize: 10.5,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 6),
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(Icons.arrow_upward_rounded, color: const Color(0xFF8B5CF6), size: 18),
                      onPressed: () => _sendPrompt(_promptController.text),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip(String label, IconData icon) {
    return GestureDetector(
      onTap: () => _sendPrompt(label),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 10, color: RoadOSColors.cyberCyan),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: RoadOSColors.platinumWhite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
