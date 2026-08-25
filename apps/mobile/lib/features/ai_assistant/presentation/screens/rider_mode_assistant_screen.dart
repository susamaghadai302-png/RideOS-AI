import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import '../../../../core/design_system/premium_navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/ai_assistant/models/ai_ride_assistant_models.dart';
import '../../../../core/ai_assistant/services/ai_ride_assistant.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';

class RiderModeAssistantScreen extends ConsumerStatefulWidget {
  const RiderModeAssistantScreen({super.key});

  @override
  ConsumerState<RiderModeAssistantScreen> createState() => _RiderModeAssistantScreenState();
}

class _RiderModeAssistantScreenState extends ConsumerState<RiderModeAssistantScreen> {
  final _assistant = AIRideAssistant();
  final _queryController = TextEditingController();

  bool _isListening = false;
  bool _isProcessing = false;
  AssistantResponse? _latestResponse;
  PersonalizedRideBriefing? _briefing;

  @override
  void initState() {
    super.initState();
    _refreshBriefing();
  }

  void _refreshBriefing() {
    final activeContext = ref.read(activeVehicleContextProvider);
    _assistant.setActiveVehicle(activeContext.profile);
    setState(() {
      _briefing = _assistant.generatePreRideBriefing();
    });
  }

  Future<void> _handleQuery(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isProcessing = true);
    _queryController.text = query;

    final activeContext = ref.read(activeVehicleContextProvider);
    _assistant.setActiveVehicle(activeContext.profile);

    final resp = await _assistant.askAssistant(query: query);

    if (mounted) {
      setState(() {
        _latestResponse = resp;
        _isProcessing = false;
      });
    }
  }

  void _toggleVoiceSimulation() {
    if (_isListening) {
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      // Simulate speech recognition utterance trigger after brief pause
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted && _isListening) {
          setState(() => _isListening = false);
          _handleQuery('How is my bike?');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.mic_rounded, color: RoadOSColors.electricBlue, size: 20),
            SizedBox(width: 8),
            Text(
              'RIDER AI ASSISTANT',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: RoadOSColors.textSecondary),
            onPressed: _refreshBriefing,
          ),
        ],
      ),
      body: CinematicBackground(child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_briefing != null) _buildBriefingCard(_briefing!),
                if (_latestResponse != null) ...[
                  const SizedBox(height: 16),
                  _buildResponseCard(_latestResponse!),
                ],
                const SizedBox(height: 20),
                _buildQuickCommandChips(),
              ],
            ),
          ),
          _buildVoiceBottomBar(),
        ],
      )),
    );
  }

  Widget _buildBriefingCard(PersonalizedRideBriefing b) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: b.hasCaution ? RoadOSColors.warningAmber.withValues(alpha: 0.5) : RoadOSColors.borderTranslucent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    b.hasCaution ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
                    color: b.hasCaution ? RoadOSColors.warningAmber : RoadOSColors.apexEmerald,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'PRE-RIDE BRIEFING',
                    style: TextStyle(color: RoadOSColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (b.isVehicleConnected ? RoadOSColors.apexEmerald : RoadOSColors.textMuted).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  b.isVehicleConnected ? 'CONNECTED' : 'STANDBY',
                  style: TextStyle(color: b.isVehicleConnected ? RoadOSColors.apexEmerald : RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const Divider(color: RoadOSColors.borderTranslucent, height: 20),
          _buildBriefingRow(Icons.two_wheeler_rounded, 'Vehicle', b.vehicleName),
          _buildBriefingRow(Icons.battery_charging_full_rounded, 'Energy / Fuel', b.fuelOrBatteryStatus),
          _buildBriefingRow(Icons.healing_rounded, 'Health Status', b.vehicleHealthStatus),
          _buildBriefingRow(Icons.wb_sunny_rounded, 'Weather', b.weatherStatus),
          _buildBriefingRow(Icons.build_rounded, 'Maintenance', b.upcomingMaintenance),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: RoadOSColors.neonViolet, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    b.aiRecommendation,
                    style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBriefingRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, color: RoadOSColors.electricBlue, size: 14),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 11, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponseCard(AssistantResponse resp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoadOSColors.electricBlue.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.record_voice_over_rounded, color: RoadOSColors.electricBlue, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    resp.intent.label.toUpperCase(),
                    style: const TextStyle(color: RoadOSColors.electricBlue, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: RoadOSColors.neonViolet.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  resp.isOfflineAi ? 'OFFLINE AI' : 'CLOUD AI',
                  style: const TextStyle(color: RoadOSColors.neonViolet, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            resp.spokenText,
            style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 6),
          Text(
            resp.displayText,
            style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11),
          ),
          if (resp.predictions.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.insights_rounded, color: RoadOSColors.warningAmber, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '[AI PREDICTION] ${resp.predictions.first.predictionText}',
                      style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (resp.suggestedActions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...resp.suggestedActions.map((action) => _buildActionButton(action)),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(AssistantActionExecution action) {
    if (action.isBlockedForSafety) {
      return Container(
        margin: const EdgeInsets.only(top: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.redAccent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.redAccent),
        ),
        child: Row(
          children: [
            const Icon(Icons.block_rounded, color: Colors.redAccent, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(action.description, style: const TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold))),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow_rounded, size: 16),
        label: Text(action.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
        style: ElevatedButton.styleFrom(
          backgroundColor: RoadOSColors.electricBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () async {
          final success = await _assistant.executeAction(action);
          if (mounted && success) {
            showLuxSnack(context, 'Executed: ${action.title}', variant: LuxSnackVariant.info);
          }
        },
      ),
    );
  }

  Widget _buildQuickCommandChips() {
    final commands = [
      'How is my bike?',
      'What is my battery?',
      'Give me the safest route',
      'Start ride tracking',
      'Do I need service soon?',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QUICK VOICE SHORTCUTS',
          style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: commands.map((cmd) {
            return ActionChip(
              backgroundColor: RoadOSColors.cardSurface,
              label: Text(cmd, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: RoadOSColors.borderTranslucent),
              ),
              onPressed: () => _handleQuery(cmd),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVoiceBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _queryController,
              style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Ask or type riding request...',
                hintStyle: const TextStyle(color: RoadOSColors.textMuted, fontSize: 13),
                filled: true,
                fillColor: Colors.black,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: RoadOSColors.borderTranslucent)),
              ),
              onSubmitted: _handleQuery,
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _toggleVoiceSimulation,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isListening ? Colors.redAccent : RoadOSColors.electricBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
