import 'dart:async';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../analytics/core/services/ride_intelligence_service.dart';
import '../../../maintenance/core/services/predictive_maintenance_engine.dart';
import '../../../push_notifications/core/services/ai_notification_service.dart';

class TypewriterText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Duration typingSpeed;
  final VoidCallback? onComplete;

  const TypewriterText({
    super.key,
    required this.text,
    this.style,
    this.typingSpeed = const Duration(milliseconds: 15),
    this.onComplete,
  });

  @override
  State<TypewriterText> createState() => _TypewriterTextState();
}

class _TypewriterTextState extends State<TypewriterText> {
  String _displayedText = '';
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void didUpdateWidget(covariant TypewriterText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _startTyping();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    _timer?.cancel();
    setState(() {
      _displayedText = '';
      _currentIndex = 0;
    });

    _timer = Timer.periodic(widget.typingSpeed, (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_currentIndex < widget.text.length) {
        setState(() {
          _displayedText = widget.text.substring(0, _currentIndex + 1);
          _currentIndex++;
        });
      } else {
        timer.cancel();
        widget.onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_displayedText.isEmpty) {
      return const SizedBox(height: 20);
    }
    return MarkdownBody(
      data: _displayedText,
      shrinkWrap: true,
      styleSheet: MarkdownStyleSheet(
        p: widget.style ?? const TextStyle(color: RoadOSColors.platinumWhite, fontSize: 13, height: 1.5),
        strong: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        em: const TextStyle(fontStyle: FontStyle.italic, color: RoadOSColors.textMuted),
        listBullet: const TextStyle(color: RoadOSColors.cyberCyan),
        code: const TextStyle(
          color: RoadOSColors.hyperOrange,
          backgroundColor: Colors.transparent,
          fontFamily: 'monospace',
          fontSize: 12,
        ),
        codeblockPadding: const EdgeInsets.all(8),
        codeblockDecoration: BoxDecoration(
          color: Colors.black45,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF334155)),
        ),
      ),
    );
  }
}

class MarkdownAiMessageWidget extends StatelessWidget {
  final String text;
  final bool isAnimated;
  final VoidCallback? onComplete;

  const MarkdownAiMessageWidget({
    super.key,
    required this.text,
    this.isAnimated = true,
    this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1E).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              gradient: LuxGradients.cyberPurple,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: isAnimated
                ? TypewriterText(
                    text: text,
                    onComplete: onComplete,
                  )
                : MarkdownBody(
                    data: text,
                    shrinkWrap: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: RoadOSColors.platinumWhite, fontSize: 13, height: 1.5),
                      strong: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
                      listBullet: const TextStyle(color: RoadOSColors.cyberCyan),
                      code: const TextStyle(
                        color: RoadOSColors.hyperOrange,
                        backgroundColor: Colors.transparent,
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                      codeblockPadding: const EdgeInsets.all(8),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF334155)),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class MarkdownUserMessageWidget extends StatelessWidget {
  final String text;

  const MarkdownUserMessageWidget({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.82,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF141A29),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1F293D)),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
        ),
      ),
    );
  }
}

class NeuralVoiceOrbWidget extends StatefulWidget {
  final bool isListening;
  final String wakeWordStatus;
  final VoidCallback? onTap;

  const NeuralVoiceOrbWidget({
    super.key,
    this.isListening = true,
    this.wakeWordStatus = 'Listening for "Hey RideOS"...',
    this.onTap,
  });

  @override
  State<NeuralVoiceOrbWidget> createState() => _NeuralVoiceOrbWidgetState();
}

