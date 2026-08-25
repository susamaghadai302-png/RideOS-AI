import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../core/services/garage_storage_service.dart';
import '../../domain/entities/garage_vehicle_model.dart';

/// Modal dialog to create and register a new custom motorcycle into the 3D Garage
class AddCustomMotorcycleModal extends StatefulWidget {
  final Function(GarageVehicleModel newVehicle) onVehicleCreated;

  const AddCustomMotorcycleModal({super.key, required this.onVehicleCreated});

  @override
  State<AddCustomMotorcycleModal> createState() => _AddCustomMotorcycleModalState();
}

class _AddCustomMotorcycleModalState extends State<AddCustomMotorcycleModal> {
  final _formKey = GlobalKey<FormState>();

  final _makeCtrl = TextEditingController(text: 'Aprilia');
  final _modelCtrl = TextEditingController(text: 'RSV4 Factory 1100');
  final _yearCtrl = TextEditingController(text: '2024');
  final _ccCtrl = TextEditingController(text: '1099');
  final _hpCtrl = TextEditingController(text: '217');
  final _topSpeedCtrl = TextEditingController(text: '305 km/h');
  final _weightCtrl = TextEditingController(text: '199.0');
  String _category = 'Superbike';
  Color _selectedColor = const Color(0xFFFF3D00);
  bool _isSaving = false;

  final List<Color> _colorOptions = const [
    Color(0xFFFF3D00), // Apex Orange
    Color(0xFF00E5FF), // Quantum Cyan
    Color(0xFFD50000), // Racing Red
    Color(0xFF1976D2), // Blue
    Color(0xFFFFD600), // Solar Gold
    Color(0xFF00E676), // Emerald
    Color(0xFF7C4DFF), // Purple
    Color(0xFFECEFF1), // Silver White
  ];

  @override
  void dispose() {
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _yearCtrl.dispose();
    _ccCtrl.dispose();
    _hpCtrl.dispose();
    _topSpeedCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    LuxAudioHapticsService.heavyImpact();

    final fullName = '${_makeCtrl.text.trim()} ${_modelCtrl.text.trim()}';
    final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';

    final newBike = GarageVehicleModel(
      id: id,
      make: _makeCtrl.text.trim(),
      model: _modelCtrl.text.trim(),
      fullName: fullName,
      year: int.tryParse(_yearCtrl.text) ?? 2024,
      category: _category,
      engineCc: int.tryParse(_ccCtrl.text) ?? 1000,
      horsepower: int.tryParse(_hpCtrl.text) ?? 200,
      torqueNm: 115.0,
      topSpeedKmh: _topSpeedCtrl.text.trim().isNotEmpty ? _topSpeedCtrl.text.trim() : '299 km/h',
      zeroToHundred: '2.9 s',
      curbWeightKg: double.tryParse(_weightCtrl.text) ?? 195.0,
      transmission: '6-speed with bi-directional quickshifter',
      compressionRatio: '13.5 : 1',
      fuelCapacityLiters: '17.5 L',
      coolingSystem: 'Liquid-cooled 4-stroke 16-valve DOHC',
      status: 'GARAGE READY',
      isPrimary: false,
      isFavorite: false,
      isCustomVehicle: true,
      imagePath: 'assets/garage/yamaha_r1m.png', // Default high-res canvas stage
      factoryAccentColor: _selectedColor,
      customization: VehicleCustomizationState(
        bodyColor: _selectedColor,
        wheelColor: const Color(0xFF1E1E1E),
        caliperColor: const Color(0xFFFF1744),
        seatColor: const Color(0xFF212121),
        accentGlowColor: _selectedColor,
        finishType: SurfaceFinishType.glossMetallic,
        exhaustType: ExhaustSystemType.akrapovicTitanium,
      ),
      components: {
        'engine': ComponentInspectionSpec(
          title: '$fullName High-Performance Powertrain',
          category: 'Powertrain',
          shortSummary: '${_ccCtrl.text}cc engine delivering ${_hpCtrl.text} HP.',
          keyFeature: 'Custom-tuned ECU with electronic ride-by-wire mapping.',
          hotspotNormalizedOffset: const Offset(0.48, 0.52),
          technicalDetails: {
            'Displacement': '${_ccCtrl.text} cc',
            'Max Output': '${_hpCtrl.text} HP',
            'Cylinder Layout': 'Multi-cylinder liquid cooled',
          },
        ),
      },
    );

    await GarageStorageService().addCustomVehicle(newBike);

    if (mounted) {
      setState(() => _isSaving = false);
      widget.onVehicleCreated(newBike);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: const Color(0xF00A0F1D),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: _selectedColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black87, blurRadius: 40, spreadRadius: 10),
          ],
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.two_wheeler_rounded, color: _selectedColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REGISTER CUSTOM MOTORCYCLE',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'Add a new superbike to your 3D digital showroom',
                          style: TextStyle(color: Colors.white54, fontSize: 11),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Make & Model Fields
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _makeCtrl,
                        label: 'Manufacturer (Make)',
                        hint: 'e.g. Aprilia',
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _modelCtrl,
                        label: 'Model Name',
                        hint: 'e.g. RSV4 Factory',
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Year & CC Fields
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _yearCtrl,
                        label: 'Year',
                        hint: '2024',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _ccCtrl,
                        label: 'Engine Displacement (CC)',
                        hint: '1099',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Horsepower & Top Speed
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        controller: _hpCtrl,
                        label: 'Peak Horsepower (HP)',
                        hint: '217',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTextField(
                        controller: _topSpeedCtrl,
                        label: 'Top Speed',
                        hint: '305 km/h',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Primary Livery Accent Color
                const Text(
                  'PRIMARY LIVERY ACCENT COLOR',
                  style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: _colorOptions.map((c) {
                    final isSelected = _selectedColor == c;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = c),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.white24,
                            width: isSelected ? 2.5 : 1.0,
                          ),
                        ),
                        child: isSelected ? const Icon(Icons.check_rounded, color: Colors.white, size: 16) : null,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isSaving
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.check_rounded, size: 16),
                      label: Text(_isSaving ? 'Registering...' : 'Register to Garage', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 12),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.white12)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _selectedColor)),
          ),
        ),
      ],
    );
  }
}
