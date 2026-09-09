import 'package:flutter/material.dart';
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
import '../../../../core/widgets/cinematic_background.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() => _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  int _selectedFilterIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    NotificationCenterManager().initialize(ref);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
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

  void _showNotificationDetail(AppNotificationModel notif) {
    LuxAudioHapticsService.lightImpact();
    NotificationCenterManager().markAsRead(notif.id);

    Color priorityColor = RoadOSColors.cyberCyan;
    String priorityLabel = 'INFORMATION';
    IconData priorityIcon = Icons.info_outline_rounded;

    if (notif.priority == NotificationPriority.critical) {
      priorityColor = RoadOSColors.errorCrimson;
      priorityLabel = 'CRITICAL ADVISORY';
      priorityIcon = Icons.error_outline_rounded;
    } else if (notif.priority == NotificationPriority.warning) {
      priorityColor = RoadOSColors.warningAmber;
      priorityLabel = 'SYSTEM WARNING';
      priorityIcon = Icons.warning_amber_rounded;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D1322),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: priorityColor.withValues(alpha: 0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: priorityColor.withValues(alpha: 0.2),
                blurRadius: 30,
                spreadRadius: -5,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: priorityColor.withValues(alpha: 0.15),
                      border: Border.all(color: priorityColor.withValues(alpha: 0.5)),
                    ),
                    child: Icon(priorityIcon, color: priorityColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: priorityColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            priorityLabel,
                            style: TextStyle(
                              color: priorityColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF131C30),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Text(
                  notif.body,
                  style: const TextStyle(
                    color: RoadOSColors.platinumWhite,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.access_time_rounded, size: 14, color: RoadOSColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Logged at ${_formatTimestamp(notif.timestamp)}',
                    style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11.5),
                  ),
                  const Spacer(),
                  if (notif.deepLinkRoute != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: RoadOSColors.cyberCyan.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'ROUTE: ${notif.deepLinkRoute?.toUpperCase()}',
                        style: const TextStyle(
                          color: RoadOSColors.cyberCyan,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        NotificationCenterManager().deleteNotification(notif.id);
                        Navigator.pop(context);
                        showLuxSnack(context, 'Alert dismissed', variant: LuxSnackVariant.info);
                      },
                      child: const Text('DISMISS', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  if (notif.deepLinkRoute != null) ...[
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: priorityColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _handleDeepLink(notif);
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('OPEN MODULE', style: TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final allNotifs = ref.watch(notificationsListProvider);

    final criticalCount = allNotifs.where((n) => n.priority == NotificationPriority.critical).length;
    final warningCount = allNotifs.where((n) => n.priority == NotificationPriority.warning).length;
    final infoCount = allNotifs.where((n) => n.priority == NotificationPriority.info || n.priority == NotificationPriority.notice).length;
    final unreadCount = allNotifs.where((n) => n.status == NotificationStatus.unread).length;

    final filterTabs = [
      'ALL (${allNotifs.length})',
      'CRITICAL ($criticalCount)',
      'WARNING ($warningCount)',
      'INFO ($infoCount)',
    ];

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
          onPressed: () {
            LuxAudioHapticsService.lightImpact();
            Navigator.pop(context);
          },
        ),
        title: Column(
          children: [
            Text(
              'COCKPIT ADVISORIES',
              style: RoadOSTypography.screenTitle.copyWith(fontSize: 15, letterSpacing: 1.2),
            ),
            Text(
              unreadCount > 0 ? '$unreadCount ACTIVE UNREAD' : 'BUFFER SYNCHRONIZED',
              style: TextStyle(
                color: unreadCount > 0 ? RoadOSColors.neonViolet : RoadOSColors.cyberCyan,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          if (allNotifs.isNotEmpty)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 22),
              color: const Color(0xFF0F172A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: Colors.white12),
              ),
              onSelected: (val) async {
                LuxAudioHapticsService.mediumImpact();
                if (val == 'read_all') {
                  await NotificationCenterManager().markAllAsRead();
                  if (context.mounted) {
                    showLuxSnack(context, 'All advisories marked as read', variant: LuxSnackVariant.success);
                  }
                } else if (val == 'clear_all') {
                  await NotificationCenterManager().clearAll();
                  if (context.mounted) {
                    showLuxSnack(context, 'Alert buffer cleared', variant: LuxSnackVariant.info);
                  }
                } else if (val == 'seed_sample') {
                  await NotificationCenterManager().seedSampleAlerts();
                  if (context.mounted) {
                    showLuxSnack(context, 'Diagnostic alerts simulated', variant: LuxSnackVariant.success);
                  }
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'read_all',
                  child: Row(
                    children: [
                      Icon(Icons.done_all_rounded, color: RoadOSColors.cyberCyan, size: 18),
                      SizedBox(width: 10),
                      Text('Mark All as Read', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      Icon(Icons.delete_sweep_rounded, color: RoadOSColors.errorCrimson, size: 18),
                      SizedBox(width: 10),
                      Text('Clear Alert Buffer', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'seed_sample',
                  child: Row(
                    children: [
                      Icon(Icons.radar_rounded, color: RoadOSColors.neonViolet, size: 18),
                      SizedBox(width: 10),
                      Text('Simulate Telemetry Alerts', style: TextStyle(color: Colors.white, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: CinematicBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Radar Diagnostic Banner
                _buildSystemStatusBanner(criticalCount, warningCount),
                const SizedBox(height: 14),

                // 2. Futuristic Filter Tab Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(filterTabs.length, (index) {
                      final isSelected = _selectedFilterIndex == index;
                      Color accentColor = RoadOSColors.cyberCyan;
                      if (index == 1) accentColor = RoadOSColors.errorCrimson;
                      if (index == 2) accentColor = RoadOSColors.warningAmber;

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            LuxAudioHapticsService.selectionClick();
                            setState(() => _selectedFilterIndex = index);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? accentColor.withValues(alpha: 0.18)
                                  : const Color(0xFF101626),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? accentColor.withValues(alpha: 0.7)
                                    : Colors.white.withValues(alpha: 0.08),
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: accentColor.withValues(alpha: 0.25),
                                        blurRadius: 10,
                                        spreadRadius: -2,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              filterTabs[index],
                              style: TextStyle(
                                color: isSelected ? Colors.white : RoadOSColors.textMuted,
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Notification Stream List or Empty State
                Expanded(
                  child: filteredNotifs.isEmpty
                      ? _buildEmptyState(allNotifs.isEmpty)
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredNotifs.length,
                          itemBuilder: (context, index) {
                            final notif = filteredNotifs[index];
                            return Dismissible(
                              key: Key(notif.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (direction) {
                                LuxAudioHapticsService.mediumImpact();
                                NotificationCenterManager().deleteNotification(notif.id);
                                showLuxSnack(context, 'Advisory dismissed', variant: LuxSnackVariant.info);
                              },
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      RoadOSColors.errorCrimson.withValues(alpha: 0.4),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
                                    SizedBox(width: 8),
                                    Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)),
                                  ],
                                ),
                              ),
                              child: _buildAlertCard(notif),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSystemStatusBanner(int criticalCount, int warningCount) {
    Color statusColor = RoadOSColors.cyberCyan;
    String statusText = 'ALL TELEMETRY NOMINAL';
    String subText = 'Cockpit live sensors active · 0 fault codes';
    IconData statusIcon = Icons.shield_outlined;

    if (criticalCount > 0) {
      statusColor = RoadOSColors.errorCrimson;
      statusText = '$criticalCount CRITICAL ADVISOR${criticalCount > 1 ? "IES" : "Y"}';
      subText = 'Immediate inspection required by rider';
      statusIcon = Icons.warning_rounded;
    } else if (warningCount > 0) {
      statusColor = RoadOSColors.warningAmber;
      statusText = '$warningCount SYSTEM WARNING${warningCount > 1 ? "S" : ""}';
      subText = 'Non-critical telemetry advisories detected';
      statusIcon = Icons.info_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: -4,
          ),
        ],
      ),
      child: Row(
        children: [
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withValues(alpha: 0.15),
                border: Border.all(color: statusColor.withValues(alpha: 0.6), width: 1.5),
              ),
              child: Icon(statusIcon, color: statusColor, size: 18),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subText,
                  style: const TextStyle(
                    color: RoadOSColors.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_tethering_rounded, color: RoadOSColors.cyberCyan, size: 12),
                SizedBox(width: 4),
                Text('LIVE', style: TextStyle(color: Colors.white70, fontSize: 9.5, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isEmptyBuffer) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: RoadOSColors.cyberCyan.withValues(alpha: 0.08),
                  border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.3), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: RoadOSColors.cyberCyan.withValues(alpha: 0.2),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(Icons.check_circle_outline_rounded, color: RoadOSColors.cyberCyan, size: 44),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'ALL SYSTEMS NOMINAL',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'No pending advisories or warning codes in this category. Telemetry stream is clear.',
                textAlign: TextAlign.center,
                style: TextStyle(color: RoadOSColors.textMuted, fontSize: 12, height: 1.4),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF162238),
                foregroundColor: RoadOSColors.cyberCyan,
                side: BorderSide(color: RoadOSColors.cyberCyan.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              onPressed: () async {
                LuxAudioHapticsService.mediumImpact();
                await NotificationCenterManager().seedSampleAlerts();
                if (context.mounted) {
                  showLuxSnack(context, 'Telemetry diagnostic alerts simulated', variant: LuxSnackVariant.success);
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text(
                'SIMULATE DIAGNOSTIC ADVISORIES',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(AppNotificationModel notif) {
    Color color = RoadOSColors.cyberCyan;
    IconData icon = Icons.notifications_rounded;
    String categoryTag = 'COCKPIT';

    if (notif.priority == NotificationPriority.critical) {
      color = RoadOSColors.errorCrimson;
      icon = Icons.error_outline_rounded;
      categoryTag = 'CRITICAL FAULT';
    } else if (notif.priority == NotificationPriority.warning) {
      color = RoadOSColors.warningAmber;
      icon = Icons.warning_amber_rounded;
      categoryTag = 'ADVISORY';
    } else if (notif.category == NotificationCategory.maintenance) {
      color = RoadOSColors.neonViolet;
      icon = Icons.build_circle_outlined;
      categoryTag = 'MAINTENANCE';
    }

    final timeStr = _formatTimestamp(notif.timestamp);
    final isUnread = notif.status == NotificationStatus.unread;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _showNotificationDetail(notif),
        child: Container(
          decoration: BoxDecoration(
            color: isUnread ? const Color(0xFF111827) : const Color(0xFF0C121E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? color.withValues(alpha: 0.45) : Colors.white.withValues(alpha: 0.07),
              width: isUnread ? 1.4 : 1,
            ),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.16),
                      blurRadius: 14,
                      spreadRadius: -3,
                    ),
                  ]
                : null,
          ),
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
                      border: Border.all(color: color.withValues(alpha: 0.45), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.25),
                          blurRadius: 10,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  if (isUnread)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF0C121E), width: 2),
                          boxShadow: [
                            BoxShadow(color: color, blurRadius: 6),
                          ],
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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            categoryTag,
                            style: TextStyle(
                              color: color,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: RoadOSColors.textMuted.withValues(alpha: 0.7),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notif.title,
                      style: TextStyle(
                        color: isUnread ? Colors.white : RoadOSColors.platinumWhite.withValues(alpha: 0.85),
                        fontSize: 13,
                        fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notif.body,
                      style: const TextStyle(
                        color: RoadOSColors.textMuted,
                        fontSize: 11.5,
                        height: 1.35,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (notif.deepLinkRoute != null) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _handleDeepLink(notif),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'OPEN DETAILS',
                              style: TextStyle(
                                color: color,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, color: color, size: 12),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
