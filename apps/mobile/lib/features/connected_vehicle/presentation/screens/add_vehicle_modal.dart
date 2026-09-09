import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import '../../../../core/vehicle_resolution/providers/my_vehicles_provider.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import '../../../../core/vehicle_connectivity/services/universal_vehicle_database.dart';

/// Fully functional Add Vehicle Modal for RideOS-AI.
/// Provides rich, validated manual vehicle registration with Brand, Model, Year,
/// Registration Number, Nickname, and persistent storage.
class AddVehicleModal extends ConsumerStatefulWidget {
  final VoidCallback? onVehicleSaved;

  const AddVehicleModal({super.key, this.onVehicleSaved});

  @override
  ConsumerState<AddVehicleModal> createState() => _AddVehicleModalState();
}

class _AddVehicleModalState extends ConsumerState<AddVehicleModal> {
  final _formKey = GlobalKey<FormState>();
  final _db = UniversalVehicleDatabase();

  String _vehicleType = 'Motorcycle';
  String? _selectedBrand;
  String? _selectedModel;
  final TextEditingController _customModelController = TextEditingController();
  final TextEditingController _regNumberController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  int _selectedYear = 2024;
  bool _isSaving = false;

  final List<String> _vehicleTypes = const [
    'Motorcycle',
    'Scooter',
    'Other Two-Wheeler',
  ];

  final List<int> _years = List.generate(15, (index) => 2026 - index);

  @override
  void initState() {
    super.initState();
    final brands = _db.availableBrands;
    if (brands.isNotEmpty) {
      _selectedBrand = brands.first;
      final models = _getModelsForSelectedBrand();
      if (models.isNotEmpty) {
        _selectedModel = models.first;
        _customModelController.text = models.first;
      }
    }
  }

