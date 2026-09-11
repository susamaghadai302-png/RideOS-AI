import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/widgets/rideos_3d_model_viewer.dart';
import '../../domain/models/advanced_garage_models.dart';
import '../../core/services/advanced_3d_garage_engine.dart';

class Advanced3dGarageScreen extends StatefulWidget {
  final Advanced3dGarageEngine? engine;
  const Advanced3dGarageScreen({super.key, this.engine});

  @override
  State<Advanced3dGarageScreen> createState() => _Advanced3dGarageScreenState();
}

class _Advanced3dGarageScreenState extends State<Advanced3dGarageScreen> {
  late final Advanced3dGarageEngine _garageEngine;

  @override
  void initState() {
    super.initState();
    _garageEngine = widget.engine ?? Advanced3dGarageEngine();
  }
  String _selectedVehicleId = 'v_unconfigured';
  CameraPreset _selectedCamera = CameraPreset.isometric;
  LightingPreset _selectedLighting = LightingPreset.showroomStudio;
  double _rotationAngle = 0.0;
  String _aiOutput = '';
  final TextEditingController _queryController = TextEditingController();

  void _sendQuery(String prompt) {
    if (prompt.trim().isEmpty) return;
    final res = _garageEngine.processGarageAiQuery(prompt.trim(), _selectedVehicleId);
    setState(() {
      _aiOutput = res;
      _queryController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final motorcycles = _garageEngine.getRegisteredMotorcycles();
    final bike = _garageEngine.getMotorcycleById(_selectedVehicleId);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: const Color(0xFF060912),
        title: const Text(
          'SMART GARAGE 3D & VEHICLE SYSTEM',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5, color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Vehicle Selector Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: motorcycles.map((m) => _buildVehicleTab(m)).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // 2. Interactive 3D Viewport Card
          Container(
            height: 230,
            decoration: BoxDecoration(
              gradient: _getLightingGradient(),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.5)),
              boxShadow: RoadOSShadows.luxuryCard,
            ),
            child: Stack(
              children: [
                // Real 3D Model Viewer or Truthful Pending Validation Viewport
                Positioned.fill(
                  child: RideOS3DModelViewer(
                    modelPath: bike.isAssetAvailable ? bike.assetGlbPath : '',
                    vehicleName: '${bike.manufacturer} ${bike.modelName}',
                    autoRotate: false,
                    cameraControls: true,
                  ),
                ),

                // Top Camera Preset Badge
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF070B18).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1A2035)),
                    ),
                    child: Text(_selectedCamera.label, style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),

                // Top Lighting Preset Badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF070B18).withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1A2035)),
                    ),
                    child: Text(_selectedLighting.label, style: const TextStyle(color: RoadOSColors.hyperOrange, fontSize: 8, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Camera Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CAMERA PRESETS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Row(
                children: [
                  _buildCameraBtn(CameraPreset.isometric, Icons.view_in_ar),
                  const SizedBox(width: 4),
                  _buildCameraBtn(CameraPreset.front, Icons.arrow_upward),
                  const SizedBox(width: 4),
                  _buildCameraBtn(CameraPreset.sideProfile, Icons.arrow_forward),
                  const SizedBox(width: 4),
                  _buildCameraBtn(CameraPreset.rear, Icons.arrow_downward),
                  const SizedBox(width: 4),
                  _buildCameraBtn(CameraPreset.topInspection, Icons.layers_rounded),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 3b. Lighting Preset Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('LIGHTING PRESETS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              Row(
                children: LightingPreset.values.map((preset) {
                  final isSelected = _selectedLighting == preset;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedLighting = preset),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? RoadOSColors.hyperOrange : RoadOSColors.cardSurface,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: isSelected ? RoadOSColors.hyperOrange : RoadOSColors.borderTranslucent),
                      ),
                      child: Text(
                        preset.label.split(' ').first,
                        style: TextStyle(
                          color: isSelected ? Colors.black : RoadOSColors.textMuted,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4. Vehicle Specifications Grid
          const Text('VEHICLE POWERTRAIN SPECIFICATIONS', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildSpecCard('ENGINE', '${bike.displacementCc}cc', RoadOSColors.hyperOrange)),
              const SizedBox(width: 8),
              Expanded(child: _buildSpecCard('POWER', '${bike.horsepower.round()} HP', RoadOSColors.cyberCyan)),
              const SizedBox(width: 8),
              Expanded(child: _buildSpecCard('TORQUE', '${bike.torqueNm} Nm', RoadOSColors.apexEmerald)),
              const SizedBox(width: 8),
              Expanded(child: _buildSpecCard('WEIGHT', '${bike.curbWeightKg.round()} kg', Colors.white)),
            ],
          ),
          const SizedBox(height: 14),

          // 5. Interactive Components Inspection
          const Text('INTERACTIVE COMPONENT INSPECTION', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ...bike.components.map((c) => _buildComponentTile(c)),

          const SizedBox(height: 16),

          // 6. AI Garage Assistant
          const Text('GARAGE AI DIAGNOSTIC ASSISTANT', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPromptChip('What are the engine specs?'),
                _buildPromptChip('Inspect front brakes'),
                _buildPromptChip('When is the next service for this bike?'),
                _buildPromptChip('Show available colors'),
              ],
            ),
          ),
          const SizedBox(height: 10),

          if (_aiOutput.isNotEmpty)
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
                    child: Text(_aiOutput, style: const TextStyle(color: Colors.white, fontSize: 11, height: 1.3)),
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
                    hintText: 'Ask about components, torque curve, service intervals...',
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
      ),
    );
  }

