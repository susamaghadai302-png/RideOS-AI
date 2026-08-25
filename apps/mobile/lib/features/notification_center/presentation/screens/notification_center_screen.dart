import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/premium_overlays.dart';
import '../../../../core/notifications/models/app_notification_model.dart';
import '../../../../core/notifications/services/notification_center_manager.dart';
import '../../../diagnostics/presentation/screens/vehicle_health_dashboard_screen.dart';
import '../../../garage/presentation/screens/vehicle_maintenance_screen.dart';
import '../../../ride_history/presentation/screens/ride_history_screen.dart';
import '../../../connected_vehicle/presentation/screens/connect_vehicle_screen.dart';
import '../../../../core/design_system/premium_navigation.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = ['ALL', 'CRITICAL', 'WARNING', 'INFO'];

  @override
  void initState() {
    super.initState();
    NotificationCenterManager().initialize(ref);
  }

  void _handleDeepLink(AppNotificationModel notif) {
    LuxAudioHapticsService.lightImpact();
    NotificationCenterManager().markAsRead(notif.id);

    if (notif.deepLinkRoute == 'diagnostics' || notif.deepLinkRoute == 'health') {
      Navigator.push(context, premiumRoute(const VehicleHealthDashboardScreen()));
    } else if (notif.deepLinkRoute == 'maintenance') {
      Navigator.push(context, premiumRoute(const VehicleMaintenanceScreen()));
    } else if (notif.deepLinkRoute == 'trips') {
      Navigator.push(context, premiumRoute(const RideHistoryScreen()));
    } else if (notif.deepLinkRoute == 'connect_vehicle') {
      Navigator.push(context, premiumRoute(const ConnectVehicleScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final allNotifs = ref.watch(notificationsListProvider);

    final filteredNotifs = allNotifs.where((n) {
      if (_selectedFilterIndex == 0) return true;
      if (_selectedFilterIndex == 1) return n.priority == NotificationPriority.critical;
      if (_selectedFilterIndex == 2) return n.priority == NotificationPriority.warning;
      return n.priority == NotificationPriority.info || n.priority == NotificationPriority.notice;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'ALERTS',
          style: RoadOSTypography.screenTitle.copyWith(fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 20),
            onPressed: () {
              LuxAudioHapticsService.lightImpact();
              NotificationCenterManager().markAllAsRead();
            },
          ),
        ],
      ),
      body: CinematicBackground(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Pills (Reference Design #8: ALL, CRITICAL, WARNING, INFO)
            Center(
              child: FuturisticPillTab(
                tabs: _filters,
                activeIndex: _selectedFilterIndex,
                onTabSelected: (index) {
                  setState(() => _selectedFilterIndex = index);
                },
              ),
            ),
            const SizedBox(height: 20),

            Expanded(
              child: filteredNotifs.isEmpty
                  ? _buildDefaultAlertsList()
                  : ListView.builder(
                      itemCount: filteredNotifs.length,
                      itemBuilder: (context, index) {
                        return _buildAlertCard(filteredNotifs[index]);
                      },
                    ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildDefaultAlertsList() {
    final mockAlerts = [
      {
        'title': 'LOW FUEL WARNING',
        'desc': 'Fuel level is below 10%',
        'time': '2 min ago',
        'icon': Icons.local_gas_station_rounded,
        'color': RoadOSColors.errorCrimson,
      },
      {
        'title': 'HIGH ENGINE TEMPERATURE',
        'desc': 'Temperature reached 102 degC',
        'time': '15 min ago',
        'icon': Icons.warning_amber_rounded,
        'color': RoadOSColors.warningAmber,
      },
      {
        'title': 'RIDE COMPLETED',
        'desc': 'Your ride has been saved',
        'time': '1 hr ago',
        'icon': Icons.info_outline_rounded,
        'color': RoadOSColors.cyberCyan,
      },
      {
        'title': 'SERVICE REMINDER',
        'desc': 'Next service in 850 km',
        'time': '1 day ago',
        'icon': Icons.build_outlined,
        'color': RoadOSColors.neonViolet,
      },
    ];

    return ListView.builder(
      itemCount: mockAlerts.length,
      itemBuilder: (context, index) {
        final alert = mockAlerts[index];
        final color = alert['color'] as Color;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _LuxAlertCard(
            title: alert['title'] as String,
            desc: alert['desc'] as String,
            time: alert['time'] as String,
            icon: alert['icon'] as IconData,
            color: color,
            onTap: () {
              LuxAudioHapticsService.lightImpact();
              showLuxSnack(context, alert['title'] as String, variant: LuxSnackVariant.info);
            },
          ),
        );
      },
    );
  }

  Widget _buildAlertCard(AppNotificationModel notif) {
    Color color = RoadOSColors.cyberCyan;
    IconData icon = Icons.notifications_rounded;

    if (notif.priority == NotificationPriority.critical) {
      color = RoadOSColors.errorCrimson;
      icon = Icons.error_outline_rounded;
    } else if (notif.priority == NotificationPriority.warning) {
      color = RoadOSColors.warningAmber;
      icon = Icons.warning_amber_rounded;
    }

    final timeStr = '${notif.timestamp.hour}:${notif.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _LuxAlertCard(
        title: notif.title.toUpperCase(),
        desc: notif.body,
        time: timeStr,
        icon: icon,
        color: color,
        isUnread: notif.status == NotificationStatus.unread,
        onTap: () => _handleDeepLink(notif),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  _LuxAlertCard — premium notification card with glow border + unread dot
// ─────────────────────────────────────────────────────────────────────────────
class _LuxAlertCard extends StatelessWidget {
  final String title;
  final String desc;
  final String time;
  final IconData icon;
  final Color color;
  final bool isUnread;
  final VoidCallback onTap;

  const _LuxAlertCard({
    required this.title,
    required this.desc,
    required this.time,
    required this.icon,
    required this.color,
    this.isUnread = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RoadOSCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon with coloured glow ring
            Stack(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                    border: Border.all(
                        color: color.withValues(alpha: 0.45), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 10,
                          spreadRadius: -2),
                    ],
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                if (isUnread)
                  Positioned(
                    top: 0, right: 0,
                    child: Container(
                      width: 9, height: 9,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.black, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            color: isUnread ? Colors.white : RoadOSColors.platinumWhite.withValues(alpha: 0.75),
                            fontSize: 12.5,
                            fontWeight: isUnread ? FontWeight.w900 : FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: TextStyle(
                          color: RoadOSColors.textMuted.withValues(alpha: 0.6),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    desc,
                    style: const TextStyle(
                        color: RoadOSColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  // Priority chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      isUnread ? 'UNREAD' : 'READ',
                      style: TextStyle(
                          color: color,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