  @override
  void dispose() {
    _customModelController.dispose();
    _regNumberController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  List<String> _getModelsForSelectedBrand() {
    if (_selectedBrand == null) return [];
    final entries = _db.allEntries.where((e) => e.brand.toLowerCase() == _selectedBrand!.toLowerCase()).toList();
    final models = entries.map((e) => e.model).toSet().toList();
    models.sort();
    return models;
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) {
      LuxAudioHapticsService.errorImpact();
      return;
    }

    final brand = _selectedBrand ?? 'Custom';
    final model = (_selectedModel != null && _selectedModel!.isNotEmpty)
        ? _selectedModel!
        : (_customModelController.text.trim().isNotEmpty
            ? _customModelController.text.trim()
            : 'Two-Wheeler');

    final regNumber = _regNumberController.text.trim().toUpperCase();
    final nickname = _nicknameController.text.trim();

    setState(() => _isSaving = true);
    LuxAudioHapticsService.mediumImpact();

    try {
      final uniqueId = 'v_${brand.toLowerCase()}_${model.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}_${DateTime.now().millisecondsSinceEpoch % 10000}';

      final newProfile = VehicleProfile(
        id: uniqueId,
        manufacturer: brand,
        model: model,
        variant: nickname.isNotEmpty ? nickname : (_vehicleType == 'Scooter' ? 'Scooter Edition' : 'Standard'),
        year: _selectedYear,
        category: _vehicleType,
        fuelType: _vehicleType.contains('Electric') ? 'Electric' : 'Petrol',
        displacementCc: _vehicleType == 'Scooter' ? 125 : 350,
        powerBhp: _vehicleType == 'Scooter' ? 8.5 : 24.0,
        torqueNm: _vehicleType == 'Scooter' ? 10.0 : 28.0,
        topSpeedKmh: _vehicleType == 'Scooter' ? 95 : 140,
        curbWeightKg: _vehicleType == 'Scooter' ? 110 : 175,
        fuelCapacityL: _vehicleType == 'Scooter' ? 5.5 : 13.5,
        protocolAdapter: 'generic_obd_ble',
        model3DUrl: '',
        thumbnailUrl: _vehicleType == 'Scooter' ? 'assets/garage/suzuki_burgman.png' : 'assets/garage/generic_bike.png',
        isVerified: true,
        specifications: {
          'registrationNumber': regNumber,
          if (nickname.isNotEmpty) 'nickname': nickname,
          'type': _vehicleType,
        },
      );

      // Persist to My Vehicles repository
      await ref.read(myVehiclesProvider.notifier).addVehicle(newProfile);

      // Switch active vehicle context
      ref.read(activeVehicleContextProvider.notifier).switchVehicle(newProfile);

      LuxAudioHapticsService.successPattern();

      if (mounted) {
        widget.onVehicleSaved?.call();
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        showLuxSnack(
          context,
          'Vehicle "$brand $model" successfully added to your garage!',
          variant: LuxSnackVariant.success,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        showLuxSnack(context, 'Error saving vehicle: $e', variant: LuxSnackVariant.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final brands = _db.availableBrands;
    final availableModels = _getModelsForSelectedBrand();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF070B18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sheet drag pill
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: RoadOSColors.textMuted.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: RoadOSColors.cyberCyan.withValues(alpha: 0.15),
                          border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, color: RoadOSColors.cyberCyan, size: 18),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ADD VEHICLE',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Register two-wheeler to your personal garage',
                            style: GoogleFonts.inter(
                              color: RoadOSColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: RoadOSColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Color(0x331F293D), height: 1),
              const SizedBox(height: 16),

              // 1. Vehicle Type Selector
              _buildFieldLabel('VEHICLE TYPE'),
              const SizedBox(height: 8),
              Row(
                children: _vehicleTypes.map((type) {
                  final isSelected = _vehicleType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        LuxAudioHapticsService.lightImpact();
                        setState(() => _vehicleType = type);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? RoadOSColors.cyberCyan.withValues(alpha: 0.18) : const Color(0xFF0E1426),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? RoadOSColors.cyberCyan : const Color(0xFF1E293B),
                            width: isSelected ? 1.4 : 1.0,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            type,
                            style: GoogleFonts.outfit(
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.textMuted,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // 2. Brand / Manufacturer Dropdown
              _buildFieldLabel('BRAND / MANUFACTURER *'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1426),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedBrand,
                    dropdownColor: const Color(0xFF0E1426),
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: RoadOSColors.cyberCyan),
                    items: brands.map((b) {
                      return DropdownMenuItem<String>(
                        value: b,
                        child: Text(
                          b,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        LuxAudioHapticsService.selectionClick();
                        setState(() {
                          _selectedBrand = val;
                          final models = _getModelsForSelectedBrand();
                          _selectedModel = models.isNotEmpty ? models.first : null;
                          _customModelController.text = models.isNotEmpty ? models.first : '';
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Model Dropdown & Custom Model
              _buildFieldLabel('MODEL *'),
              const SizedBox(height: 8),
              if (availableModels.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0E1426),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1E293B)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: availableModels.contains(_selectedModel) ? _selectedModel : null,
                      hint: Text(
                        'Select model or enter below...',
                        style: GoogleFonts.inter(color: RoadOSColors.textMuted, fontSize: 12),
                      ),
                      dropdownColor: const Color(0xFF0E1426),
                      isExpanded: true,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: RoadOSColors.cyberCyan),
                      items: availableModels.map((m) {
                        return DropdownMenuItem<String>(
                          value: m,
                          child: Text(
                            m,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          LuxAudioHapticsService.selectionClick();
                          setState(() {
                            _selectedModel = val;
                            _customModelController.text = val;
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              TextFormField(
                controller: _customModelController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: _inputDecoration('e.g. YZF-R1M, Activa 6G, Street Triple...'),
                validator: (v) {
                  if ((_selectedModel == null || _selectedModel!.isEmpty) &&
                      (v == null || v.trim().isEmpty)) {
                    return 'Please select or enter vehicle model';
                  }
                  return null;
                },
                onChanged: (v) {
                  setState(() => _selectedModel = v);
                },
              ),
              const SizedBox(height: 16),

              // 4. Model Year
              _buildFieldLabel('MODEL YEAR'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E1426),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF1E293B)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    dropdownColor: const Color(0xFF0E1426),
                    isExpanded: true,
                    icon: const Icon(Icons.calendar_today_rounded, color: RoadOSColors.cyberCyan, size: 16),
                    items: _years.map((y) {
                      return DropdownMenuItem<int>(
                        value: y,
                        child: Text(
                          '$y Edition',
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        LuxAudioHapticsService.selectionClick();
                        setState(() => _selectedYear = val);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Registration Number
              _buildFieldLabel('REGISTRATION NUMBER (NUMBER PLATE) *'),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('add_vehicle_reg_field'),
                controller: _regNumberController,
                textCapitalization: TextCapitalization.characters,
                style: GoogleFonts.robotoMono(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                decoration: _inputDecoration('e.g. DL 01 AB 1234 or MH 02 CZ 9876'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Registration number is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 6. Optional Nickname
              _buildFieldLabel('NICKNAME (OPTIONAL)'),
              const SizedBox(height: 8),
              TextFormField(
                key: const Key('add_vehicle_nickname_field'),
                controller: _nicknameController,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: _inputDecoration('e.g. The Apex Beast, Daily Commuter...'),
              ),
              const SizedBox(height: 24),

              // Actions: Save & Cancel
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('add_vehicle_cancel_button'),
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RoadOSColors.textMuted,
                        side: const BorderSide(color: Color(0xFF1E293B)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      key: const Key('add_vehicle_save_button'),
                      onPressed: _isSaving ? null : _saveVehicle,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Icon(Icons.check_circle_rounded, size: 16),
                      label: Text(
                        _isSaving ? 'SAVING VEHICLE...' : 'SAVE VEHICLE',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: RoadOSColors.cyberCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
        color: RoadOSColors.cyberCyan,
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: RoadOSColors.textMuted.withValues(alpha: 0.5), fontSize: 12),
      filled: true,
      fillColor: const Color(0xFF0E1426),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: RoadOSColors.cyberCyan, width: 1.4),
      ),
    );
  }
}
