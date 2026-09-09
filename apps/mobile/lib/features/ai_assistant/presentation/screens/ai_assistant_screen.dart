import 'package:flutter/material.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/widgets/roados_visual_environment.dart';
import '../../../garage/presentation/screens/luxury_garage_showroom_screen.dart';
import '../../../navigation/presentation/screens/three_d_navigation_screen.dart';
import '../../../obd_tpms/presentation/screens/obd_diagnostics_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/ai_assistant_bloc.dart';
import '../bloc/ai_assistant_event.dart';
import '../bloc/ai_assistant_state.dart';
import '../widgets/ai_assistant_widgets.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/contracts/text_to_speech_gateway.dart';
import '../../../voice_assistant/presentation/bloc/voice_bloc.dart';
import '../../../../core/contracts/voice_models.dart';

class AiAssistantScreen extends StatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  State<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends State<AiAssistantScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _textController = TextEditingController();
  final TextToSpeechGateway _ttsGateway = getIt<TextToSpeechGateway>();
  bool _isTtsActive = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _textController.dispose();
    _ttsGateway.stop();
    super.dispose();
  }

  void _handleUserPrompt(String input) {
    final prompt = input.trim();
    if (prompt.isEmpty) return;

    LuxAudioHapticsService.mediumImpact();
    _textController.clear();
    context.read<AiAssistantBloc>().add(SendAiPromptEvent(prompt: prompt));
  }

  void _clearChatHistory() {
    LuxAudioHapticsService.selectionClick();
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
            context.read<AiAssistantBloc>().add(SendAiPromptEvent(prompt: state.currentTranscript!.text));
          },
        ),
        BlocListener<AiAssistantBloc, AiAssistantState>(
          listenWhen: (previous, current) => previous != current && current is AiAssistantLoadedState,
          listener: (context, state) {
            if (_isTtsActive && state is AiAssistantLoadedState && state.messages.isNotEmpty) {
              final lastMsg = state.messages.last;
              if (!lastMsg.isUser) _ttsGateway.speak(lastMsg.text);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: RoadOSVisualEnvironment(
          environmentType: RoadOSEnvironmentType.voiceAi,
          child: SafeArea(
            top: false,
            child: Column(
              children: [
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
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildConversationalVoiceTab(),
                      _buildMaintenanceTab(),
                      _buildRideAnalyticsTab(),
                      _buildTripPlannerTab(),
                      _buildNotificationsTab(),
                      _buildLeaderboardTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationalVoiceTab() {
    return LuxResponsiveContainer(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                BlocBuilder<VoiceBloc, VoiceState>(
                  builder: (context, state) {
                    final isProcessing = state.inputState == VoiceInputState.processing;
                    final isListening = state.inputState == VoiceInputState.listening;
                    return Row(
                      children: [
                        Container(width: 6, height: 6, decoration: BoxDecoration(color: isProcessing ? RoadOSColors.hyperOrange : RoadOSColors.apexEmerald, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Text(isProcessing ? 'JARVIS REASONING...' : (isListening ? 'LISTENING...' : 'HEY ROADOS ENGINE ONLINE'), style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: RoadOSColors.textMuted, letterSpacing: 0.5)),
                      ],
                    );
                  },
                ),
                TextButton.icon(onPressed: _clearChatHistory, icon: const Icon(Icons.delete_outline_rounded, size: 14, color: RoadOSColors.textMuted), label: const Text('Clear Chat', style: TextStyle(fontSize: 10, color: RoadOSColors.textMuted, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          BlocBuilder<VoiceBloc, VoiceState>(
            builder: (context, state) {
              final isListening = state.inputState == VoiceInputState.listening;
              return NeuralVoiceOrbWidget(
                isListening: isListening,
                wakeWordStatus: isListening ? 'Listening for command...' : 'Tap to speak...',
                onTap: () => isListening ? context.read<VoiceBloc>().add(StopVoiceListening()) : context.read<VoiceBloc>().add(StartVoiceListening()),
              );
            },
          ),
          const SizedBox(height: 10),
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
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: BlocBuilder<AiAssistantBloc, AiAssistantState>(
              builder: (context, state) {
                if (state is AiAssistantInitialState) return const Center(child: Text('How can I assist your ride today?', style: TextStyle(color: RoadOSColors.textMuted)));
                List<AiUiMessage> messages = [];
                bool isLoading = false;
                if (state is AiAssistantLoadingState) { messages = state.messages; isLoading = true; }
                else if (state is AiAssistantLoadedState) messages = state.messages;
                else if (state is AiAssistantErrorState) return Center(child: Text('Error: ${state.errorMessage}', style: const TextStyle(color: RoadOSColors.hyperOrange)));
                final reversed = messages.reversed.toList();
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  physics: const BouncingScrollPhysics(),
                  reverse: true,
                  itemCount: reversed.length + (isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (isLoading && index == 0) return const Padding(padding: EdgeInsets.only(bottom: 16), child: Align(alignment: Alignment.centerLeft, child: CircularProgressIndicator(color: RoadOSColors.cyberCyan, strokeWidth: 2)));
                    final msg = reversed[isLoading ? index - 1 : index];
                    return msg.isUser
                        ? MarkdownUserMessageWidget(text: msg.text)
                        : MarkdownAiMessageWidget(text: msg.text, isAnimated: false, onComplete: () {});
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 16, top: 10),
            child: Container(
              decoration: BoxDecoration(color: const Color(0xFF0E1426).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF334155).withValues(alpha: 0.5))),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(padding: const EdgeInsets.only(bottom: 4, left: 4), child: IconButton(icon: Icon(_isTtsActive ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: _isTtsActive ? const Color(0xFF8B5CF6) : RoadOSColors.textMuted, size: 20), onPressed: () { LuxAudioHapticsService.selectionClick(); setState(() { _isTtsActive = !_isTtsActive; if (!_isTtsActive) _ttsGateway.stop(); }); })),
                  Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: TextField(controller: _textController, minLines: 1, maxLines: 5, keyboardType: TextInputType.multiline, style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4), decoration: InputDecoration(hintText: 'Message Rideo AI...', hintStyle: TextStyle(color: RoadOSColors.textMuted.withValues(alpha: 0.6), fontSize: 13), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12))))),
                  Padding(padding: const EdgeInsets.only(bottom: 4, right: 4), child: BlocBuilder<AiAssistantBloc, AiAssistantState>(builder: (context, aiState) { final isProcessing = aiState is AiAssistantLoadingState; return Container(decoration: BoxDecoration(color: isProcessing ? Colors.transparent : const Color(0xFF8B5CF6), shape: BoxShape.circle), child: IconButton(icon: Icon(isProcessing ? Icons.more_horiz_rounded : Icons.arrow_upward_rounded, color: isProcessing ? RoadOSColors.textMuted : Colors.white, size: 20), onPressed: isProcessing ? null : () => _handleUserPrompt(_textController.text))); })),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandChip(String label) {
    return GestureDetector(onTap: () => _handleUserPrompt(label), child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xFF8B5CF6).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.55), width: 1.2)), child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF8B5CF6)))));
  }

  Widget _buildMaintenanceTab() => SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(16), child: PredictiveMaintenanceGridWidget());
  Widget _buildRideAnalyticsTab() => SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(16), child: RideIntelligenceRadarWidget());
  Widget _buildTripPlannerTab() => const SingleChildScrollView(physics: BouncingScrollPhysics(), padding: EdgeInsets.all(16), child: SmartTripPlannerWidget());
  Widget _buildNotificationsTab() => SingleChildScrollView(physics: const BouncingScrollPhysics(), padding: const EdgeInsets.all(16), child: AiNotificationsDrawerWidget());
  Widget _buildLeaderboardTab() => const SingleChildScrollView(physics: BouncingScrollPhysics(), padding: EdgeInsets.all(16), child: RiderProfileLeaderboardWidget());
}
