import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import '../../../../core/vehicle_resolution/providers/my_vehicles_provider.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  
  String _category = 'Motorcycle';
  final _manufacturerController = TextEditingController();
  final _modelController = TextEditingController();
  final _vinController = TextEditingController();
  final _yearController = TextEditingController();
  final _batteryController = TextEditingController();
  final _engineCcController = TextEditingController();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _manufacturerController.dispose();
    _modelController.dispose();
    _vinController.dispose();
    _yearController.dispose();
    _batteryController.dispose();
    _engineCcController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final profile = VehicleProfile(
        id: '', // Backend generates ID
        manufacturer: _manufacturerController.text.trim(),
        model: _modelController.text.trim(),
        year: int.parse(_yearController.text.trim()),
        category: _category,
        vin: _vinController.text.trim().isEmpty ? null : _vinController.text.trim(),
        batteryCapacityKwh: _batteryController.text.trim().isEmpty ? null : double.parse(_batteryController.text.trim()),
        displacementCc: _engineCcController.text.trim().isEmpty ? null : int.parse(_engineCcController.text.trim()),
        protocolAdapter: 'generic_ble',
        model3DUrl: '',
        thumbnailUrl: '',
      );

      await ref.read(myVehiclesProvider.notifier).addVehicle(profile);
      
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add vehicle: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEV = _category == 'Electric Vehicle' || _category == 'Electric Scooter';
    final isICE = _category == 'Motorcycle' || _category == 'Car' || _category == 'Scooter';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('ADD VEHICLE', style: TextStyle(fontFamily: 'Orbitron', fontWeight: FontWeight.bold, letterSpacing: 1.5, color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  dropdownColor: const Color(0xFF1A1A1A),
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Category',
                    labelStyle: TextStyle(color: RoadOSColors.cyberCyan),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: RoadOSColors.borderTranslucent)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: RoadOSColors.cyberCyan)),
                  ),
                  items: ['Car', 'Motorcycle', 'Scooter', 'Electric Vehicle', 'Electric Scooter']
                      .map((c) => DropdownMenuItem<String>(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _category = val);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _manufacturerController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Manufacturer',
                    labelStyle: TextStyle(color: RoadOSColors.borderTranslucent),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: RoadOSColors.borderTranslucent)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: RoadOSColors.cyberCyan)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _modelController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Model',
                    labelStyle: TextStyle(color: RoadOSColors.borderTranslucent),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: RoadOSColors.borderTranslucent)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: RoadOSColors.cyberCyan)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _yearController,
                  style: const TextStyle(color: Colors.white),
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Year',
                    labelStyle: TextStyle(color: RoadOSColors.borderTranslucent),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: RoadOSColors.borderTranslucent)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: RoadOSColors.cyberCyan)),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _vinController,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'VIN (Optional, 17 chars)',
                    labelStyle: TextStyle(color: RoadOSColors.borderTranslucent),
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: RoadOSColors.borderTranslucent)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: RoadOSColors.cyberCyan)),
                  ),
                ),
                const SizedBox(height: 16),
                if (isEV)
                  TextFormField(
                    controller: _batteryController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Battery Capacity (kWh) (Optional)',
                      labelStyle: TextStyle(color: RoadOSColors.borderTranslucent),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: RoadOSColors.borderTranslucent)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: RoadOSColors.cyberCyan)),
                    ),
                  ),
                if (isICE)
                  TextFormField(
                    controller: _engineCcController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Engine CC (Optional)',
                      labelStyle: TextStyle(color: RoadOSColors.borderTranslucent),
                      enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: RoadOSColors.borderTranslucent)),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: RoadOSColors.cyberCyan)),
                    ),
                  ),
                const SizedBox(height: 48),
                if (_isLoading)
                  const Center(child: CircularProgressIndicator(color: RoadOSColors.cyberCyan))
                else
                  RoadOSButton(
                    label: 'REGISTER VEHICLE',
                    onPressed: _submit,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