  LinearGradient _getLightingGradient() {
    switch (_selectedLighting) {
      case LightingPreset.cyberpunkNeon:
        return const LinearGradient(
          colors: [Color(0xFF1E0836), Color(0xFF070B19)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case LightingPreset.trackdayPaddock:
        return const LinearGradient(
          colors: [Color(0xFF261A08), Color(0xFF0F0E14)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case LightingPreset.daylightNatural:
        return const LinearGradient(
          colors: [Color(0xFF142436), Color(0xFF0A101D)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case LightingPreset.showroomStudio:
        return RoadOSGradients.darkCardGradient;
    }
  }

  Widget _buildVehicleTab(MotorcycleGarageProfile m) {
    final isSelected = _selectedVehicleId == m.id;
    return GestureDetector(
      onTap: () {
        LuxAudioHapticsService.lightImpact();
        setState(() {
          _selectedVehicleId = m.id;
          _rotationAngle = 0.0;
          _aiOutput = '';
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? RoadOSColors.electricBlue : RoadOSColors.cardSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.borderTranslucent),
        ),
        child: Text(
          '${m.manufacturer} ${m.modelName}',
          style: TextStyle(
            color: isSelected ? Colors.white : RoadOSColors.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCameraBtn(CameraPreset preset, IconData icon) {
    final isSelected = _selectedCamera == preset;
    return IconButton(
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: isSelected ? RoadOSColors.electricBlue : RoadOSColors.cardSurface,
        foregroundColor: isSelected ? Colors.white : RoadOSColors.textMuted,
      ),
      icon: Icon(icon, size: 14),
      onPressed: () => setState(() => _selectedCamera = preset),
    );
  }

  Widget _buildSpecCard(String label, String val, Color col) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF070B18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 8, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(val, style: TextStyle(color: col, fontSize: 12, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }

  Widget _buildComponentTile(Motorcycle3dComponent c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(c.name, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: RoadOSColors.apexEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('${c.healthScore}% HEALTH', style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(c.maintenanceMilestone, style: const TextStyle(color: RoadOSColors.hyperOrange, fontSize: 9, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(c.description, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9)),
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
