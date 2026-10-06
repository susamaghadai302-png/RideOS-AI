import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../domain/models/intelligent_platform_models.dart';
import '../../core/services/intelligent_rider_platform_engine.dart';
import '../../../../core/widgets/cinematic_background.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  const ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class IntelligentRiderPlatformScreen extends StatefulWidget {
  const IntelligentRiderPlatformScreen({super.key});

  @override
  State<IntelligentRiderPlatformScreen> createState() => _IntelligentRiderPlatformScreenState();
}

class _IntelligentRiderPlatformScreenState extends State<IntelligentRiderPlatformScreen> {
  final _aiEngine = IntelligentRiderPlatformEngine();
  final TextEditingController _queryController = TextEditingController();
  final List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: 'RideOS AI Assistant online. How can I assist your ride today?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(
      text: text.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    final reply = _aiEngine.processRiderQuery(text.trim());
    final botMsg = ChatMessage(
      text: reply,
      isUser: false,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMsg);
      _messages.add(botMsg);
      _queryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final health = _aiEngine.evaluateVehicleHealth();
    final analytics = _aiEngine.getRidingAnalytics();
    final milestones = _aiEngine.getMaintenanceMilestones();
    final insights = _aiEngine.generateProactiveInsights();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF060912),
        title: const Text(
          'RIDEOS AI PLATFORM',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
        ),
      ),
      body: CinematicBackground(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Unified Vehicle Health Score Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: RoadOSGradients.darkCardGradient,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: RoadOSColors.electricBlue.withValues(alpha: 0.4)),
              boxShadow: RoadOSShadows.luxuryCard,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('OVERALL VEHICLE HEALTH', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: RoadOSColors.apexEmerald.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '${health?.overallHealthScore ?? 0}% OPTIMAL',
                        style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 9, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildHealthBar('Engine', health?.engineScore ?? 0, RoadOSColors.hyperOrange)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildHealthBar('Coolant', health?.coolantScore ?? 0, RoadOSColors.cyberCyan)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildHealthBar('Battery', health?.batteryScore ?? 0, RoadOSColors.apexEmerald)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildHealthBar('Service', health?.maintenanceScore ?? 0, RoadOSColors.electricBlue)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Proactive AI Insights Feed
          const Text('AI PROACTIVE INSIGHTS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ...insights.map((ins) => _buildInsightTile(ins)),

          const SizedBox(height: 16),

          // 3. Smart Maintenance Milestones
          const Text('INTELLIGENT MAINTENANCE ROADMAP', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ...milestones.map((m) => _buildMilestoneTile(m)),

          const SizedBox(height: 16),

          // 4. Riding Performance Overview
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF080C1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RoadOSColors.borderTranslucent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RIDER PERFORMANCE MATRIX', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    Text(analytics?.efficiencyRating ?? 'N/A', style: const TextStyle(color: RoadOSColors.hyperOrange, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatMetric('SAFETY SCORE', '${analytics?.overallSafetyScore ?? 0}/100', RoadOSColors.apexEmerald),
                    _buildStatMetric('TOP SPEED', '${analytics?.maxSpeedKmh.round() ?? 0} km/h', RoadOSColors.cyberCyan),
                    _buildStatMetric('MAX LEAN', '${analytics?.maxLeanAngleDeg.toStringAsFixed(1) ?? "0.0"} deg', RoadOSColors.warningAmber),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 5. Conversational AI Assistant
          const Text('ASK RIDEOS AI ASSISTANT', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),

          // Quick Prompt Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPromptChip('How is my bike?'),
                _buildPromptChip('Is my engine temp normal?'),
                _buildPromptChip('When is my next service?'),
                _buildPromptChip('Show riding performance'),
                _buildPromptChip('Pre-ride checklist'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Chat Messages View
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF070B18),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: RoadOSColors.borderTranslucent),
            ),
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, idx) {
                final msg = _messages[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!msg.isUser)
                        const Padding(
                          padding: EdgeInsets.only(right: 6, top: 2),
                          child: Icon(Icons.smart_toy_rounded, color: RoadOSColors.cyberCyan, size: 14),
                        ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: msg.isUser ? RoadOSColors.electricBlue : Colors.white10,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            msg.text,
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Input Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Ask about vehicle health, service, safety...',
                    hintStyle: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF080C1A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: RoadOSColors.borderTranslucent),
                    ),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: RoadOSColors.electricBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                onPressed: () => _sendMessage(_queryController.text),
              ),
            ],
          ),
        ],
      )),
    );
  }

  Widget _buildHealthBar(String label, int score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text('$score%', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
        const SizedBox(height: 3),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: score / 100.0,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildInsightTile(AiRiderInsight ins) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF070B18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RoadOSColors.borderTranslucent),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, color: RoadOSColors.cyberCyan, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ins.title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(ins.message, style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneTile(SmartMaintenanceMilestone m) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF070B18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RoadOSColors.borderTranslucent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(m.taskType, style: const TextStyle(color: RoadOSColors.electricBlue, fontSize: 11, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: m.priority == MaintenancePriority.critical
                      ? Colors.red.withValues(alpha: 0.2)
                      : RoadOSColors.apexEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  m.priority.label,
                  style: TextStyle(
                    color: m.priority == MaintenancePriority.critical ? Colors.redAccent : RoadOSColors.apexEmerald,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('Due in ${m.remainingKm} km (at ${m.nextDueKm} km odometer)', style: const TextStyle(color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 2),
          Text(m.explanation, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildStatMetric(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildPromptChip(String prompt) {
    return GestureDetector(
      onTap: () => _sendMessage(prompt),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF080C1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: RoadOSColors.borderTranslucent),
        ),
        child: Text(prompt, style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
