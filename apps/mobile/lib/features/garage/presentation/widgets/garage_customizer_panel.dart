import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../core/services/garage_storage_service.dart';
import '../../domain/entities/garage_vehicle_model.dart';

/// Full interactive vehicle configurator & customization panel
class GarageCustomizerPanel extends StatefulWidget {
  final GarageVehicleModel vehicle;
  final Function(VehicleCustomizationState updatedState) onCustomizationChanged;
  final VoidCallback onClose;
  final String riderId;

  const GarageCustomizerPanel({
    super.key,
    required this.vehicle,
    required this.onCustomizationChanged,
    required this.onClose,
    required this.riderId,
  });

  @override
  State<GarageCustomizerPanel> createState() => _GarageCustomizerPanelState();
}

class _GarageCustomizerPanelState extends State<GarageCustomizerPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late VehicleCustomizationState _currentState;
  bool _isSaving = false;

  // Preset Body Colors
  final List<Map<String, dynamic>> _bodyColorPresets = const [
    {'name': 'Icon Racing Blue', 'color': Color(0xFF0D47A1)},
    {'name': 'Ducati Corse Red', 'color': Color(0xFFD50000)},
    {'name': 'M Motorsport Alpine White', 'color': Color(0xFFFAFAFA)},
    {'name': 'Stealth Carbon Black', 'color': Color(0xFF181818)},
    {'name': 'Solar Gold Metallic', 'color': Color(0xFFFFB300)},
    {'name': 'Apex Emerald Green', 'color': Color(0xFF00C853)},
    {'name': 'Hyper Orange Pearl', 'color': Color(0xFFFF6D00)},
    {'name': 'Cyber Violet Chrome', 'color': Color(0xFF7C4DFF)},
    {'name': 'Nardo Storm Grey', 'color': Color(0xFF78909C)},
    {'name': 'Quantum Cyan', 'color': Color(0xFF00E5FF)},
  ];

  // Preset Wheel Rim Colors
  final List<Map<String, dynamic>> _wheelColorPresets = const [
    {'name': 'Forged Matte Black', 'color': Color(0xFF1E1E1E)},
    {'name': 'Racing Gold Bronze', 'color': Color(0xFFFFB300)},
    {'name': 'Yamaha Racing Blue', 'color': Color(0xFF1976D2)},
    {'name': 'Ducati Racing Red', 'color': Color(0xFFD50000)},
    {'name': 'High-Gloss Silver', 'color': Color(0xFFECEFF1)},
    {'name': 'Anthracite Gunmetal', 'color': Color(0xFF37474F)},
  ];

  // Preset Caliper Colors
  final List<Map<String, dynamic>> _caliperColorPresets = const [
    {'name': 'Brembo Racing Red', 'color': Color(0xFFFF1744)},
    {'name': 'Acid Racing Yellow', 'color': Color(0xFFFFEA00)},
    {'name': 'M Performance Blue', 'color': Color(0xFF0066CC)},
    {'name': 'Solar Gold Ceramic', 'color': Color(0xFFFFB300)},
    {'name': 'Stealth Titanium Grey', 'color': Color(0xFF90A4AE)},
    {'name': 'Apex Emerald Green', 'color': Color(0xFF00E676)},
  ];

  // Preset Seat Materials & Stitching
  final List<Map<String, dynamic>> _seatPresets = const [
    {'name': 'Alcantara Suede + Accent Stitch', 'color': Color(0xFF212121)},
    {'name': 'Perforated Racing Red Leather', 'color': Color(0xFF880E4F)},
    {'name': 'Vintage Cognac Brown Leather', 'color': Color(0xFF5D4037)},
    {'name': 'Full Carbon Race Monocoque', 'color': Color(0xFF121212)},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _currentState = widget.vehicle.customization;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateState(VehicleCustomizationState newState) {
    LuxAudioHapticsService.selectionClick();
    setState(() => _currentState = newState);
    widget.onCustomizationChanged(newState);
  }

  Future<void> _saveConfiguration() async {
    setState(() => _isSaving = true);
    LuxAudioHapticsService.heavyImpact();

    await GarageStorageService().saveCustomization(widget.vehicle.id, _currentState, riderId: widget.riderId);

    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ ${_currentState.finishType.label} configuration saved for ${widget.vehicle.fullName}!'),
          backgroundColor: const Color(0xFF0D1B2A),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _resetToFactory() async {
    LuxAudioHapticsService.mediumImpact();
    await GarageStorageService().resetCustomization(widget.vehicle.id);
    _updateState(widget.vehicle.customization);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Factory livery and components restored.'),
          backgroundColor: Color(0xFF0F172A),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.vehicle.factoryAccentColor;

    return Container(
      width: 440,
      decoration: BoxDecoration(
        color: const Color(0xF00A0F1D),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.8),
            blurRadius: 32,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 14, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.palette_rounded, color: accent, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'VEHICLE CONFIGURATOR',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        widget.vehicle.fullName,
                        style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Customization Category Tabs
          TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: accent,
            unselectedLabelColor: Colors.white60,
            indicatorColor: accent,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'PAINT & BODY'),
              Tab(text: 'WHEELS & BRAKES'),
              Tab(text: 'EXHAUST SYSTEM'),
              Tab(text: 'AERO & SEAT'),
            ],
          ),
          const Divider(color: Colors.white12, height: 1),

          // Tab Content Area
          SizedBox(
            height: 290,
            child: TabBarView(
              controller: _tabController,
              children: [
                // 1. Paint & Body Tab
                _buildPaintTab(accent),
                // 2. Wheels & Brakes Tab
                _buildWheelsBrakesTab(accent),
                // 3. Exhaust System Tab
                _buildExhaustTab(accent),
                // 4. Aero & Seat Tab
                _buildAeroSeatTab(accent),
              ],
            ),
          ),

          const Divider(color: Colors.white12, height: 1),

          // Bottom Action Controls (Save, Reset, Export)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: _resetToFactory,
                  icon: const Icon(Icons.restart_alt_rounded, size: 16, color: Colors.white70),
                  label: const Text('Factory Reset', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveConfiguration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_rounded, size: 16),
                  label: Text(
                    _isSaving ? 'Saving...' : 'Save Configuration',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 1: PAINT & FINISH
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildPaintTab(Color accent) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'SURFACE FINISH TYPE',
          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SurfaceFinishType.values.map((finish) {
            final isSelected = _currentState.finishType == finish;
            return ChoiceChip(
              label: Text(finish.label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
              selected: isSelected,
              selectedColor: accent,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              onSelected: (val) {
                if (val) _updateState(_currentState.copyWith(finishType: finish));
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        const Text(
          'BODY LIVERY COLOR PRESETS',
          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _bodyColorPresets.map((preset) {
            final col = preset['color'] as Color;
            final isSelected = _currentState.bodyColor == col;
            return Tooltip(
              message: preset['name'] as String,
              child: GestureDetector(
                onTap: () => _updateState(_currentState.copyWith(bodyColor: col, accentGlowColor: col)),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: col,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white24,
                      width: isSelected ? 3.0 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: col.withValues(alpha: 0.8), blurRadius: 12, spreadRadius: 2)]
                        : [],
                  ),
                  child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 18) : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 2: WHEELS & BRAKES
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildWheelsBrakesTab(Color accent) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'WHEEL RIM COLOR',
          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _wheelColorPresets.map((preset) {
            final col = preset['color'] as Color;
            final isSelected = _currentState.wheelColor == col;
            return Tooltip(
              message: preset['name'] as String,
              child: GestureDetector(
                onTap: () => _updateState(_currentState.copyWith(wheelColor: col)),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: col,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white24,
                      width: isSelected ? 3.0 : 1.0,
                    ),
                  ),
                  child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        const Text(
          'BRAKE CALIPER FINISH',
          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _caliperColorPresets.map((preset) {
            final col = preset['color'] as Color;
            final isSelected = _currentState.caliperColor == col;
            return Tooltip(
              message: preset['name'] as String,
              child: GestureDetector(
                onTap: () => _updateState(_currentState.copyWith(caliperColor: col)),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: col,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.white24,
                      width: isSelected ? 3.0 : 1.0,
                    ),
                  ),
                  child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 3: EXHAUST SYSTEM
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildExhaustTab(Color accent) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: ExhaustSystemType.values.map((exhaust) {
        final isSelected = _currentState.exhaustType == exhaust;
        return GestureDetector(
          onTap: () => _updateState(_currentState.copyWith(exhaustType: exhaust)),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? accent.withValues(alpha: 0.18) : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? accent : Colors.white12,
                width: isSelected ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? accent : Colors.white54,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exhaust.label,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        exhaust.description,
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════════
  // TAB 4: AERO & SEAT
  // ═════════════════════════════════════════════════════════════════════════════

  Widget _buildAeroSeatTab(Color accent) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          activeTrackColor: accent,
          title: const Text('Carbon Aerodynamic Winglets', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          subtitle: const Text('Generates +22 kg downforce @ 250 km/h', style: TextStyle(color: Colors.white54, fontSize: 10)),
          value: _currentState.hasWinglets,
          onChanged: (val) => _updateState(_currentState.copyWith(hasWinglets: val)),
        ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          activeTrackColor: accent,
          title: const Text('Smoked Racing Windscreen', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          subtitle: const Text('Anti-glare aerodynamic double-bubble profile', style: TextStyle(color: Colors.white54, fontSize: 10)),
          value: _currentState.hasTintedWindscreen,
          onChanged: (val) => _updateState(_currentState.copyWith(hasTintedWindscreen: val)),
        ),
        const Divider(color: Colors.white12, height: 16),
        const Text(
          'SEAT UPHOLSTERY',
          style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
        ),
        const SizedBox(height: 10),
        ..._seatPresets.map((s) {
          final col = s['color'] as Color;
          final isSelected = _currentState.seatColor == col;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(radius: 12, backgroundColor: col),
            title: Text(s['name'] as String, style: const TextStyle(color: Colors.white, fontSize: 11)),
            trailing: isSelected ? Icon(Icons.check_circle_rounded, color: accent, size: 18) : null,
            onTap: () => _updateState(_currentState.copyWith(seatColor: col)),
          );
        }),
      ],
    );
  }
}
