import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/widgets/rideos_3d_model_viewer.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import '../../../../core/vehicle_health/services/maintenance_manager.dart';
import '../../../../core/vehicle_health/models/maintenance_record_model.dart';
import '../../../../core/graphics/global_3d_state_bridge.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  VEHICLE MAINTENANCE — Futuristic 3D Service Bay & Predictive Upkeep
// ─────────────────────────────────────────────────────────────────────────────

class VehicleMaintenanceScreen extends ConsumerStatefulWidget {
  final VehicleProfile? vehicle;

  const VehicleMaintenanceScreen({super.key, this.vehicle});

  @override
  ConsumerState<VehicleMaintenanceScreen> createState() =>
      _VehicleMaintenanceScreenState();
}

class _VehicleMaintenanceScreenState
    extends ConsumerState<VehicleMaintenanceScreen> {
  int _selectedTaskIndex = 0;

  @override
  void initState() {
    super.initState();
    MaintenanceManager().initialize(ref);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Global3DStateBridge().setCameraPreset('engine');
    });
  }

  IconData _getIconForService(String type) {
    switch (type) {
      case 'engine_oil':
        return Icons.oil_barrel_rounded;
      case 'brake_fluid':
        return Icons.album_rounded;
      case 'chain_service':
      case 'chain_lube':
        return Icons.link_rounded;
      case 'coolant':
        return Icons.thermostat_rounded;
      case 'spark_plugs':
        return Icons.flash_on_rounded;
      case 'tyre_inspection':
        return Icons.tire_repair_rounded;
      case 'air_filter':
        return Icons.air_rounded;
      default:
        return Icons.build_rounded;
    }
  }

  Color _getColorForStatus(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.ok:
        return RoadOSColors.apexEmerald;
      case ServiceStatus.dueSoon:
        return RoadOSColors.cyberCyan;
      case ServiceStatus.dueNow:
        return RoadOSColors.hyperOrange;
      case ServiceStatus.overdue:
        return Colors.redAccent;
      case ServiceStatus.insufficientData:
        return Colors.grey;
      case ServiceStatus.unknown:
        return Colors.grey;
    }
  }

  String _getPresetForService(String type) {
    switch (type) {
      case 'brake_fluid':
      case 'chain_service':
      case 'chain_lube':
      case 'tyre_inspection':
        return 'wheels';
      default:
        return 'engine';
    }
  }

  void _selectTask(int index, List<ServiceScheduleItem> items) {
    LuxAudioHapticsService.selectionClick();
    setState(() => _selectedTaskIndex = index);
    if (items.isEmpty) return;
    final task = items[index];
    Global3DStateBridge()
        .setCameraPreset(_getPresetForService(task.serviceType));
    Global3DStateBridge().highlightComponent(task.serviceType);
  }

  void _showAddServiceModal(VehicleProfile? profile) {
    LuxAudioHapticsService.lightImpact();
    final odoController = TextEditingController(
      text: MaintenanceManager().currentOdometer.toStringAsFixed(0),
    );
    String selectedType = 'engine_oil';

    final scheduleItems = MaintenanceManager().getSchedule(profile);
    if (scheduleItems.isEmpty) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            ),
            child: RoadOSCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: selectedType,
                    dropdownColor: const Color(0xFF080D22),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Service Task',
                      labelStyle:
                          const TextStyle(color: RoadOSColors.textMuted),
                      filled: true,
                      fillColor: const Color(0x30101A38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    items: scheduleItems
                        .map((s) => DropdownMenuItem(
                              value: s.serviceType,
                              child: Text(s.title),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setModalState(() => selectedType = val ?? selectedType),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: odoController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Odometer (km)',
                      labelStyle:
                          const TextStyle(color: RoadOSColors.textMuted),
                      filled: true,
                      fillColor: const Color(0x30101A38),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RoadOSColors.cyberCyan,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final km = double.tryParse(odoController.text) ?? 0.0;
                        final record = MaintenanceRecordModel(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          vehicleId: profile?.id ?? 'unknown',
                          serviceType: selectedType,
                          date: DateTime.now(),
                          odometerKm: km,
                          isVehicleOdometer: false,
                        );
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(ctx);

                        await MaintenanceManager().addServiceRecord(record);

                        if (!mounted) return;
                        navigator.pop();
                        setState(() {});
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            backgroundColor: RoadOSColors.apexEmerald,
                            content: Text(
                              'Service logged and predictions updated.',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'SAVE RECORD',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeContext = ref.watch(activeVehicleContextProvider);
    final vehicle = widget.vehicle ?? activeContext.profile;

    // Watch for records updates
    ref.watch(maintenanceRecordsProvider);

    final scheduleItems = MaintenanceManager().getSchedule(vehicle);
    if (_selectedTaskIndex >= scheduleItems.length &&
        scheduleItems.isNotEmpty) {
      _selectedTaskIndex = 0;
    }
    final selectedTask =
        scheduleItems.isNotEmpty ? scheduleItems[_selectedTaskIndex] : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '3D SERVICE BAY & UPKEEP',
          style: TextStyle(
            color: RoadOSColors.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 15,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: RoadOSColors.cyberCyan,
            ),
            tooltip: 'Log Service',
            onPressed: () => _showAddServiceModal(vehicle),
          ),
        ],
      ),
      body: CinematicBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── 1. Top Maintenance Odometer Overview ──────────────────────
                _buildOdometerOverview(MaintenanceManager().currentOdometer,
                    MaintenanceManager().isVehicleOdometer),
                const SizedBox(height: 18),

                // ── 2. 3D Service Platform Stage ──────────────────────────────
                if (selectedTask != null)
                  _build3DServicePlatform(vehicle, selectedTask),
                const SizedBox(height: 18),

                // ── 3. Maintenance Task Selector ──────────────────────────────
                const Text(
                  'SCHEDULED SERVICE ITEMS',
                  style: TextStyle(
                    color: RoadOSColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                _buildTasksList(scheduleItems),
                const SizedBox(height: 18),

                // ── 4. AI Predictive Upkeep Assessment ────────────────────────
                _buildAiPredictiveCard(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOdometerOverview(double odo, bool isVehicleOdometer) {
    return RoadOSCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'CURRENT ODOMETER',
                style: TextStyle(
                  color: RoadOSColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${odo.toStringAsFixed(0)} km',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (!isVehicleOdometer && odo > 0)
                const Text('User Entered',
                    style: TextStyle(
                        color: RoadOSColors.hyperOrange, fontSize: 10)),
            ],
          ),
          Container(
            height: 36,
            width: 1,
            color: RoadOSColors.borderSubtle,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PREDICTION STATE',
                style: TextStyle(
                  color: RoadOSColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                odo <= 0 ? 'Insufficient Data' : 'Active Tracking',
                style: TextStyle(
                  color: odo <= 0 ? Colors.grey : RoadOSColors.cyberCyan,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _build3DServicePlatform(
      dynamic vehicle, ServiceScheduleItem selectedTask) {
    final color = _getColorForStatus(selectedTask.status);
    return Container(
      height: 260,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 1.2),
        gradient: const LinearGradient(
          colors: [Color(0x35101A38), Color(0x1504060C)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          children: [
            RideOS3DModelViewer(
              vehicleProfile: vehicle,
              cameraOrbit: '45deg 70deg 95%',
              exposure: 1.15,
            ),
            Positioned(
              top: 14,
              left: 14,
              child: FloatingHudBubble(
                icon: _getIconForService(selectedTask.serviceType),
                label: 'Selected Component',
                value: selectedTask.title,
                unit: '| Status: ${selectedTask.statusDetail}',
                accentColor: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksList(List<ServiceScheduleItem> items) {
    if (items.isEmpty) return const SizedBox();
    return Column(
      children: List.generate(items.length, (index) {
        final task = items[index];
        final isSelected = index == _selectedTaskIndex;
        final color = _getColorForStatus(task.status);

        double progress = 0.0;
        if (task.status == ServiceStatus.insufficientData) {
          progress = 0.0;
        } else if (task.lastPerformedKm != null) {
          final done = task.currentOdometerKm - task.lastPerformedKm!;
          progress = (done / task.intervalKm).clamp(0.0, 1.0);
        } else {
          progress = (task.currentOdometerKm / task.intervalKm).clamp(0.0, 1.0);
        }

        return GestureDetector(
          onTap: () => _selectTask(index, items),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.14)
                  : const Color(0x20101A38),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : RoadOSColors.borderSubtle,
                width: isSelected ? 1.4 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getIconForService(task.serviceType),
                      color: isSelected ? color : RoadOSColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : RoadOSColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            task.statusDetail,
                            style: TextStyle(
                              color: color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.chevron_right_rounded,
                      color: isSelected ? color : RoadOSColors.textMuted,
                      size: 18,
                    ),
                  ],
                ),
                if (isSelected) ...[
                  const SizedBox(height: 8),
                  Text(
                    task.explanation,
                    style: const TextStyle(
                      color: RoadOSColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                  if (task.isGenericEstimate) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'ADVISORY ONLY: Please consult manufacturer manual.',
                      style: TextStyle(
                          color: RoadOSColors.hyperOrange,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 4,
                    backgroundColor: const Color(0x20101A38),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress > 0.8
                          ? RoadOSColors.hyperOrange
                          : RoadOSColors.cyberCyan,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildAiPredictiveCard() {
    return RoadOSCard(
      borderColor: RoadOSColors.neonViolet.withValues(alpha: 0.45),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RoadOSGradients.primaryViolet,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI WEAR PREDICTION ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Engine oil viscosity index high (94%). Next service recommended at 4,000 km mark.',
                  style: TextStyle(
                    color: RoadOSColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
