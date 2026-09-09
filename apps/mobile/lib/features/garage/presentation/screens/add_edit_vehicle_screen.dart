import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/design_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/widgets/cinematic_background.dart';

class AddEditVehicleScreen extends StatefulWidget {
  final Map<String, dynamic>? initialBike;
  const AddEditVehicleScreen({super.key, this.initialBike});

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _makeController;
  late TextEditingController _modelController;
  late TextEditingController _yearController;
  late TextEditingController _ccController;
  late TextEditingController _regController;
  late TextEditingController _vinController;
  late TextEditingController _colorController;

  String _fuelType = 'Petrol';
  bool _isDefaultVehicle = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final bike = widget.initialBike;
    _makeController = TextEditingController(text: bike?['make'] ?? 'Yamaha');
    _modelController = TextEditingController(text: bike?['model'] ?? 'YZF-R1M');
    _yearController = TextEditingController(text: (bike?['year'] ?? 2024).toString());
    _ccController = TextEditingController(text: (bike?['engineCC'] ?? 998).toString());
    _regController = TextEditingController(text: bike?['regNumber'] ?? 'CA-9201-R1M');
    _vinController = TextEditingController(text: bike?['vin'] ?? 'JYAR1M908N1002491');
    _colorController = TextEditingController(text: bike?['color'] ?? 'Carbon Raven Black');
    _fuelType = bike?['fuelType'] ?? 'Petrol';
    _isDefaultVehicle = bike?['isPrimary'] ?? true;
  }

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _ccController.dispose();
    _regController.dispose();
    _vinController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      LuxAudioHapticsService.heavyImpact();

      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        setState(() => _isSaving = false);
        showLuxSnack(context, '${_makeController.text} ${_modelController.text} saved to Digital Garage.', variant: LuxSnackVariant.info);
        Navigator.pop(context);
      }
    }
  }

  void _deleteVehicle() {
    LuxAudioHapticsService.heavyImpact();
    showLuxSnack(context, 'Vehicle removed from garage.', variant: LuxSnackVariant.info);
    Navigator.pop(context);
  }

  void _uploadBikePhoto() {
    LuxAudioHapticsService.selectionClick();
    showLuxSnack(context, 'Motorcycle photo uploaded to vehicle profile.', variant: LuxSnackVariant.info);
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialBike != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: RoadOSColors.platinumWhite, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'EDIT MOTORCYCLE' : 'ADD MOTORCYCLE',
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: RoadOSColors.hyperOrange),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: RoadOSColors.errorCrimson),
              onPressed: _deleteVehicle,
            ),
        ],
      ),
      body: CinematicBackground(child: LuxAuroraBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Vehicle Photo Upload Stage Card
                  GestureDetector(
                    onTap: _uploadBikePhoto,
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LuxGradients.hyperOrange,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: LuxShadows.glassGlow(RoadOSColors.hyperOrange),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.add_a_photo_rounded, size: 42, color: Colors.white),
                          const SizedBox(height: 8),
                          Text(
                            'Upload Motorcycle Photo',
                            style: LuxTypography.bodyMedium(color: Colors.white).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Specifications Card
                  RoadOSCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'VEHICLE SPECIFICATIONS',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: RoadOSColors.cyberCyan),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _makeController,
                          style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                          decoration: buildLuxGlassInputDecoration(label: 'Manufacturer (Make)', icon: Icons.branding_watermark_outlined),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _modelController,
                          style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                          decoration: buildLuxGlassInputDecoration(label: 'Model Name', icon: Icons.two_wheeler_outlined),
                          validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _yearController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                                decoration: buildLuxGlassInputDecoration(label: 'Year', icon: Icons.calendar_today_outlined),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _ccController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                                decoration: buildLuxGlassInputDecoration(label: 'Engine CC', icon: Icons.speed_outlined),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _colorController,
                          style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                          decoration: buildLuxGlassInputDecoration(label: 'Vehicle Color', icon: Icons.palette_outlined),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Registration & Document Details Card
                  RoadOSCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'REGISTRATION & IDENTIFICATION',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: RoadOSColors.cyberCyan),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _regController,
                          style: const TextStyle(color: RoadOSColors.hyperOrange, fontWeight: FontWeight.bold),
                          decoration: buildLuxGlassInputDecoration(label: 'Registration Plate Number', icon: Icons.badge_outlined),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _vinController,
                          style: const TextStyle(color: RoadOSColors.platinumWhite, fontWeight: FontWeight.bold),
                          decoration: buildLuxGlassInputDecoration(label: 'VIN (Chassis Number)', icon: Icons.fingerprint_outlined),
                        ),
                        const SizedBox(height: 16),

                        // Fuel Type Selection Row
                        const Text('Fuel Category', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 8),
                        Row(
                          children: ['Petrol', 'Electric (EV)', 'Hybrid'].map((f) {
                            final isSelected = _fuelType == f;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                  child: ChoiceChip(
                                  label: Text(f, style: TextStyle(fontSize: 11, color: isSelected ? Colors.black : RoadOSColors.platinumWhite, fontWeight: FontWeight.bold)),
                                  selected: isSelected,
                                  selectedColor: RoadOSColors.cyberCyan,
                                  backgroundColor: Colors.transparent,
                                  onSelected: (val) {
                                    if (val) setState(() => _fuelType = f);
                                  },
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        SwitchListTile.adaptive(
                          contentPadding: EdgeInsets.zero,
                          activeTrackColor: RoadOSColors.hyperOrange,
                          title: const Text('Set as Primary Vehicle', style: TextStyle(color: RoadOSColors.platinumWhite, fontSize: 13, fontWeight: FontWeight.bold)),
                          subtitle: const Text('Default motorcycle for telematics & navigation', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                          value: _isDefaultVehicle,
                          onChanged: (val) => setState(() => _isDefaultVehicle = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  RoadOSButton(
                    label: isEditing ? 'UPDATE MOTORCYCLE' : 'REGISTER TO GARAGE',
                    icon: Icons.check_circle_rounded,
                    gradient: LuxGradients.hyperOrange,
                    isLoading: _isSaving,
                    onPressed: _saveVehicle,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      )),
    );
  }
}
