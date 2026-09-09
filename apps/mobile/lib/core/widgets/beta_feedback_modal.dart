import 'package:flutter/material.dart';
import '../design_system/design_tokens.dart';
import '../design_system/roados_components.dart';
import '../design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;
import '../services/lux_haptics_audio_service.dart';

enum BetaFeedbackCategory { bugReport, featureRequest, navigation, aiCopilot, general }

class BetaFeedbackModal extends StatefulWidget {
  const BetaFeedbackModal({super.key});

  static void show(BuildContext context) {
    showLuxSheet(
                context: context,
                title: '',
      builder: (_) => const BetaFeedbackModal(),
    );
  }

  @override
  State<BetaFeedbackModal> createState() => _BetaFeedbackModalState();
}

class _BetaFeedbackModalState extends State<BetaFeedbackModal> {
  BetaFeedbackCategory _selectedCategory = BetaFeedbackCategory.bugReport;
  final TextEditingController _feedbackController = TextEditingController();
  int _rating = 5;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  void _submitFeedback() {
    if (_feedbackController.text.trim().isEmpty) return;

    LuxAudioHapticsService.heavyImpact();
    showLuxSnack(context, 'Beta feedback & diagnostic logs submitted cleanly to RideOS AI QA Server.', variant: LuxSnackVariant.info);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: RoadOSColors.cyberCyan, width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bug_report_rounded, color: RoadOSColors.cyberCyan, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'CLOSED BETA RC2 FEEDBACK',
                    style: TextStyle(color: RoadOSColors.cyberCyan, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: RoadOSColors.platinumWhite, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),

          const Text('CATEGORY', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: BetaFeedbackCategory.values.map((cat) {
              final isSelected = _selectedCategory == cat;
              return ChoiceChip(
                label: Text(cat.name.toUpperCase()),
                selected: isSelected,
                selectedColor: RoadOSColors.cyberCyan.withValues(alpha: 0.3),
                backgroundColor: Colors.black45,
                labelStyle: TextStyle(
                  color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.textMuted,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
                onSelected: (_) {
                  LuxAudioHapticsService.selectionClick();
                  setState(() => _selectedCategory = cat);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          const Text('RATING', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (idx) {
              final star = idx + 1;
              return IconButton(
                icon: Icon(
                  star <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: RoadOSColors.solarGold,
                  size: 26,
                ),
                onPressed: () {
                  LuxAudioHapticsService.lightImpact();
                  setState(() => _rating = star);
                },
              );
            }),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _feedbackController,
            maxLines: 4,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: buildLuxGlassInputDecoration(
              label: 'Describe issue or suggestion for QA team',
              icon: Icons.edit_note_rounded,
            ),
          ),
          const SizedBox(height: 20),

          RoadOSButton(
            label: 'SUBMIT BETA FEEDBACK',
            icon: Icons.send_rounded,
            gradient: LuxGradients.quantumCyan,
            onPressed: _submitFeedback,
          ),
        ],
      ),
    );
  }
}
