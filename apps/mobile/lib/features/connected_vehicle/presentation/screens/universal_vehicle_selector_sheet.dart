import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/premium_navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_connectivity/services/universal_vehicle_database.dart';
import '../../../../core/vehicle_connectivity/models/vehicle_capabilities.dart';
import '../../../../core/vehicle_connectivity/services/generic_vehicle_connectivity_engine.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import 'vehicle_compatibility_details_modal.dart';

class UniversalVehicleSelectorSheet extends ConsumerStatefulWidget {
  const UniversalVehicleSelectorSheet({super.key});

  @override
  ConsumerState<UniversalVehicleSelectorSheet> createState() => _UniversalVehicleSelectorSheetState();
}

class _UniversalVehicleSelectorSheetState extends ConsumerState<UniversalVehicleSelectorSheet> {
  final _db = UniversalVehicleDatabase();
  String? _selectedBrand;
  String? _selectedFamily;
  UniversalVehicleEntry? _selectedEntry;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final brands = _db.availableBrands;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: RoadOSColors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UNIVERSAL VEHICLE CATALOG',
                    style: TextStyle(
                      color: RoadOSColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Select 2015+ motorcycle, scooter or EV profile',
                    style: TextStyle(color: RoadOSColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: RoadOSColors.textMuted),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search box
          TextField(
            style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search brand, model or variant...',
              hintStyle: const TextStyle(color: RoadOSColors.textMuted, fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: RoadOSColors.electricBlue, size: 20),
              filled: true,
              fillColor: const Color(0xFF080C1A),
              contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: RoadOSColors.borderTranslucent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: RoadOSColors.borderTranslucent),
              ),
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val;
                _selectedBrand = null;
                _selectedFamily = null;
                _selectedEntry = null;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_searchQuery.isEmpty && _selectedBrand == null) ...[
            const Text(
              'SELECT MANUFACTURER / BRAND',
              style: TextStyle(
                color: RoadOSColors.electricBlue,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: brands.length,
                itemBuilder: (ctx, i) {
                  final brand = brands[i];
                  return InkWell(
                    onTap: () {
        LuxAudioHapticsService.lightImpact();
                      setState(() {
                        _selectedBrand = brand;
                        _selectedFamily = null;
                        _selectedEntry = null;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF080C1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF1A2035)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              brand,
                              style: const TextStyle(
                                color: RoadOSColors.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded, color: RoadOSColors.textMuted, size: 18),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ] else if (_searchQuery.isNotEmpty) ...[
            Expanded(child: _buildSearchResults()),
          ] else if (_selectedBrand != null && _selectedFamily == null) ...[
            _buildFamilySelector(),
          ] else if (_selectedFamily != null) ...[
            _buildModelVariantList(),
          ],
        ],
      ),
    );
  }

  Widget _buildFamilySelector() {
    final families = _db.getFamiliesForBrand(_selectedBrand!);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: RoadOSColors.electricBlue, size: 20),
                onPressed: () => setState(() => _selectedBrand = null),
              ),
              Text(
                '$_selectedBrand MODEL FAMILIES',
                style: const TextStyle(
                  color: RoadOSColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: families.length,
              itemBuilder: (ctx, i) {
                final family = families[i];
                return ListTile(
                  tileColor: RoadOSColors.cardSurface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: RoadOSColors.borderTranslucent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  title: Text(
                    family,
                    style: const TextStyle(color: RoadOSColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded, color: RoadOSColors.electricBlue),
                  onTap: () {
        LuxAudioHapticsService.lightImpact();
                    setState(() => _selectedFamily = family);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelVariantList() {
    final models = _db.getModelsForFamily(_selectedBrand!, _selectedFamily!);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: RoadOSColors.electricBlue, size: 20),
                onPressed: () => setState(() => _selectedFamily = null),
              ),
              Expanded(
                child: Text(
                  '$_selectedBrand $_selectedFamily VARIANTS',
                  style: const TextStyle(
                    color: RoadOSColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: models.length,
              itemBuilder: (ctx, i) {
                return _buildVehicleCard(models[i]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final results = _db.search(query: _searchQuery);
    if (results.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, color: RoadOSColors.textMuted, size: 48),
            SizedBox(height: 12),
            Text(
              'No vehicle matching search',
              style: TextStyle(color: RoadOSColors.textSecondary, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('Try brand names like Yamaha, Suzuki, KTM, Ather, BMW', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (ctx, i) => _buildVehicleCard(results[i]),
    );
  }

  Widget _buildVehicleCard(UniversalVehicleEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.brand} ${entry.model}',
                      style: const TextStyle(
                        color: RoadOSColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${entry.variant} | ${entry.modelYear}',
                      style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _buildBadge(entry.compatibilityLevel),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Display: ${entry.displayType}',
            style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                icon: const Icon(Icons.info_outline_rounded, size: 14, color: RoadOSColors.electricBlue),
                label: const Text('Capability Matrix', style: TextStyle(color: RoadOSColors.electricBlue, fontSize: 11)),
                onPressed: () {
        LuxAudioHapticsService.lightImpact();
                  showLuxSheet(
                context: context,
                title: '',
                    builder: (_) => VehicleCompatibilityDetailsModal(
                      vehicleName: entry.model,
                      manufacturer: entry.brand,
                      year: entry.modelYear.toString(),
                      capabilities: entry.capabilities,
                      compatibilityLevel: entry.compatibilityLevel,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RoadOSColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  await GenericVehicleConnectivityEngine().connectVehicle(
                    targetIdentifier: entry.id,
                    protocolAdapterId: entry.protocolAdapterId,
                  );

                  final profile = VehicleProfile(
                    id: entry.id,
                    manufacturer: entry.brand,
                    model: entry.model,
                    variant: entry.variant,
                    year: entry.modelYear,
                    category: entry.vehicleType,
                    fuelType: entry.fuelType,
                    protocolAdapter: entry.protocolAdapterId,
                    model3DUrl: entry.model3DUrl ?? '',
                    thumbnailUrl: entry.thumbnailUrl ?? 'assets/garage/generic_bike.png',
                    isVerified: true,
                  );

                  ref.read(activeVehicleContextProvider.notifier).switchVehicle(profile);
                  if (mounted) {
                    Navigator.pop(context);
                    showLuxSnack(context, 'Switched to ${entry.fullName}', variant: LuxSnackVariant.info);
                  }
                },
                child: const Text('SELECT & ACTIVATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(VehicleCompatibilityLevel level) {
    Color color = level == VehicleCompatibilityLevel.full
        ? RoadOSColors.apexEmerald
        : (level == VehicleCompatibilityLevel.partial ? RoadOSColors.warningAmber : RoadOSColors.electricBlue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        level.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }
}
