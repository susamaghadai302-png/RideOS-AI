import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../domain/models/advanced_notification_models.dart';
import '../../core/services/advanced_notification_engine.dart';
import '../../../../core/widgets/cinematic_background.dart';

class AdvancedNotificationCenterScreen extends StatefulWidget {
  const AdvancedNotificationCenterScreen({super.key});

  @override
  State<AdvancedNotificationCenterScreen> createState() => _AdvancedNotificationCenterScreenState();
}

class _AdvancedNotificationCenterScreenState extends State<AdvancedNotificationCenterScreen> {
  final _engine = AdvancedNotificationEngine();
  AlertCategory? _selectedCategory;
  String _aiReply = '';
  final TextEditingController _queryController = TextEditingController();

  void _sendQuery(String prompt) {
    if (prompt.trim().isEmpty) return;
    final res = _engine.processNotificationAiQuery(prompt.trim());
    setState(() {
      _aiReply = res;
      _queryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifications = _engine.getNotifications(categoryFilter: _selectedCategory);
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF060912),
        title: const Text(
          'NOTIFICATION CENTER & ALERTS',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () {
        LuxAudioHapticsService.lightImpact();
                setState(() {
                  _engine.markAllAsRead();
                });
              },
              child: const Text('Mark All Read', style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: CinematicBackground(child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Category Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip('All Alerts', null),
                _buildCategoryChip('Safety', AlertCategory.safety),
                _buildCategoryChip('Maintenance', AlertCategory.maintenance),
                _buildCategoryChip('Health', AlertCategory.vehicleHealth),
                _buildCategoryChip('Navigation', AlertCategory.navigationTrip),
                _buildCategoryChip('Fleet', AlertCategory.fleet),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Notification Cards
          if (notifications.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: const Column(
                children: [
                  Icon(Icons.notifications_none_rounded, color: RoadOSColors.textMuted, size: 40),
                  SizedBox(height: 10),
                  Text('Zero Active Alerts', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('All vehicle and safety parameters are nominal.', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                ],
              ),
            )
          else
            ...notifications.map((n) => _buildNotificationCard(n)),

          const SizedBox(height: 16),

          // Notification AI Assistant
          const Text('NOTIFICATION AI ASSISTANT', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPromptChip('Show my unread notifications'),
                _buildPromptChip('Are there any critical alerts?'),
                _buildPromptChip('Mark all as read'),
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
                    hintText: 'Ask about unread alerts, maintenance reminders...',
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
                  backgroundColor: RoadOSColors.electricBlue,
                  foregroundColor: Colors.white,
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

  Widget _buildCategoryChip(String label, AlertCategory? cat) {
    final isSelected = _selectedCategory == cat;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = cat),
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? RoadOSColors.electricBlue : RoadOSColors.cardSurface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.borderTranslucent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : RoadOSColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(RiderNotificationItem n) {
    Color sevColor = RoadOSColors.cyberCyan;
    if (n.severity == AlertSeverity.high) sevColor = Colors.amberAccent;
    if (n.severity == AlertSeverity.critical) sevColor = Colors.redAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: n.isRead ? RoadOSColors.obsidianSurface : RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: n.isRead ? RoadOSColors.borderTranslucent : sevColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: n.isRead ? Colors.transparent : sevColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(n.vehicleName, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: sevColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  n.severity.label,
                  style: TextStyle(color: sevColor, fontSize: 8, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(n.title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(n.message, style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 10)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(n.category.label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 8)),
              if (!n.isRead)
                GestureDetector(
                  onTap: () {
        LuxAudioHapticsService.lightImpact();
                    setState(() {
                      _engine.markAsRead(n.id);
                    });
                  },
                  child: const Text('Mark Read', style: TextStyle(color: RoadOSColors.cyberCyan, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
            ],
          ),
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
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF1A2035)),
        ),
        child: Text(prompt, style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
