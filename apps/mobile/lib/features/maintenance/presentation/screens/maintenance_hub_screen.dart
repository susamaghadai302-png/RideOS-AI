import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../domain/entities/maintenance_log_entity.dart';
import '../providers/maintenance_notifier.dart';
import '../providers/maintenance_state.dart';
import 'predictive_ride_intelligence_screen.dart';

class MaintenanceHubScreen extends ConsumerStatefulWidget {
  final VehicleProfile? vehicle;

  const MaintenanceHubScreen({super.key, this.vehicle});

  @override
  ConsumerState<MaintenanceHubScreen> createState() => _MaintenanceHubScreenState();
}

class _MaintenanceHubScreenState extends ConsumerState<MaintenanceHubScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadData() {
    final activeContext = ref.read(activeVehicleContextProvider);
    final vehicle = widget.vehicle ?? activeContext.profile;
    final bikeId = vehicle?.id ?? 'default-bike';
    final odo = activeContext.telemetry.odometer.value?.toInt() ?? 0;

    ref.read(maintenanceNotifierProvider.notifier).loadTasksForBike(
          bikeId,
          currentOdometerKm: odo,
          customIntervals: vehicle?.maintenanceIntervals,
        );
  }

  Color _getStatusColor(MaintenanceScheduleStatus status) {
    switch (status) {
      case MaintenanceScheduleStatus.optimal:
        return RoadOSColors.apexEmerald;
      case MaintenanceScheduleStatus.dueSoon:
        return RoadOSColors.cyberCyan;
      case MaintenanceScheduleStatus.dueNow:
        return RoadOSColors.hyperOrange;
      case MaintenanceScheduleStatus.overdue:
        return Colors.redAccent;
      case MaintenanceScheduleStatus.pendingOdometer:
        return Colors.grey;
    }
  }

  IconData _getTaskIcon(String taskType) {
    final type = taskType.toUpperCase();
    if (type.contains('OIL')) return Icons.oil_barrel_rounded;
    if (type.contains('CHAIN')) return Icons.link_rounded;
    if (type.contains('BRAKE')) return Icons.album_rounded;
    if (type.contains('TIRE')) return Icons.tire_repair_rounded;
    if (type.contains('SPARK')) return Icons.flash_on_rounded;
    if (type.contains('VALVE')) return Icons.settings_suggest_rounded;
    return Icons.build_rounded;
  }

  void _showLogServiceModal({String? preselectedTaskType}) {
    LuxAudioHapticsService.lightImpact();
    final activeContext = ref.read(activeVehicleContextProvider);
    final vehicle = widget.vehicle ?? activeContext.profile;
    final bikeId = vehicle?.id ?? 'default-bike';
    final state = ref.read(maintenanceNotifierProvider);

    String taskType = preselectedTaskType ?? MaintenanceTaskTypes.oilChange;
    final odoController = TextEditingController(
      text: state.currentOdometerKm > 0 ? state.currentOdometerKm.toString() : '0',
    );
    final intervalController = TextEditingController(
      text: MaintenanceTaskTypes.getDefaultIntervalKm(taskType).toString(),
    );
    final costController = TextEditingController();
    final providerController = TextEditingController();
    final notesController = TextEditingController();
    DateTime performedDate = DateTime.now();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: RoadOSGradients.liquidWaterGlass,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.4)),
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'LOG COMPLETED SERVICE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                                onPressed: () => Navigator.pop(ctx),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // 1. Task Type Dropdown
                          DropdownButtonFormField<String>(
                            initialValue: taskType,
                            dropdownColor: const Color(0xFF0A0F24),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Maintenance Task',
                              labelStyle: const TextStyle(color: RoadOSColors.textMuted),
                              filled: true,
                              fillColor: const Color(0x30101A38),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            items: MaintenanceTaskTypes.all.map((t) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(MaintenanceTaskTypes.getDisplayName(t)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() {
                                  taskType = val;
                                  intervalController.text =
                                      MaintenanceTaskTypes.getDefaultIntervalKm(val).toString();
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),

                          // 2. Odometer & Interval Row
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: odoController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Odometer (km)',
                                    labelStyle: const TextStyle(color: RoadOSColors.textMuted),
                                    filled: true,
                                    fillColor: const Color(0x30101A38),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: intervalController,
                                  keyboardType: TextInputType.number,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Next Due (km)',
                                    labelStyle: const TextStyle(color: RoadOSColors.textMuted),
                                    filled: true,
                                    fillColor: const Color(0x30101A38),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 3. Date & Cost Row
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: ctx,
                                      initialDate: performedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime.now().add(const Duration(days: 1)),
                                    );
                                    if (picked != null) {
                                      setModalState(() => performedDate = picked);
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                    decoration: BoxDecoration(
                                      color: const Color(0x30101A38),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.white24),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${performedDate.year}-${performedDate.month.toString().padLeft(2, '0')}-${performedDate.day.toString().padLeft(2, '0')}',
                                          style: const TextStyle(color: Colors.white, fontSize: 13),
                                        ),
                                        const Icon(Icons.calendar_today_rounded, color: RoadOSColors.cyberCyan, size: 16),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: costController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'Cost (\$)',
                                    labelStyle: const TextStyle(color: RoadOSColors.textMuted),
                                    filled: true,
                                    fillColor: const Color(0x30101A38),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // 4. Service Provider & Notes
                          TextField(
                            controller: providerController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Workshop / Service Provider',
                              labelStyle: const TextStyle(color: RoadOSColors.textMuted),
                              filled: true,
                              fillColor: const Color(0x30101A38),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: notesController,
                            maxLines: 2,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'Work Notes / Replaced Parts',
                              labelStyle: const TextStyle(color: RoadOSColors.textMuted),
                              filled: true,
                              fillColor: const Color(0x30101A38),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 5. Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: RoadOSColors.cyberCyan,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () async {
                                final km = int.tryParse(odoController.text) ?? 0;
                                final interval = int.tryParse(intervalController.text) ?? 500;
                                final cost = double.tryParse(costController.text);

                                if (km < 0) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Odometer reading cannot be negative')),
                                  );
                                  return;
                                }

                                final logEntry = MaintenanceLogEntity(
                                  id: 'maint-${DateTime.now().millisecondsSinceEpoch}',
                                  bikeId: bikeId,
                                  taskType: taskType,
                                  performedAtKm: km,
                                  performedAtDate: performedDate,
                                  nextDueKm: km + interval,
                                  notes: notesController.text.trim(),
                                  cost: cost,
                                  serviceProvider: providerController.text.trim().isNotEmpty
                                      ? providerController.text.trim()
                                      : null,
                                );

                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(ctx);
                                final success = await ref
                                    .read(maintenanceNotifierProvider.notifier)
                                    .addMaintenanceTask(
                                      logEntry,
                                      intervalKm: interval,
                                      customIntervals: vehicle?.maintenanceIntervals,
                                    );

                                if (mounted && success) {
                                  navigator.pop();
                                  messenger.showSnackBar(
                                    const SnackBar(
                                      backgroundColor: RoadOSColors.apexEmerald,
                                      content: Text('Maintenance logged and schedule updated.'),
                                    ),
                                  );
                                }
                              },
                              child: const Text(
                                'SAVE SERVICE RECORD',
                                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showEditOdometerModal() {
    final state = ref.read(maintenanceNotifierProvider);
    final controller = TextEditingController(text: state.currentOdometerKm.toString());

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF080D22),
          title: const Text('Update Vehicle Odometer', style: TextStyle(color: Colors.white, fontSize: 16)),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Odometer (km)',
              labelStyle: const TextStyle(color: RoadOSColors.textMuted),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: RoadOSColors.cyberCyan, foregroundColor: Colors.black),
              onPressed: () {
                final km = int.tryParse(controller.text);
                if (km != null && km >= 0) {
                  final activeContext = ref.read(activeVehicleContextProvider);
                  ref.read(maintenanceNotifierProvider.notifier).updateCurrentOdometer(
                        km,
                        customIntervals: (widget.vehicle ?? activeContext.profile)?.maintenanceIntervals,
                      );
                  Navigator.pop(ctx);
                }
              },
              child: const Text('UPDATE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(maintenanceNotifierProvider);
    final activeContext = ref.watch(activeVehicleContextProvider);
    final vehicle = widget.vehicle ?? activeContext.profile;

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
          vehicle?.fullName.toUpperCase() ?? 'VEHICLE UPKEEP & SERVICE',
          style: const TextStyle(
            color: RoadOSColors.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            fontSize: 14,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: RoadOSColors.neonViolet),
            tooltip: 'AI Predictive Intelligence',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PredictiveRideIntelligenceScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded, color: RoadOSColors.cyberCyan),
            tooltip: 'Log Service',
            onPressed: () => _showLogServiceModal(),
          ),
        ],
      ),
      body: CinematicBackground(
        child: SafeArea(
          child: RefreshIndicator(
            color: RoadOSColors.cyberCyan,
            backgroundColor: const Color(0xFF080D22),
            onRefresh: () async => _loadData(),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // 1. Top Metrics Banner
                _buildTopMetricsBanner(state),
                const SizedBox(height: 16),

                // 2. Tab Bar Selector
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0x30101A38),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: RoadOSColors.borderSubtle),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: RoadOSColors.cyberCyan.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.6)),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: Colors.white,
                    unselectedLabelColor: RoadOSColors.textMuted,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.0),
                    tabs: [
                      Tab(text: 'SCHEDULES (${state.schedules.length})'),
                      Tab(text: 'HISTORY (${state.tasks.length})'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Tab Content
                AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) {
                    if (state.isLoading) {
                      return const Padding(
                        padding: EdgeInsets.all(40.0),
                        child: Center(
                          child: CircularProgressIndicator(color: RoadOSColors.cyberCyan),
                        ),
                      );
                    }

                    if (_tabController.index == 0) {
                      return _buildSchedulesTab(state);
                    } else {
                      return _buildHistoryTab(state);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopMetricsBanner(MaintenanceState state) {
    final statusColor = state.hasUrgentMaintenance ? Colors.redAccent : RoadOSColors.apexEmerald;
    final statusText = state.hasUrgentMaintenance
        ? '${state.urgentSchedules.length} SERVICE(S) DUE NOW'
        : 'ALL SYSTEMS HEALTHY';

    return RoadOSCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('ODOMETER: ', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold)),
                  Text(
                    '${state.currentOdometerKm} km',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: _showEditOdometerModal,
                    child: const Icon(Icons.edit_note_rounded, color: RoadOSColors.cyberCyan, size: 18),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.6)),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: RoadOSColors.borderTranslucent, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMiniMetric('LOGGED SERVICES', '${state.tasks.length}', RoadOSColors.cyberCyan),
              _buildMiniMetric('UPCOMING ITEMS', '${state.schedules.length}', RoadOSColors.electricBlue),
              _buildMiniMetric('TOTAL SPENT', '\$${state.totalMaintenanceCost.toStringAsFixed(0)}', RoadOSColors.hyperOrange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildSchedulesTab(MaintenanceState state) {
    if (state.schedules.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text('No maintenance schedules defined for this vehicle.', style: TextStyle(color: RoadOSColors.textMuted)),
        ),
      );
    }

    return Column(
      children: state.schedules.map((schedule) {
        final color = _getStatusColor(schedule.status);
        final progress = schedule.progressRatio;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: RoadOSCard(
            borderColor: color.withValues(alpha: 0.4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_getTaskIcon(schedule.taskType), color: color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            schedule.title,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            schedule.statusDetail,
                            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color.withValues(alpha: 0.2),
                        foregroundColor: color,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: color.withValues(alpha: 0.5)),
                        ),
                      ),
                      onPressed: () => _showLogServiceModal(preselectedTaskType: schedule.taskType),
                      child: const Text('LOG', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(schedule.recommendation, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: const Color(0x30101A38),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? Colors.redAccent : (progress > 0.8 ? RoadOSColors.hyperOrange : RoadOSColors.cyberCyan),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHistoryTab(MaintenanceState state) {
    if (state.tasks.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Column(
            children: [
              const Icon(Icons.history_toggle_off_rounded, color: RoadOSColors.textMuted, size: 40),
              const SizedBox(height: 10),
              const Text('No service history records logged yet.', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 12)),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: RoadOSColors.cyberCyan, foregroundColor: Colors.black),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('LOG FIRST SERVICE'),
                onPressed: () => _showLogServiceModal(),
              ),
            ],
          ),
        ),
      );
    }

    // Filter Chips
    final filterOptions = ['ALL', 'OIL', 'CHAIN', 'BRAKES', 'INSPECTION'];
    final filtered = state.filteredTasks;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filterOptions.map((opt) {
              final isSelected = state.activeFilter == opt;
              return Padding(
                padding: const EdgeInsets.only(right: 8, bottom: 12),
                child: ChoiceChip(
                  label: Text(opt),
                  selected: isSelected,
                  selectedColor: RoadOSColors.cyberCyan.withValues(alpha: 0.3),
                  backgroundColor: const Color(0x20101A38),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : RoadOSColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  side: BorderSide(
                    color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.borderSubtle,
                  ),
                  onSelected: (_) => ref.read(maintenanceNotifierProvider.notifier).setFilter(opt),
                ),
              );
            }).toList(),
          ),
        ),
        ...filtered.map((log) {
          final dateStr =
              '${log.performedAtDate.year}-${log.performedAtDate.month.toString().padLeft(2, '0')}-${log.performedAtDate.day.toString().padLeft(2, '0')}';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: RoadOSCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(_getTaskIcon(log.taskType), color: RoadOSColors.cyberCyan, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            MaintenanceTaskTypes.getDisplayName(log.taskType),
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (log.cost != null)
                        Text(
                          '\$${log.cost!.toStringAsFixed(0)}',
                          style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 13, fontWeight: FontWeight.w900),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text('At ${log.performedAtKm} km', style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11)),
                      const SizedBox(width: 10),
                      Text('•  $dateStr', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                      if (log.serviceProvider != null) ...[
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '•  ${log.serviceProvider!}',
                            style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (log.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      log.notes,
                      style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
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
