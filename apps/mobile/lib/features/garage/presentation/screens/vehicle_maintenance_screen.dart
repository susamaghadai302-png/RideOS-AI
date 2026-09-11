import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/widgets/rideos_3d_model_viewer.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import '../../../../core/vehicle_health/services/maintenance_manager.dart';
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

  final List<Map<String, dynamic>> _maintenanceTasks = [
    {
      'id': 'engine_oil',
      'label': 'Engine Oil & Filter',
      'icon': Icons.oil_barrel_rounded,
      'color': RoadOSColors.hyperOrange,
      'dueIn': '1,542 km',
      'progress': 0.72,
      'preset': 'engine',
    },
    {
      'id': 'brake_fluid',
      'label': 'Brake Fluid & Pads',
      'icon': Icons.album_rounded,
      'color': RoadOSColors.cyberCyan,
      'dueIn': '3,800 km',
      'progress': 0.45,
      'preset': 'wheels',
    },
    {
      'id': 'chain_service',
      'label': 'Drive Chain Lube & Tension',
      'icon': Icons.link_rounded,
      'color': RoadOSColors.neonViolet,
      'dueIn': '450 km',
      'progress': 0.88,
      'preset': 'wheels',
    },
    {
      'id': 'coolant',
      'label': 'Coolant Flush',
      'icon': Icons.thermostat_rounded,
      'color': RoadOSColors.roadCyan,
      'dueIn': '6,200 km',
      'progress': 0.25,
      'preset': 'engine',
    },
    {
      'id': 'spark_plugs',
      'label': 'Spark Plugs Replacement',
      'icon': Icons.flash_on_rounded,
      'color': RoadOSColors.apexEmerald,
      'dueIn': '8,500 km',
      'progress': 0.15,
      'preset': 'engine',
    },
  ];

  @override
  void initState() {
    super.initState();
    MaintenanceManager().initialize(ref);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Global3DStateBridge().setCameraPreset('engine');
    });
  }

  void _selectTask(int index) {
    LuxAudioHapticsService.selectionClick();
    setState(() => _selectedTaskIndex = index);
    final task = _maintenanceTasks[index];
    Global3DStateBridge().setCameraPreset(task['preset'] as String);
    Global3DStateBridge().highlightComponent(task['id'] as String);
  }

  void _showAddServiceModal() {
    LuxAudioHapticsService.lightImpact();
    final odoController = TextEditingController(
      text: MaintenanceManager().currentOdometer.toStringAsFixed(0),
    );
    final providerController = TextEditingController();
    String selectedType = 'engine_oil';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
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
                    labelStyle: const TextStyle(color: RoadOSColors.textMuted),
                    filled: true,
                    fillColor: const Color(0x30101A38),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'engine_oil',
                      child: Text('Engine Oil & Filter'),
                    ),
                    DropdownMenuItem(
                      value: 'brake_fluid',
                      child: Text('Brake Fluid & Pads'),
                    ),
                    DropdownMenuItem(
                      value: 'chain_service',
                      child: Text('Drive Chain Service'),
                    ),
                    DropdownMenuItem(
                      value: 'coolant',
                      child: Text('Coolant Flush'),
                    ),
                    DropdownMenuItem(
                      value: 'spark_plugs',
                      child: Text('Spark Plugs'),
                    ),
                  ],
                  onChanged: (val) => selectedType = val ?? selectedType,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: odoController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Odometer (km)',
                    labelStyle: const TextStyle(color: RoadOSColors.textMuted),
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
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: RoadOSColors.apexEmerald,
                          content: Text(
                            'Service logged into digital maintenance book.',
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final activeContext = ref.watch(activeVehicleContextProvider);
    final vehicle = widget.vehicle ?? activeContext.profile;
    final selectedTask = _maintenanceTasks[_selectedTaskIndex];

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
            onPressed: _showAddServiceModal,
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
                _buildOdometerOverview(),
                const SizedBox(height: 18),

                // ── 2. 3D Service Platform Stage ──────────────────────────────
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
                _buildTasksList(),
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

  /// Top Odometer Overview
  Widget _buildOdometerOverview() {
    return RoadOSCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CURRENT ODOMETER',
                style: TextStyle(
                  color: RoadOSColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '2,458 km',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Container(
            height: 36,
            width: 1,
            color: RoadOSColors.borderSubtle,
          ),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'NEXT SERVICE DUE',
                style: TextStyle(
                  color: RoadOSColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '4,000 km (1,542 km left)',
                style: TextStyle(
                  color: RoadOSColors.cyberCyan,
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

  /// 3D Service Platform Stage
  Widget _build3DServicePlatform(
    dynamic vehicle,
    Map<String, dynamic> selectedTask,
  ) {
    final color = selectedTask['color'] as Color;
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
                icon: selectedTask['icon'] as IconData,
                label: 'Selected Component',
                value: selectedTask['label'] as String,
                unit: '| Due: ${selectedTask['dueIn']}',
                accentColor: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tasks List
  Widget _buildTasksList() {
    return Column(
      children: List.generate(_maintenanceTasks.length, (index) {
        final task = _maintenanceTasks[index];
        final isSelected = index == _selectedTaskIndex;
        final color = task['color'] as Color;
        final progress = task['progress'] as double;

        return GestureDetector(
          onTap: () => _selectTask(index),
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
              children: [
                Row(
                  children: [
                    Icon(
                      task['icon'] as IconData,
                      color: isSelected ? color : RoadOSColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['label'] as String,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : RoadOSColors.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Due in ${task['dueIn']}',
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

  /// AI Predictive Card
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
