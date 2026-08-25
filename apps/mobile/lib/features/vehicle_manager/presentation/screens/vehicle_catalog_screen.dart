import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/widgets/cinematic_background.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import '../../../../core/vehicle_resolution/models/vehicle_catalog_models.dart';
import '../../../../core/vehicle_resolution/services/vehicle_registry.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';
import '../../../garage/presentation/screens/luxury_garage_showroom_screen.dart';
import '../../../../core/design_system/premium_navigation.dart';

class VehicleCatalogScreen extends ConsumerStatefulWidget {
  const VehicleCatalogScreen({super.key});

  @override
  ConsumerState<VehicleCatalogScreen> createState() => _VehicleCatalogScreenState();
}

class _VehicleCatalogScreenState extends ConsumerState<VehicleCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  CatalogFilterState _filterState = const CatalogFilterState();
  final Set<String> _favoriteIds = {'v_ducati_v4s', 'v_bmw_m1000rr', 'v_yamaha_r1m', 'v_re_classic_350'};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filterState = _filterState.copyWith(searchQuery: query);
    });
  }

  void _selectBrand(String? brand) {
    LuxAudioHapticsService.lightImpact();
    setState(() {
      if (_filterState.selectedBrand == brand) {
        _filterState = _filterState.copyWith(clearBrand: true);
      } else {
        _filterState = _filterState.copyWith(selectedBrand: brand);
      }
    });
  }

  void _selectCategory(VehicleTypeCategory? category) {
    LuxAudioHapticsService.lightImpact();
    setState(() {
      if (_filterState.selectedCategory == category) {
        _filterState = _filterState.copyWith(clearCategory: true);
      } else {
        _filterState = _filterState.copyWith(selectedCategory: category);
      }
    });
  }

  void _toggleFavorite(String id) {
    LuxAudioHapticsService.selectionClick();
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final registry = VehicleRegistry();
    final allBrands = registry.allBrands;
    final filteredVehicles = registry.filter(_filterState, favoriteIds: _favoriteIds);
    final activeContext = ref.watch(activeVehicleContextProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'VEHICLE CATALOG',
              style: RoadOSTypography.screenTitle.copyWith(fontSize: 16, letterSpacing: 1.5),
            ),
            Text(
              '${filteredVehicles.length} MODELS AVAILABLE',
              style: const TextStyle(fontSize: 10, color: RoadOSColors.cyberCyan, fontWeight: FontWeight.w600, letterSpacing: 1.0),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _filterState.onlyFavorites ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _filterState.onlyFavorites ? const Color(0xFFFF2A6D) : Colors.white70,
              size: 22,
            ),
            onPressed: () {
              LuxAudioHapticsService.lightImpact();
              setState(() {
                _filterState = _filterState.copyWith(onlyFavorites: !_filterState.onlyFavorites);
              });
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: CinematicBackground(
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + 56),
          // 1. Search Bar & 3D Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0x2817264D), Color(0x150A1024)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: RoadOSColors.borderSubtle),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _onSearchChanged,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Search brand, model, engine...',
                            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                            prefixIcon: const Icon(Icons.search_rounded, color: RoadOSColors.cyberCyan, size: 20),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 18),
                                    onPressed: () {
                                      _searchController.clear();
                                      _onSearchChanged('');
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                LiquidWaterRipple(
                  borderRadius: 14,
                  rippleColor: RoadOSColors.cyberCyan,
                  onTap: () {
                    LuxAudioHapticsService.lightImpact();
                    setState(() {
                      _filterState = _filterState.copyWith(only3DReady: !_filterState.only3DReady);
                    });
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          gradient: _filterState.only3DReady
                              ? const LinearGradient(
                                  colors: [Color(0x4000F2FE), Color(0x200066FF)],
                                )
                              : const LinearGradient(
                                  colors: [Color(0x22131D3B), Color(0x10070C1E)],
                                ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _filterState.only3DReady ? RoadOSColors.cyberCyan : RoadOSColors.borderSubtle,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.view_in_ar_rounded,
                              size: 18,
                              color: _filterState.only3DReady ? RoadOSColors.cyberCyan : Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '3D Ready',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: _filterState.only3DReady ? RoadOSColors.cyberCyan : Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Brand Filter Carousel
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFilterChip(
                  label: 'All Brands',
                  isSelected: _filterState.selectedBrand == null,
                  onTap: () => _selectBrand(null),
                ),
                ...allBrands.map((b) => _buildFilterChip(
                      label: b.name,
                      count: b.totalModels,
                      isSelected: _filterState.selectedBrand?.toLowerCase() == b.name.toLowerCase(),
                      onTap: () => _selectBrand(b.name),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 3. Category Filter Chips
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip(
                  label: 'All Categories',
                  isSelected: _filterState.selectedCategory == null,
                  onTap: () => _selectCategory(null),
                ),
                ...VehicleTypeCategory.values.map((c) => _buildCategoryChip(
                      label: c.label,
                      isSelected: _filterState.selectedCategory == c,
                      onTap: () => _selectCategory(c),
                    )),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 4. Vehicle List Grid / Cards
          Expanded(
            child: filteredVehicles.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filteredVehicles.length,
                    itemBuilder: (context, index) {
                      final vehicle = filteredVehicles[index];
                      final isActive = activeContext.vehicleId == vehicle.id;
                      final isFavorite = _favoriteIds.contains(vehicle.id);
                      return _buildVehicleCatalogCard(context, ref, vehicle, isActive, isFavorite);
                    },
                  ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    int? count,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return LiquidWaterRipple(
      borderRadius: 10,
      rippleColor: RoadOSColors.cyberCyan,
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0xFF00F2FE), Color(0xFF0066FF)],
                    )
                  : const LinearGradient(
                      colors: [Color(0x2817264D), Color(0x120A1024)],
                    ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? RoadOSColors.cyberCyan : RoadOSColors.borderSubtle,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? Colors.black : Colors.white,
                  ),
                ),
                if (count != null) ...[
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : Colors.white70,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return LiquidWaterRipple(
      borderRadius: 8,
      rippleColor: const Color(0xFF00FF66),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? const LinearGradient(
                      colors: [Color(0x3500FF66), Color(0x1500FF66)],
                    )
                  : const LinearGradient(
                      colors: [Color(0x18FFFFFF), Color(0x08FFFFFF)],
                    ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? const Color(0xFF00FF66) : RoadOSColors.borderSubtle,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF00FF66) : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVehicleCatalogCard(
    BuildContext context,
    WidgetRef ref,
    VehicleProfile vehicle,
    bool isActive,
    bool isFavorite,
  ) {
    final has3d = vehicle.has3DModel;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: isActive
            ? RoadOSShadows.cyanGlow(opacity: 0.3, blur: 20)
            : RoadOSShadows.luxuryCard,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          children: [
            // 1. Liquid Water-Glass Base with Backdrop Blur
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0x3500F2FE), Color(0x18162244), Color(0x150A1024)],
                          )
                        : RoadOSGradients.liquidWaterGlass,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isActive
                          ? RoadOSColors.cyberCyan
                          : (has3d ? const Color(0xFF00FF66).withValues(alpha: 0.45) : RoadOSColors.borderSubtle),
                      width: isActive ? 1.5 : 1.0,
                    ),
                  ),
                ),
              ),
            ),

            // 2. Specular Water Sheen
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: RoadOSGradients.waterSheenOverlay,
                  ),
                ),
              ),
            ),

            // 3. Card Content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Top Header: Make, Category Badge & Favorite
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: RoadOSColors.cyberCyan.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: RoadOSColors.cyberCyan.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        vehicle.manufacturer.toUpperCase(),
                        style: const TextStyle(
                          color: RoadOSColors.cyberCyan,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        vehicle.category,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF66).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFF00FF66)),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Color(0xFF00FF66),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: Icon(
                    isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: isFavorite ? const Color(0xFFFF2A6D) : Colors.white38,
                    size: 20,
                  ),
                  onPressed: () => _toggleFavorite(vehicle.id),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Model Title & Variant
            Text(
              vehicle.model,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (vehicle.variant.isNotEmpty)
              Text(
                vehicle.variant,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 12,
                ),
              ),

            const SizedBox(height: 12),

            // Specifications Grid Pill Strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSpecMetric(
                    label: vehicle.fuelType == 'Electric' ? 'BATTERY' : 'ENGINE',
                    value: vehicle.fuelType == 'Electric'
                        ? '${vehicle.batteryCapacityKwh ?? 0} kWh'
                        : '${vehicle.displacementCc ?? 0} cc',
                  ),
                  _buildDivider(),
                  _buildSpecMetric(
                    label: 'POWER',
                    value: '${vehicle.powerBhp ?? 0} HP',
                  ),
                  _buildDivider(),
                  _buildSpecMetric(
                    label: 'TORQUE',
                    value: '${vehicle.torqueNm ?? 0} Nm',
                  ),
                  _buildDivider(),
                  _buildSpecMetric(
                    label: 'WEIGHT',
                    value: '${vehicle.curbWeightKg?.round() ?? 0} kg',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Bottom Actions & 3D Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 3D Verification Badge
                Row(
                  children: [
                    Icon(
                      has3d
                          ? Icons.check_circle_rounded
                          : (vehicle.isVerified ? Icons.info_outline_rounded : Icons.pending_rounded),
                      size: 14,
                      color: has3d
                          ? const Color(0xFF00FF66)
                          : (vehicle.isVerified ? Colors.white60 : const Color(0xFFFFB300)),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      vehicle.model3DStatus,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: has3d
                            ? const Color(0xFF00FF66)
                            : (vehicle.isVerified ? Colors.white60 : const Color(0xFFFFB300)),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),

                // Action Buttons
                Row(
                  children: [
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () {
                        LuxAudioHapticsService.lightImpact();
                        ref.read(activeVehicleContextProvider.notifier).switchVehicle(vehicle);
                        Navigator.push(
                          context,
                          premiumRoute(const LuxuryGarageShowroomScreen()),
                        );
                      },
                      child: const Text(
                        '3D View',
                        style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isActive ? const Color(0xFF00FF66) : RoadOSColors.cyberCyan,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        LuxAudioHapticsService.heavyImpact();
                        ref.read(activeVehicleContextProvider.notifier).switchVehicle(vehicle);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            backgroundColor: const Color(0xFF060912),
                            behavior: SnackBarBehavior.floating,
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF00FF66), size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  'Activated ${vehicle.manufacturer} ${vehicle.model}',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Text(
                        isActive ? 'Active' : 'Select',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  ),
),
);
}

  Widget _buildSpecMetric({required String label, required String value}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 56, color: Colors.white.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'No matching vehicles found',
            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search query or filter tags',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
          ),
        ],
      ),
    );
  }
}