class _NeuralVoiceOrbWidgetState extends State<NeuralVoiceOrbWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        LuxAudioHapticsService.mediumImpact();
        widget.onTap?.call();
      },
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = 1.0 + (_pulseController.value * 0.12);
          return Column(
            children: [
              Transform.scale(
                scale: scale,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LuxGradients.cyberPurple,
                    boxShadow: LuxShadows.glassGlow(const Color(0xFF8B5CF6)),
                  ),
                  child: Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LuxGradients.quantumCyan,
                      ),
                      child: Icon(
                        widget.isListening ? Icons.graphic_eq_rounded : Icons.mic_none_rounded,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.wakeWordStatus,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoadOSColors.cyberCyan),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PredictiveMaintenanceGridWidget extends StatelessWidget {
  final PredictiveMaintenanceEngine engine = PredictiveMaintenanceEngine();

  PredictiveMaintenanceGridWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final items = engine.getPredictions();
    final totalCost = engine.calculateTotalEstimatedCost();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('PREDICTIVE MAINTENANCE ENGINE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
            Text('Est. Total: \$${totalCost.round()}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoadOSColors.hyperOrange)),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.35,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final color = item.isUrgent
                ? RoadOSColors.errorCrimson
                : (item.remainingLifePct > 60 ? RoadOSColors.apexEmerald : RoadOSColors.solarGold);

            return RoadOSCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isUrgent)
                        const Icon(Icons.warning_amber_rounded, color: RoadOSColors.errorCrimson, size: 16),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${item.remainingLifePct.round()}% LIFE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color)),
                          Text('\$${item.estimatedCostUsd.round()}', style: const TextStyle(fontSize: 10, color: RoadOSColors.textMuted, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: item.remainingLifePct / 100.0,
                          minHeight: 6,
                          backgroundColor: Colors.black45,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${item.remainingKm} km remaining',
                    style: const TextStyle(fontSize: 9, color: RoadOSColors.textMuted),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class RideIntelligenceRadarWidget extends StatelessWidget {
  final RideIntelligenceService service = RideIntelligenceService();

  RideIntelligenceRadarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final habit = service.analyzeCurrentRide();

    return RoadOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.auto_graph_rounded, color: RoadOSColors.hyperOrange, size: 20),
                  SizedBox(width: 8),
                  Text('AI RIDE INTELLIGENCE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: RoadOSColors.hyperOrange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: RoadOSColors.hyperOrange),
                ),
                child: Text(
                  'SAFETY: ${habit.overallSafetyScore.round()}/100',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: RoadOSColors.hyperOrange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildScoreGauge('RIDE SCORE', habit.overallRideScore, RoadOSColors.cyberCyan),
              _buildScoreGauge('ECO SCORE', habit.overallEcoScore, RoadOSColors.apexEmerald),
              _buildScoreGauge('FUEL EFF.', habit.fuelEfficiencyScore, RoadOSColors.solarGold),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: const Color(0xFF334155), height: 1),
          const SizedBox(height: 12),
          _buildHabitBar('Braking Smoothness', habit.brakingSmoothnessScore, RoadOSColors.cyberCyan),
          const SizedBox(height: 6),
          _buildHabitBar('Cornering Lean Stability', habit.corneringLeanStabilityScore, RoadOSColors.hyperOrange),
          const SizedBox(height: 6),
          _buildHabitBar('Acceleration Index', habit.accelerationIndexScore, RoadOSColors.solarGold),
          const SizedBox(height: 6),
          _buildHabitBar('Night Riding Safety', habit.nightRidingSafetyScore, const Color(0xFF8B5CF6)),
          const SizedBox(height: 6),
          _buildHabitBar('Rain Riding Control', habit.rainRidingControlScore, RoadOSColors.electricBlue),
        ],
      ),
    );
  }

  Widget _buildScoreGauge(String title, double score, Color color) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 54,
              height: 54,
              child: CircularProgressIndicator(
                value: score / 100.0,
                strokeWidth: 5,
                backgroundColor: Colors.black38,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '${score.round()}',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: RoadOSColors.textMuted)),
      ],
    );
  }

  Widget _buildHabitBar(String label, double val, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 140,
          child: Text(label, style: const TextStyle(fontSize: 10, color: RoadOSColors.platinumWhite)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: val / 100.0,
              minHeight: 6,
              backgroundColor: Colors.black38,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('${val.round()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}

class SmartRideDashboardCardsWidget extends StatelessWidget {
  final RideIntelligenceService service = RideIntelligenceService();

  SmartRideDashboardCardsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = service.getDashboardMetrics();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('SMART RIDE DASHBOARD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
        const SizedBox(height: 10),
        SizedBox(
          height: 100,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            children: [
              _buildMetricCard("TODAY'S RIDE", '${metrics.todaysDistanceKm} km', Icons.today_rounded, RoadOSColors.cyberCyan),
              _buildMetricCard('WEEKLY RIDE', '${metrics.weeklyDistanceKm} km', Icons.calendar_view_week_rounded, RoadOSColors.hyperOrange),
              _buildMetricCard('MONTHLY RIDE', '${metrics.monthlyDistanceKm} km', Icons.calendar_month_rounded, const Color(0xFF8B5CF6)),
              _buildMetricCard('TOTAL DISTANCE', '${metrics.totalLifetimeKm} km', Icons.map_rounded, RoadOSColors.solarGold),
              _buildMetricCard('FUEL SAVED', '${metrics.fuelSavedLiters} L', Icons.local_gas_station_rounded, RoadOSColors.apexEmerald),
              _buildMetricCard('RIDING TIME', metrics.totalRidingTimeStr, Icons.timer_rounded, RoadOSColors.electricBlue),
              _buildMetricCard('CARBON SAVED', '${metrics.carbonSavedKg} kg', Icons.eco_rounded, RoadOSColors.apexEmerald),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String val, IconData icon, Color color) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 10),
      child: RoadOSCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: color, size: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(val, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
                Text(title, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: RoadOSColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AiNotificationsDrawerWidget extends StatelessWidget {
  final AiNotificationService service = AiNotificationService();

  AiNotificationsDrawerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final notifs = service.activeNotifications;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Row(
              children: [
                Icon(Icons.notifications_active_rounded, color: RoadOSColors.warningAmber, size: 20),
                SizedBox(width: 8),
                Text('AI SMART NOTIFICATIONS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
              ],
            ),
            Text('${notifs.length} Alerts', style: const TextStyle(fontSize: 10, color: RoadOSColors.textMuted, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 10),
        ...notifs.map((n) {
          final isCritical = n.priority == NotificationPriority.critical;
          final color = isCritical ? RoadOSColors.errorCrimson : RoadOSColors.warningAmber;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: RoadOSCard(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(isCritical ? Icons.report_problem_rounded : Icons.info_outline_rounded, color: color, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                        Text(n.message, style: const TextStyle(fontSize: 10, color: RoadOSColors.textMuted)),
                      ],
                    ),
                  ),
                  if (n.actionLabel != null) ...[
                    const SizedBox(width: 6),
                    ElevatedButton(
                      onPressed: () {
                        LuxAudioHapticsService.heavyImpact();
                        showLuxSnack(context, 'Executed action: ${n.actionLabel}', variant: LuxSnackVariant.info);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.withValues(alpha: 0.2),
                        foregroundColor: color,
                        elevation: 0,
                        side: BorderSide(color: color),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                      child: Text(n.actionLabel!, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class SmartTripPlannerWidget extends StatefulWidget {
  const SmartTripPlannerWidget({super.key});

  @override
  State<SmartTripPlannerWidget> createState() => _SmartTripPlannerWidgetState();
}

class _SmartTripPlannerWidgetState extends State<SmartTripPlannerWidget> {
  bool _isGenerating = false;
  bool _planGenerated = false;

  void _generatePlan() async {
    LuxAudioHapticsService.mediumImpact();
    setState(() {
      _isGenerating = true;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isGenerating = false;
        _planGenerated = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.route_rounded, color: const Color(0xFF8B5CF6), size: 20),
                  SizedBox(width: 8),
                  Text('SMART TRIP PLANNER', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Text('AI Multi-Stop', style: TextStyle(fontSize: 10, color: const Color(0xFF8B5CF6), fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Generates complete ride itinerary with fuel stops, food, hotels, weather warnings & elevation profile.',
            style: TextStyle(fontSize: 10, color: RoadOSColors.textMuted),
          ),
          const SizedBox(height: 12),
          if (_isGenerating) ...[
            const LinearProgressIndicator(color: const Color(0xFF8B5CF6), backgroundColor: Colors.black26),
            const SizedBox(height: 8),
            const Center(child: Text('AI Optimizing Multi-Stop Motorcycle Route...', style: TextStyle(fontSize: 10, color: const Color(0xFF8B5CF6)))),
          ] else if (_planGenerated) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF8B5CF6)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ROUTE: Big Sur Alpine Coast Loop (340 km)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                  SizedBox(height: 4),
                  Text('| Fuel Stop: Chevron High Octane at Km 120\n| Rest & Food: Nepenthe Cliff Restaurant at Km 185\n| Hotel: Ventana Big Sur Resort\n| Weather: Clear 22 degC | Rain 0%\n| Elevation Gain: 1,420 m', style: TextStyle(fontSize: 10, color: RoadOSColors.textMuted)),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generatePlan,
            icon: const Icon(Icons.auto_awesome_rounded, size: 16),
            label: Text(_planGenerated ? 'REGENERATE TRIP PLAN' : 'GENERATE AI RIDE PLAN', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
              foregroundColor: const Color(0xFF8B5CF6),
              minimumSize: const Size(double.infinity, 40),
              side: const BorderSide(color: const Color(0xFF8B5CF6)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class RiderProfileLeaderboardWidget extends StatelessWidget {
  const RiderProfileLeaderboardWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return RoadOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.emoji_events_rounded, color: RoadOSColors.solarGold, size: 20),
                  SizedBox(width: 8),
                  Text('RIDER PROFILE & LEADERBOARD', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: RoadOSColors.solarGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: RoadOSColors.solarGold),
                ),
                child: const Text('LEVEL 42 | APEX LEGEND', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: RoadOSColors.solarGold)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBadgeItem('APEX LEAN', Icons.sports_motorsports_rounded, RoadOSColors.hyperOrange),
              _buildBadgeItem('RAIN MASTER', Icons.water_drop_rounded, RoadOSColors.electricBlue),
              _buildBadgeItem('IRON BUTT', Icons.map_rounded, RoadOSColors.solarGold),
              _buildBadgeItem('SAFETY KING', Icons.shield_rounded, RoadOSColors.apexEmerald),
            ],
          ),
          const SizedBox(height: 14),
          const Text('GLOBAL RIDER LEADERBOARD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RoadOSColors.textMuted)),
          const SizedBox(height: 8),
          _buildLeaderboardRow('#1', 'Alex Vance (Ducati Panigale V4)', '9,420 XP', true),
          _buildLeaderboardRow('#2', 'Elena Rostova (BMW S1000RR)', '8,950 XP', false),
          _buildLeaderboardRow('#3', 'Rider (You) (Kawasaki Ninja ZX-10R)', '8,420 XP', false, isYou: true),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(String title, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 4),
        Text(title, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: RoadOSColors.platinumWhite)),
      ],
    );
  }

  Widget _buildLeaderboardRow(String rank, String name, String xp, bool isFirst, {bool isYou = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isYou ? RoadOSColors.solarGold.withValues(alpha: 0.15) : Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isYou ? RoadOSColors.solarGold : const Color(0xFF334155)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(rank, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isFirst ? RoadOSColors.solarGold : RoadOSColors.platinumWhite)),
              const SizedBox(width: 10),
              Text(name, style: TextStyle(fontSize: 11, fontWeight: isYou ? FontWeight.bold : FontWeight.normal, color: RoadOSColors.platinumWhite)),
            ],
          ),
          Text(xp, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: RoadOSColors.cyberCyan)),
        ],
      ),
    );
  }
}
