import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/services/lux_haptics_audio_service.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design_system/roados_tokens.dart';
import '../../design_system/roados_components.dart';
import '../../design_system/liquid_glass_components.dart';
import '../models/vehicle_intelligence_models.dart';

void showAiInsightDetailModal(BuildContext context, AiInsight insight, {VoidCallback? onActionTriggered}) {
  showLiquidGlassModal(
    context: context,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modal Header with Severity Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'AI INSIGHT EXPLANATION',
                style: GoogleFonts.outfit(
                  color: RoadOSColors.cyberCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            LiquidGlassBadge(
              label: insight.severity.label,
              icon: insight.severity.icon,
              color: insight.severity.color,
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Title
        Text(
          insight.title,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),

        // 1. WHAT HAPPENED
        _buildSectionTitle('WHAT HAPPENED'),
        const SizedBox(height: 4),
        Text(
          insight.explanation,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 12.5,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        // 2. WHY IT MATTERS
        _buildSectionTitle('WHY IT MATTERS'),
        const SizedBox(height: 4),
        Text(
          insight.whyItMatters,
          style: GoogleFonts.inter(
            color: RoadOSColors.textSecondary,
            fontSize: 12,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 14),

        // 3. SOURCE & TIMESTAMP
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('SOURCE'),
                const SizedBox(height: 2),
                Text(
                  insight.source,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildSectionTitle('SIGNAL TIME'),
                const SizedBox(height: 2),
                Text(
                  'JUST NOW',
                  style: GoogleFonts.inter(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Action Button
        if (insight.recommendedAction != null)
          LiquidGlassButton(
            label: insight.recommendedAction!.toUpperCase(),
            icon: Icons.arrow_forward_rounded,
            height: 46,
            onPressed: () {
        LuxAudioHapticsService.lightImpact();
              Navigator.pop(context);
              if (onActionTriggered != null) {
                onActionTriggered();
              }
            },
          ),
      ],
    ),
  );
}

Widget _buildSectionTitle(String title) {
  return Text(
    title,
    style: GoogleFonts.outfit(
      color: RoadOSColors.cyberCyan,
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.0,
    ),
  );
}
