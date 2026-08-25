import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../domain/models/advanced_safety_models.dart';
import '../../core/services/advanced_safety_protection_engine.dart';

class AdvancedSafetyCenterScreen extends StatefulWidget {
  const AdvancedSafetyCenterScreen({super.key});

  @override
  State<AdvancedSafetyCenterScreen> createState() => _AdvancedSafetyCenterScreenState();
}

class _AdvancedSafetyCenterScreenState extends State<AdvancedSafetyCenterScreen> {
  final _safetyEngine = AdvancedSafetyProtectionEngine();
  String _aiOutput = '';
  final TextEditingController _queryController = TextEditingController();

  void _sendQuery(String prompt) {
    if (prompt.trim().isEmpty) return;
    final res = _safetyEngine.processSafetyAiQuery(prompt.trim());
    setState(() {
      _aiOutput = res;
      _queryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = _safetyEngine.getSafetyCenterStatus();
    final contacts = _safetyEngine.getEmergencyContacts();
    final events = _safetyEngine.getSafetyEventHistory();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF060912),
        title: const Text(
          'SAFETY CENTER & EMERGENCY PROTECTION',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
        ),
      ),
      body: CinematicBackground(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Safety Status Card
          RoadOSCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('RIDER & VEHICLE SAFETY STATUS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: RoadOSColors.apexEmerald.withValues(alpha: 0.5)),
                      ),
                      child: Text('${status.label} / PROTECTED', style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 9, fontWeight: FontWeight.w900)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildMetricItem('Crash Detection', 'ARMED', RoadOSColors.cyberCyan)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricItem('Thermal Monitor', 'NOMINAL', RoadOSColors.hyperOrange)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricItem('Emergency Link', '${contacts.length} Contacts', RoadOSColors.apexEmerald)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. Emergency SOS Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24),
                    SizedBox(width: 8),
                    Text('EMERGENCY SOS PROTECTION', style: TextStyle(color: Colors.redAccent, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text('Hold for 2 seconds to initiate SOS broadcast with GPS coordinates to emergency contacts.', style: TextStyle(color: Colors.white70, fontSize: 10), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.sos_rounded, size: 20),
                  label: const Text('MANUAL SOS TRIGGER', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  onPressed: () {
        LuxAudioHapticsService.lightImpact();
                    showLuxSnack(context, 'SOS Test Mode: Emergency broadcast simulated. All contacts notified.', variant: LuxSnackVariant.info);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Emergency Contacts
          const Text('CONFIGURED EMERGENCY CONTACTS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ...contacts.map((c) => _buildContactTile(c)),

          const SizedBox(height: 16),

          // 4. Safety Event History
          const Text('SAFETY & INCIDENT AUDIT LOG', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ...events.map((e) => _buildEventTile(e)),

          const SizedBox(height: 16),

          // 5. Safety AI Assistant
          const Text('SAFETY & DIAGNOSTIC AI ASSISTANT', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPromptChip('Is my bike safe to ride?'),
                _buildPromptChip('What should I do about high temp?'),
                _buildPromptChip('Show my last safety event'),
                _buildPromptChip('Show emergency contacts'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (_aiOutput.isNotEmpty)
            RoadOSCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.smart_toy_rounded, color: RoadOSColors.cyberCyan, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(_aiOutput, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3)),
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
                    hintText: 'Ask about safety alerts, thermal limits...',
                    hintStyle: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11),
                    filled: true,
                    fillColor: const Color(0xFF080C1A),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: RoadOSColors.borderTranslucent),
                    ),
                  ),
                  onSubmitted: _sendQuery,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: RoadOSColors.cyberCyan,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                onPressed: () => _sendQuery(_queryController.text),
              ),
            ],
          ),
        ],
      )),
    );
  }

  Widget _buildMetricItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildContactTile(EmergencyContactItem c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF060C1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.28)),
        boxShadow: [BoxShadow(color: RoadOSColors.cyberCyan.withValues(alpha: 0.08), blurRadius: 10, spreadRadius: -3)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: RoadOSColors.cyberCyan.withValues(alpha: 0.14),
                  boxShadow: [BoxShadow(color: RoadOSColors.cyberCyan.withValues(alpha: 0.3), blurRadius: 8)],
                ),
                child: const Icon(Icons.contact_phone_rounded, color: RoadOSColors.cyberCyan, size: 16),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('${c.relationship} | ${c.phone}', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9)),
                ],
              ),
            ],
          ),
          if (c.isPrimary)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: RoadOSColors.apexEmerald.withValues(alpha: 0.5)),
              ),
              child: const Text('PRIMARY', style: TextStyle(color: RoadOSColors.apexEmerald, fontSize: 8, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  Widget _buildEventTile(SafetyEventRecord e) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF07091A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A2040)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${e.eventType} | ${e.vehicleName}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: e.resolutionStatus == 'CANCELLED_BY_RIDER' ? RoadOSColors.cyberCyan.withValues(alpha: 0.18) : RoadOSColors.apexEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: e.resolutionStatus == 'CANCELLED_BY_RIDER' ? RoadOSColors.cyberCyan.withValues(alpha: 0.45) : RoadOSColors.apexEmerald.withValues(alpha: 0.4)),
                ),
                child: Text(
                  e.resolutionStatus,
                  style: TextStyle(
                    color: e.resolutionStatus == 'CANCELLED_BY_RIDER' ? RoadOSColors.cyberCyan : RoadOSColors.apexEmerald,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(e.description, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9)),
        ],
      ),
    );
  }

  Widget _buildPromptChip(String prompt) {
    return GestureDetector(
      onTap: () => _sendQuery(prompt),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF080C1A),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.35)),
        ),
        child: Text(prompt, style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
