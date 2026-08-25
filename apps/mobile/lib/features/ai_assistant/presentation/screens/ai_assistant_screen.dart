import 'package:flutter/material.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/widgets/roados_visual_environment.dart';
import '../../../garage/presentation/screens/luxury_garage_showroom_screen.dart';
import '../../../navigation/presentation/screens/three_d_navigation_screen.dart';
import '../../../obd_tpms/presentation/screens/obd_diagnostics_screen.dart';
import '../../../voice_assistant/core/services/voice_command_engine.dart';
import '../widgets/ai_assistant_widgets.dart';
import '../../../../core/design_system/premium_navigation.dart';

/// Voice AI Interaction State Machine
enum VoiceAiState {
  idle,
  listening,
  processing,
  thinking,
  responding,
  error,
  offline,
}

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final VoiceCommandEngine _voiceEngine = VoiceCommandEngine();
  final TextEditingController _textController = TextEditingController();

  VoiceAiState _aiState = VoiceAiState.listening;
  bool _isTtsActive = true;

  final List<Map<String, String>> _messages = [
    {
      'sender': 'RIDEO AI',
      'text': 'Greetings Rider! Voice active. "Hey Rideo" wake-word listening. Telematics show 82% oil life & 36 PSI front TPMS. How can I assist your ride today?',
      'time': 'Just now',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _handleUserPrompt(String input) {
    final prompt = input.trim();
    if (prompt.isEmpty) return;

    LuxAudioHapticsService.mediumImpact();
    _textController.clear();

    setState(() {
      _aiState = VoiceAiState.thinking;
      _messages.insert(0, {
        'sender': 'RIDER',
        'text': prompt,
        'time': 'Just now',
      });
    });

    // Simulate conversational AI reasoning & intent routing delay
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final result = _voiceEngine.parseCommand(prompt);

      setState(() {
        _aiState = VoiceAiState.responding;
        _messages.insert(0, {
          'sender': 'RIDEO AI',
          'text': result.aiResponse,
          'time': 'Just now',
        });
      });

      // App Action Navigation Router
      _executeAppAction(result.commandType);

      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() => _aiState = VoiceAiState.listening);
        }
      });
    });
  }

  void _executeAppAction(VoiceCommandType commandType) {
    switch (commandType) {
      case VoiceCommandType.openGarage:
        Future.delayed(const Duration(milliseconds: 800), () {
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
      case VoiceCommandType.findHospital:
      case VoiceCommandType.findScenicRoad:
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.push(context, premiumRoute(const ThreeDNavigationScreen()));
          }
        });
        break;
      case VoiceCommandType.showBikeHealth:
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            Navigator.push(context, premiumRoute(const ObdDiagnosticsScreen()));
          }
        });
        break;
      default:
        break;
    }
  }

  void _clearChatHistory() {
    LuxAudioHapticsService.selectionClick();
    setState(() {
      _messages.clear();
      _messages.add({
        'sender': 'RIDEO AI',
        'text': 'Conversation context cleared. How can I assist your ride now?',
        'time': 'Just now',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RoadOSVisualEnvironment(
        environmentType: RoadOSEnvironmentType.voiceAi,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // TabBar Header attached directly below TopBar
              Container(
                color: const Color(0x990A0F1E),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: const Color(0xFF8B5CF6),
                  labelColor: const Color(0xFF8B5CF6),
                  unselectedLabelColor: RoadOSColors.textMuted,
                  labelStyle: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
                  tabs: const [
                    Tab(text: 'VOICE AI'),
                    Tab(text: 'MAINTENANCE'),
                    Tab(text: 'RIDE ANALYTICS'),
                    Tab(text: 'TRIP PLANNER'),
                    Tab(text: 'NOTIFICATIONS'),
                    Tab(text: 'LEADERBOARD'),
                  ],
                ),
              ),

              // TabBarView Content Pages
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: ChatGPT-Class Voice AI & Conversation
                    _buildConversationalVoiceTab(),

                    // Tab 2: Predictive Maintenance
                    _buildMaintenanceTab(),

                    // Tab 3: Ride Analytics & Intelligence
                    _buildRideAnalyticsTab(),

                    // Tab 4: Smart Trip Planner
                    _buildTripPlannerTab(),

                    // Tab 5: AI Notifications
                    _buildNotificationsTab(),

                    // Tab 6: Rider Profile & Leaderboard
                    _buildLeaderboardTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ChatGPT-Class Conversational Voice AI View
  Widget _buildConversationalVoiceTab() {
    return LuxResponsiveContainer(
      child: Column(
        children: [
          const SizedBox(height: 8),

          // Action Bar: Clear History & Voice Engine State Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: _aiState == VoiceAiState.thinking || _aiState == VoiceAiState.responding
                            ? RoadOSColors.hyperOrange
                            : RoadOSColors.apexEmerald,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _aiState == VoiceAiState.thinking
                          ? 'JARVIS REASONING...'
                          : (_aiState == VoiceAiState.responding ? 'JARVIS SPEAKING...' : 'HEY ROADOS ENGINE ONLINE'),
                      style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: RoadOSColors.textMuted, letterSpacing: 0.5),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _clearChatHistory,
                  icon: const Icon(Icons.delete_outline_rounded, size: 14, color: RoadOSColors.textMuted),
                  label: const Text('Clear Chat', style: TextStyle(fontSize: 10, color: RoadOSColors.textMuted, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),

          // Neural Orb Audio Visualizer
          NeuralVoiceOrbWidget(
            isListening: _aiState == VoiceAiState.listening,
            wakeWordStatus: _aiState == VoiceAiState.thinking
                ? 'Processing Rider Intent...'
                : (_aiState == VoiceAiState.responding ? 'Speaking Response...' : 'Listening for "Hey RoadOS"...'),
            onTap: () {
              _handleUserPrompt('Show bike health');
            },
          ),
          const SizedBox(height: 10),

          // Quick Command Action Chips
          SizedBox(
            height: 30,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              physics: const BouncingScrollPhysics(),
              children: [
                _buildCommandChip('Navigate Home'),
                _buildCommandChip('Find Petrol Pump'),
                _buildCommandChip('Open Garage'),
                _buildCommandChip('Show Bike Health'),
                _buildCommandChip('Call Emergency'),
                _buildCommandChip('Read Notifications'),
                _buildCommandChip('Start Ride'),
                _buildCommandChip('End Ride'),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Multi-Turn Chat Feed
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              physics: const BouncingScrollPhysics(),
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAi = msg['sender'] == 'RIDEO AI';
                // Only animate the very first message if it's AI and currently responding
                final isLatest = index == 0;
                final shouldAnimate = isAi && isLatest && _aiState == VoiceAiState.responding;

                if (isAi) {
                  return MarkdownAiMessageWidget(
                    text: msg['text']!,
                    isAnimated: shouldAnimate,
                    onComplete: () {
                      if (mounted && _aiState == VoiceAiState.responding) {
                        setState(() {
                          _aiState = VoiceAiState.listening;
                        });
                      }
                    },
                  );
                } else {
                  return MarkdownUserMessageWidget(
                    text: msg['text']!,
                  );
                }
              },
            ),
          ),

          // Text Chat Input & Control Bar
          Container(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 16, top: 10),
            color: Colors.transparent, // Floating over the background
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_aiState == VoiceAiState.thinking || _aiState == VoiceAiState.responding) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      LuxAudioHapticsService.lightImpact();
                      setState(() {
                        _aiState = VoiceAiState.listening;
                      });
                    },
                    icon: const Icon(Icons.stop_rounded, size: 16),
                    label: const Text('Stop generating', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF141A29),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1426).withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 4),
                        child: IconButton(
                          icon: Icon(
                            _isTtsActive ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                            color: _isTtsActive ? const Color(0xFF8B5CF6) : RoadOSColors.textMuted,
                            size: 20,
                          ),
                          onPressed: () {
                            LuxAudioHapticsService.selectionClick();
                            setState(() => _isTtsActive = !_isTtsActive);
                          },
                          tooltip: _isTtsActive ? 'Voice TTS Active' : 'Voice Muted',
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: TextField(
                            controller: _textController,
                            minLines: 1,
                            maxLines: 5,
                            keyboardType: TextInputType.multiline,
                            style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                            decoration: InputDecoration(
                              hintText: 'Message Rideo AI...',
                              hintStyle: TextStyle(color: RoadOSColors.textMuted.withValues(alpha: 0.6), fontSize: 13),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, right: 4),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _aiState == VoiceAiState.thinking || _aiState == VoiceAiState.responding
                                ? Colors.transparent
                                : const Color(0xFF8B5CF6),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _aiState == VoiceAiState.thinking || _aiState == VoiceAiState.responding
                                  ? Icons.more_horiz_rounded
                                  : Icons.arrow_upward_rounded,
                              color: _aiState == VoiceAiState.thinking || _aiState == VoiceAiState.responding
                                  ? RoadOSColors.textMuted
                                  : Colors.white,
                              size: 20,
                            ),
                            onPressed: _aiState == VoiceAiState.thinking || _aiState == VoiceAiState.responding
                                ? null
                                : () => _handleUserPrompt(_textController.text),
                            tooltip: 'Send Message',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandChip(String label) {
    return GestureDetector(
      onTap: () => _handleUserPrompt(label),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.55), width: 1.2),
          boxShadow: [BoxShadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.12), blurRadius: 8, spreadRadius: -2)],
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF8B5CF6)),
        ),
      ),
    );
  }

  Widget _buildMaintenanceTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: PredictiveMaintenanceGridWidget(),
    );
  }

  Widget _buildRideAnalyticsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: RideIntelligenceRadarWidget(),
    );
  }

  Widget _buildTripPlannerTab() {
    return const SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: SmartTripPlannerWidget(),
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: AiNotificationsDrawerWidget(),
    );
  }

  Widget _buildLeaderboardTab() {
    return const SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      padding: EdgeInsets.all(16),
      child: RiderProfileLeaderboardWidget(),
    );
  }
}
