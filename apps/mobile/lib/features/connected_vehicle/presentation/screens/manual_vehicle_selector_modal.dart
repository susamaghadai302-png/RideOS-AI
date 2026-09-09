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

/// Full-featured, offline-resilient Manual Vehicle Selector Sheet for RideOS-AI.
/// Allows selecting from all 21 manufacturers and 150+ models, with category filtering,
/// real specifications, and 1-tap "CONNECT VEHICLE" / "ADD TO MY VEHICLES".
class ManualVehicleSelectorModal extends ConsumerStatefulWidget {
  final VoidCallback? onVehicleConnected;

  const ManualVehicleSelectorModal({super.key, this.onVehicleConnected});

  @override
  ConsumerState<ManualVehicleSelectorModal> createState() => _ManualVehicleSelectorModalState();
}

class _ManualVehicleSelectorModalState extends ConsumerState<ManualVehicleSelectorModal> {
  final _db = UniversalVehicleDatabase();
  String _selectedCategory = 'ALL';
  String? _selectedBrand;
  UniversalVehicleEntry? _selectedEntry;
  String _searchQuery = '';

  final List<String> _categories = const [
    'ALL',
    'Motorcycle',
    'Scooter',
    'Electric',
  ];

  @override
  Widget build(BuildContext context) {
    final allBrands = _db.availableBrands;
    final entries = _getFilteredEntries();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      padding: EdgeInsets.only(
        left: 18,
        right: 18,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF070B18),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag pill
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
          const SizedBox(height: 14),

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
                    child: const Icon(Icons.manage_search_rounded, color: RoadOSColors.cyberCyan, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MANUAL VEHICLE SELECTION',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        'Select any two-wheeler without Bluetooth required',
                        style: GoogleFonts.inter(
                          color: RoadOSColors.textMuted,
                          fontSize: 10.5,
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
          const SizedBox(height: 12),

          // Search Field
          TextField(
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Search brand, model, or variant...',
              hintStyle: GoogleFonts.inter(color: RoadOSColors.textMuted.withValues(alpha: 0.5), fontSize: 12),
              prefixIcon: const Icon(Icons.search_rounded, color: RoadOSColors.cyberCyan, size: 18),
              filled: true,
              fillColor: const Color(0xFF0E1426),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
            ),
            onChanged: (val) {
              setState(() {
                _searchQuery = val.trim();
                _selectedEntry = null;
              });
            },
          ),
          const SizedBox(height: 10),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () {
                      LuxAudioHapticsService.lightImpact();
                      setState(() {
                        _selectedCategory = cat;
                        _selectedEntry = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? RoadOSColors.cyberCyan.withValues(alpha: 0.18) : const Color(0xFF0E1426),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? RoadOSColors.cyberCyan : const Color(0xFF1E293B),
                          width: isSelected ? 1.4 : 1.0,
                        ),
                      ),
                      child: Text(
                        cat,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.textMuted,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),

          // Main Selection Area: List of vehicles or Selected Vehicle Details
          Expanded(
            child: _selectedEntry != null
                ? _buildSelectedVehiclePreview(_selectedEntry!)
                : _buildVehicleList(entries, allBrands),
          ),
        ],
      ),
    );
  }

  List<UniversalVehicleEntry> _getFilteredEntries() {
    var list = _db.allEntries;

    if (_selectedCategory == 'Motorcycle') {
      list = list.where((e) => e.vehicleType.contains('Motorcycle')).toList();
    } else if (_selectedCategory == 'Scooter') {
      list = list.where((e) => e.vehicleType.contains('Scooter')).toList();
    } else if (_selectedCategory == 'Electric') {
      list = list.where((e) => e.fuelType == 'Electric' || e.vehicleType.contains('Electric')).toList();
    }

    if (_selectedBrand != null) {
      list = list.where((e) => e.brand.toLowerCase() == _selectedBrand!.toLowerCase()).toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) {
        return e.brand.toLowerCase().contains(q) ||
            e.model.toLowerCase().contains(q) ||
            e.variant.toLowerCase().contains(q) ||
            e.family.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  Widget _buildVehicleList(List<UniversalVehicleEntry> entries, List<String> allBrands) {
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.two_wheeler_rounded, size: 40, color: Color(0xFF1E293B)),
            const SizedBox(height: 10),
            Text(
              'No matching vehicle found',
              style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search or brand filter',
              style: GoogleFonts.inter(color: RoadOSColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0E1426),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1E293B)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                LuxAudioHapticsService.lightImpact();
                setState(() {
                  _selectedEntry = entry;
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: RoadOSColors.cyberCyan.withValues(alpha: 0.12),
                      ),
                      child: const Center(
                        child: Icon(Icons.two_wheeler_rounded, color: RoadOSColors.cyberCyan, size: 20),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${entry.brand} ${entry.model}',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${entry.variant} | ${entry.modelYear} | ${entry.vehicleType}',
                            style: GoogleFonts.inter(
                              color: RoadOSColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: RoadOSColors.cyberCyan, size: 20),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedVehiclePreview(UniversalVehicleEntry entry) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: RoadOSColors.cyberCyan),
                onPressed: () {
                  LuxAudioHapticsService.lightImpact();
                  setState(() => _selectedEntry = null);
                },
              ),
              Text(
                'VEHICLE PREVIEW',
                style: GoogleFonts.outfit(
                  color: RoadOSColors.cyberCyan,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Vehicle Card Preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0E1426),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.4), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: RoadOSColors.cyberCyan.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              ],
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
                            entry.brand,
                            style: GoogleFonts.outfit(
                              color: RoadOSColors.cyberCyan,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            entry.model,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '${entry.variant} | ${entry.modelYear}',
                            style: GoogleFonts.inter(
                              color: RoadOSColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: RoadOSColors.cyberCyan.withValues(alpha: 0.12),
                      ),
                      child: const Icon(Icons.two_wheeler_rounded, color: RoadOSColors.cyberCyan, size: 28),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0x331F293D), height: 1),
                const SizedBox(height: 12),

                // Specs Grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSpecItem('TYPE', entry.vehicleType),
                    _buildSpecItem('FUEL', entry.fuelType),
                    _buildSpecItem('DISPLAY', entry.displayType),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Connect & Add Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _connectAndSave(entry, onlyAdd: true),
                  icon: const Icon(Icons.garage_rounded, size: 16),
                  label: Text(
                    'ADD TO GARAGE',
                    style: GoogleFonts.outfit(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: RoadOSColors.cyberCyan,
                    side: const BorderSide(color: RoadOSColors.cyberCyan),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  key: const Key('manual_connect_button'),
                  onPressed: () => _connectAndSave(entry, onlyAdd: false),
                  icon: const Icon(Icons.bolt_rounded, size: 18),
                  label: Text(
                    'CONNECT VEHICLE',
                    style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.0),
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
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.robotoMono(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Future<void> _connectAndSave(UniversalVehicleEntry entry, {required bool onlyAdd}) async {
    LuxAudioHapticsService.mediumImpact();

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
      specifications: {
        'display': entry.displayType,
        'connectionMethod': entry.connectionMethod.name,
      },
    );

    // Save to My Vehicles repository
    await ref.read(myVehiclesProvider.notifier).addVehicle(profile);

    // If connecting, switch active vehicle context
    if (!onlyAdd) {
      ref.read(activeVehicleContextProvider.notifier).switchVehicle(profile);
    }

    LuxAudioHapticsService.successPattern();

    if (mounted) {
      widget.onVehicleConnected?.call();
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      showLuxSnack(
        context,
        onlyAdd
            ? 'Added ${entry.brand} ${entry.model} to My Vehicles.'
            : 'Active vehicle connected: ${entry.brand} ${entry.model}',
        variant: LuxSnackVariant.success,
      );
    }
  }
}
