import 'dart:convert';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import '../../../../core/vehicle_resolution/providers/my_vehicles_provider.dart';
import 'vehicle_scanner_screen.dart';

import '../../../../core/utils/constants.dart';
import '../../../../core/design_system/premium_navigation.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  String _manufacturer = '';
  String _model = '';
  String _variant = '';
  int _year = DateTime.now().year;

  bool _isSearching = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSearching = true);

    try {
      final queryParams = {
        'manufacturer': _manufacturer,
        'model': _model,
        'year': _year.toString(),
      };
      
      final uri = Uri.parse('${ApiConstants.baseUrl}/vehicles/search/query').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          // Exact match found in registry
          final profile = VehicleProfile.fromJson(data.first);
          await ref.read(myVehiclesProvider.notifier).addVehicle(profile);
          if (mounted) Navigator.pop(context);
          return;
        }
      }

      // If not found, create unverified profile
      final postUri = Uri.parse('${ApiConstants.baseUrl}/vehicles/unverified');
      final postRes = await http.post(postUri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({
        'manufacturer': _manufacturer,
        'model': _model,
        'variant': _variant,
        'year': _year,
      }));

      if (postRes.statusCode == 201) {
        final profile = VehicleProfile.fromJson(jsonDecode(postRes.body));
        await ref.read(myVehiclesProvider.notifier).addVehicle(profile);
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showLuxSnack(context, 'Failed to add vehicle: $e', variant: LuxSnackVariant.info);
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Add Vehicle', style: TextStyle(color: Colors.cyan)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Manufacturer', labelStyle: TextStyle(color: Colors.white54)),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _manufacturer = val!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Model', labelStyle: TextStyle(color: Colors.white54)),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                onSaved: (val) => _model = val!,
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Variant (Optional)', labelStyle: TextStyle(color: Colors.white54)),
                onSaved: (val) => _variant = val ?? '',
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Year', labelStyle: TextStyle(color: Colors.white54)),
                keyboardType: TextInputType.number,
                initialValue: _year.toString(),
                onSaved: (val) => _year = int.tryParse(val ?? '') ?? _year,
              ),
              const Spacer(),
              _isSearching
                  ? const CircularProgressIndicator(color: Colors.cyan)
                  : Column(
                      children: [
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, minimumSize: const Size(double.infinity, 50)),
                          onPressed: _submit,
                          child: const Text('SEARCH REGISTRY & ADD', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.camera_alt_rounded, color: Colors.cyan),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.cyan),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: () async {
                            if (_manufacturer.isEmpty) _manufacturer = 'Custom';
                            if (_model.isEmpty) _model = 'Vehicle';
                            final twin = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => VehicleScannerScreen(
                                  manufacturer: _manufacturer.isNotEmpty ? _manufacturer : 'Custom',
                                  modelName: _model.isNotEmpty ? _model : 'Vehicle',
                                  year: _year,
                                ),
                              ),
                            );
                            if (twin != null && mounted) {
                              final profile = VehicleProfile(
                                id: 'v_custom_${DateTime.now().millisecondsSinceEpoch}',
                                manufacturer: twin.manufacturer,
                                model: twin.model,
                                variant: twin.variant,
                                year: twin.year,
                                category: twin.category,
                                protocolAdapter: 'generic_ble',
                                model3DUrl: twin.modelGlbPath,
                                thumbnailUrl: twin.thumbnailUrl,
                                digitalTwinId: twin.twinId,
                                isUserScannedTwin: true,
                                scanDate: twin.scanDate,
                                scanQuality: twin.quality.code,
                              );
                              await ref.read(myVehiclesProvider.notifier).addVehicle(profile);
                              if (mounted) Navigator.pop(context);
                            }
                          },
                          label: const Text('SCAN VEHICLE (CREATE 3D TWIN)', style: TextStyle(color: Colors.cyan, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
