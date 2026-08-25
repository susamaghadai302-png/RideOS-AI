import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_health/services/diagnostic_manager.dart';
import '../../../../core/vehicle_health/services/maintenance_manager.dart';

class TimelineEntry {
  final String title;
  final String description;
  final String badgeText;
  final Color badgeColor;
  final IconData icon;
  final DateTime timestamp;

  const TimelineEntry({
    required this.title,
    required this.description,
    required this.badgeText,
    required this.badgeColor,
    required this.icon,
    required this.timestamp,
  });
}

class VehicleHealthTimelineWidget extends ConsumerWidget {
  const VehicleHealthTimelineWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dtcs = ref.watch(activeDiagnosticsProvider);
    final maintenanceLogs = ref.watch(maintenanceRecordsProvider);

    final List<TimelineEntry> entries = [];

    for (final dtc in dtcs) {
      entries.add(
        TimelineEntry(
          title: '${dtc.code} — ${dtc.source}',
          description: dtc.description,
          badgeText: dtc.active ? 'ACTIVE FAULT' : 'RESOLVED',
          badgeColor: dtc.active ? Colors.redAccent : RoadOSColors.apexEmerald,
          icon: Icons.warning_amber_rounded,
          timestamp: dtc.lastSeen,
        ),
      );
    }

    for (final m in maintenanceLogs) {
      entries.add(
        TimelineEntry(
          title: 'Service: ${m.serviceType.toUpperCase()}',
          description: '${m.odometerLabel} | ${m.serviceProvider.isNotEmpty ? m.serviceProvider : "Owner Performed"}',
          badgeText: 'MAINTENANCE',
          badgeColor: RoadOSColors.electricBlue,
          icon: Icons.build_circle_outlined,
          timestamp: m.date,
        ),
      );
    }

    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (entries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF070B18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A2035)),
        ),
        child: const Center(
          child: Text(
            'No diagnostic or maintenance events recorded yet.\nConnect vehicle or log service history to populate timeline.',
            textAlign: TextAlign.center,
            style: TextStyle(color: RoadOSColors.textMuted, fontSize: 12, height: 1.5),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF070B18),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1A2035)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF080C1A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(entry.icon, color: entry.badgeColor, size: 18),
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
                            entry.title,
                            style: const TextStyle(
                              color: RoadOSColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: entry.badgeColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            entry.badgeText,
                            style: TextStyle(color: entry.badgeColor, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      entry.description,
                      style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11, height: 1.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      entry.timestamp.toLocal().toString().substring(0, 16),
                      style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
