import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../domain/models/predictive_intelligence_models.dart';
import '../../core/services/advanced_predictive_intelligence_engine.dart';

class PredictiveRideIntelligenceScreen extends StatefulWidget {
  const PredictiveRideIntelligenceScreen({super.key});

  @override
  State<PredictiveRideIntelligenceScreen> createState() => _PredictiveRideIntelligenceScreenState();
}

class _PredictiveRideIntelligenceScreenState extends State<PredictiveRideIntelligenceScreen> {
  final _engine = AdvancedPredictiveIntelligenceEngine();
  String _aiReply = '';
  final TextEditingController _queryController = TextEditingController();

  void _askAi(String query) {
    if (query.trim().isEmpty) return;
    final res = _engine.processPredictiveAiQuery(query.trim());
    setState(() {
      _aiReply = res;
      _queryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final roadmap = _engine.getPredictiveMaintenanceRoadmap();
    final trends = _engine.getBatteryThermalTrends();
    final score = _engine.getRideIntelligenceScore();
    final alerts = _engine.getActiveSmartAlerts();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'PREDICTIVE RIDE & VEHICLE INTELLIGENCE',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
        ),
      ),
      body: CinematicBackground(
        child: ListView(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: 16, top: MediaQuery.of(context).padding.top + 56),
        children: [
          // 1. Overall Vehicle Health Risk Card (Liquid Water-Glass)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: RoadOSShadows.luxuryCard,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: RoadOSGradients.liquidWaterGlass,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: RoadOSColors.electricBlue.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('PREDICTIVE HEALTH STATUS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: RoadOSColors.apexEmerald.withValues(alpha: 0.5)),
                            ),
                            child: const Text('HEALTHY / OPTIMAL', style: TextStyle(color: RoadOSColors.apexEmerald, fontSize: 9, fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildHealthBar('Electrical Risk', 96, RoadOSColors.cyberCyan)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildHealthBar('Thermal Risk', 98, RoadOSColors.hyperOrange)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildHealthBar('Driveline Risk', 90, RoadOSColors.apexEmerald)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Battery & Thermal Intelligence (Liquid Water-Glass)
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: RoadOSGradients.liquidWaterGlass,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: RoadOSColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('BATTERY TREND', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(trends.batteryStatus, style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 13, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text(trends.batteryTrend, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: RoadOSGradients.liquidWaterGlass,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: RoadOSColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('THERMAL TREND', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(trends.thermalStatus, style: const TextStyle(color: RoadOSColors.hyperOrange, fontSize: 13, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 2),
                          Text(trends.thermalTrend, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Multi-Dimensional Ride Score (Liquid Water-Glass)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: RoadOSShadows.luxuryCard,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: RoadOSGradients.liquidWaterGlass,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: RoadOSColors.borderSubtle),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('RIDE INTELLIGENCE SCORE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          Text('${score.overallScore}/100', style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 14, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatCol('SMOOTHNESS', '${score.smoothnessScore}%', RoadOSColors.cyberCyan),
                          _buildStatCol('EFFICIENCY', '${score.efficiencyScore}%', RoadOSColors.electricBlue),
                          _buildStatCol('THERMAL STAB.', '${score.thermalStabilityScore}%', RoadOSColors.hyperOrange),
                        ],
                      ),
                      const Divider(color: RoadOSColors.borderTranslucent, height: 16),
                      const Text('AI COACHING SUGGESTION', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(score.improvementSuggestions.first, style: const TextStyle(color: Colors.white70, fontSize: 10)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Predictive Maintenance Roadmap
          const Text('PREDICTIVE COMPONENT LIFECYCLE', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ...roadmap.map((item) => _buildPredictiveTile(item)),

          const SizedBox(height: 16),

          // 5. Predictive AI Assistant Queries
          const Text('PREDICTIVE AI ASSISTANT', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPromptChip('Is anything concerning?'),
                _buildPromptChip('What should I service next?'),
                _buildPromptChip('Has my battery changed?'),
                _buildPromptChip('How has my riding improved?'),
                _buildPromptChip('Which bike needs attention first?'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (_aiReply.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF070B18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.5)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.smart_toy_rounded, color: RoadOSColors.cyberCyan, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_aiReply, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3)),
                  ),
                ],
              ),
            ),

          // Query Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _queryController,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Ask about component wear, battery trends...',
                    hintStyle: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF080C1A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: RoadOSColors.borderTranslucent),
                    ),
                  ),
                  onSubmitted: _askAi,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: RoadOSColors.electricBlue,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                onPressed: () => _askAi(_queryController.text),
              ),
            ],
          ),
        ],
      ),
      ),
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

  Widget _buildStatCol(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildPredictiveTile(PredictiveMaintenanceItem item) {
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
              Text(item.componentName, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'CONFIDENCE: ${item.confidence.label}',
                  style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text('Due in ${item.remainingKm} km (at ${item.nextExpectedServiceKm} km odometer)', style: const TextStyle(color: Colors.white70, fontSize: 10)),
          const SizedBox(height: 2),
          Text(item.riskAssessment, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String prompt) {
    return GestureDetector(
      onTap: () => _askAi(prompt),
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
