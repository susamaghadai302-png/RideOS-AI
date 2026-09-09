import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/design_system/premium_navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_catalog/models/vehicle_catalog_models.dart';
import '../../../../core/vehicle_catalog/services/universal_vehicle_catalog_service.dart';
import '../../../../core/vehicle_connectivity/models/vehicle_capabilities.dart';
import '../../../../core/vehicle_connectivity/services/generic_vehicle_connectivity_engine.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';
import '../../../../core/vehicle_resolution/providers/active_vehicle_context_provider.dart';

class VehicleCatalogBrowserScreen extends ConsumerStatefulWidget {
  const VehicleCatalogBrowserScreen({super.key});

  @override
  ConsumerState<VehicleCatalogBrowserScreen> createState() => _VehicleCatalogBrowserScreenState();
}

class _VehicleCatalogBrowserScreenState extends ConsumerState<VehicleCatalogBrowserScreen> {
  final _catalogService = UniversalVehicleCatalogService();

  String? _selectedVehicleType;
  String? _selectedBrand;
  String? _selectedFuelType;
  VehicleCompatibilityLevel? _selectedCompatibility;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final results = _catalogService.searchAndFilter(
      CatalogFilterCriteria(
        vehicleType: _selectedVehicleType,
        brand: _selectedBrand,
        fuelType: _selectedFuelType,
        compatibility: _selectedCompatibility,
        searchQuery: _searchQuery,
      ),
    );

    final brands = _catalogService.getAvailableBrands(vehicleType: _selectedVehicleType);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'UNIVERSAL VEHICLE CATALOG',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: RoadOSColors.electricBlue.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'v${UniversalVehicleCatalogService.catalogVersion}',
              style: TextStyle(color: RoadOSColors.electricBlue, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: CinematicBackground(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSearchBar(),
          _buildFilterChips(brands),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${results.length} COMPATIBLE 2015+ PROFILES',
                  style: const TextStyle(
                    color: RoadOSColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                if (_hasActiveFilters())
                  InkWell(
                    onTap: _clearFilters,
                    child: const Text(
                      'Clear Filters',
                      style: TextStyle(color: RoadOSColors.electricBlue, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: results.isEmpty ? _buildEmptyResults() : _buildProfileList(results),
          ),
        ],
      )),
    );
  }

  bool _hasActiveFilters() =>
      _selectedVehicleType != null ||
      _selectedBrand != null ||
      _selectedFuelType != null ||
      _selectedCompatibility != null ||
      _searchQuery.isNotEmpty;

  void _clearFilters() {
    setState(() {
      _selectedVehicleType = null;
      _selectedBrand = null;
      _selectedFuelType = null;
      _selectedCompatibility = null;
      _searchQuery = '';
    });
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: TextField(
        style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search brand, model, "2025 Yamaha", "EV scooter", "BLE"...',
          hintStyle: const TextStyle(color: RoadOSColors.textMuted, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded, color: RoadOSColors.electricBlue, size: 20),
          filled: true,
          fillColor: const Color(0xFF080C1A),
          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: RoadOSColors.borderTranslucent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: RoadOSColors.borderTranslucent),
          ),
        ),
        onChanged: (val) => setState(() => _searchQuery = val),
      ),
    );
  }

  Widget _buildFilterChips(List<String> brands) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterChip('All Types', _selectedVehicleType == null, () => setState(() => _selectedVehicleType = null)),
          _buildFilterChip('Motorcycles', _selectedVehicleType == 'Motorcycle', () => setState(() => _selectedVehicleType = 'Motorcycle')),
          _buildFilterChip('Scooters', _selectedVehicleType == 'Scooter', () => setState(() => _selectedVehicleType = 'Scooter')),
          _buildFilterChip('Electric (EV)', _selectedFuelType == 'Electric', () => setState(() => _selectedFuelType = _selectedFuelType == 'Electric' ? null : 'Electric')),
          const SizedBox(width: 8),
          Container(width: 1, height: 20, color: RoadOSColors.borderTranslucent),
          const SizedBox(width: 8),
          ...brands.map((b) => _buildFilterChip(b, _selectedBrand == b, () => setState(() => _selectedBrand = _selectedBrand == b ? null : b))),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(color: isSelected ? Colors.white : RoadOSColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
        selected: isSelected,
        selectedColor: RoadOSColors.electricBlue,
        backgroundColor: RoadOSColors.cardSurface,
        onSelected: (_) => onTap(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: isSelected ? RoadOSColors.electricBlue : RoadOSColors.borderTranslucent),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildProfileList(List<UniversalVehicleProfile> list) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      itemCount: list.length,
      itemBuilder: (ctx, i) {
        final item = list[i];
        return _buildProfileCard(item);
      },
    );
  }

  Widget _buildProfileCard(UniversalVehicleProfile p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(16),
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
                      '${p.brand} ${p.model}',
                      style: const TextStyle(
                        color: RoadOSColors.textPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${p.variant} | ${p.modelYear} | ${p.fuelType}',
                      style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _buildVerificationBadge(p.verification),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.tv_rounded, size: 14, color: RoadOSColors.electricBlue),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  p.displaySystem.displayType,
                  style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (p.connectivity.requiresExternalGateway) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.cable_rounded, size: 14, color: RoadOSColors.warningAmber),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Gateway: ${p.connectivity.gatewayType ?? "Diagnostic Interface Required"}',
                    style: const TextStyle(color: RoadOSColors.warningAmber, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompatibilityTag(p.compatibility),
              Row(
                children: [
                  TextButton(
                    onPressed: () => _openDetailsModal(p),
                    child: const Text('View Specs', style: TextStyle(color: RoadOSColors.electricBlue, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 6),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RoadOSColors.electricBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _activateProfile(p),
                    child: const Text('ACTIVATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(VerificationSource src) {
    Color color;
    switch (src) {
      case VerificationSource.verified:
        color = RoadOSColors.apexEmerald;
        break;
      case VerificationSource.documented:
        color = RoadOSColors.electricBlue;
        break;
      case VerificationSource.experimental:
        color = RoadOSColors.warningAmber;
        break;
      default:
        color = RoadOSColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        src.label,
        style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildCompatibilityTag(VehicleCompatibilityLevel level) {
    Color color;
    switch (level) {
      case VehicleCompatibilityLevel.full:
        color = RoadOSColors.apexEmerald;
        break;
      case VehicleCompatibilityLevel.partial:
        color = RoadOSColors.warningAmber;
        break;
      case VehicleCompatibilityLevel.diagnosticOnly:
        color = RoadOSColors.electricBlue;
        break;
      case VehicleCompatibilityLevel.displayOnly:
        color = RoadOSColors.neonViolet;
        break;
      default:
        color = RoadOSColors.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        level.name.toUpperCase(),
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEmptyResults() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, color: RoadOSColors.textMuted, size: 52),
          SizedBox(height: 12),
          Text('No vehicle profiles match the filter', style: TextStyle(color: RoadOSColors.textSecondary, fontWeight: FontWeight.bold, fontSize: 14)),
          SizedBox(height: 4),
          Text('Try broadening your search or resetting filters', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  void _openDetailsModal(UniversalVehicleProfile p) {
    showLuxSheet(
                context: context,
                title: '',
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: ListView(
          children: [
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(color: RoadOSColors.textMuted, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(p.fullName, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Protocol Adapter: ${p.connectivity.primaryProtocolAdapterId} (v${p.connectivity.adapterVersion})',
                style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 12)),
            const Divider(color: RoadOSColors.borderTranslucent, height: 24),
            const Text('DISPLAY & TELEMETRY HARDWARE', style: TextStyle(color: RoadOSColors.electricBlue, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            Text('| Display Unit: ${p.displaySystem.displayType}', style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13)),
            Text('| Turn-by-Turn Nav: ${p.displaySystem.hasTurnByTurnNav ? "Supported" : "Unavailable"}', style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13)),
            Text('| Caller ID & Alerts: ${p.displaySystem.hasCallerId ? "Supported" : "Unavailable"}', style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13)),
            Text('| External Gateway: ${p.connectivity.requiresExternalGateway ? p.connectivity.gatewayType : "Not required (Direct wireless CCU)"}',
                style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13)),
            const Divider(color: RoadOSColors.borderTranslucent, height: 24),
            const Text('CAPABILITY MATRIX', style: TextStyle(color: RoadOSColors.electricBlue, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            const SizedBox(height: 8),
            _buildCapabilityRow('Real-time Speed', p.capabilities.speed),
            _buildCapabilityRow('Engine RPM', p.capabilities.rpm),
            _buildCapabilityRow('Battery 12V Health', p.capabilities.batteryVoltage),
            _buildCapabilityRow('Fuel / EV SoC', p.capabilities.fuelLevel != CapabilitySupportLevel.notSupported ? p.capabilities.fuelLevel : p.capabilities.batteryLevel),
            _buildCapabilityRow('Engine / Motor Temp', p.capabilities.engineTemperature),
            _buildCapabilityRow('Diagnostic DTC Codes', p.capabilities.diagnosticCodes),
            _buildCapabilityRow('Navigation TBT HUD', p.capabilities.navigationData),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: RoadOSColors.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
        LuxAudioHapticsService.lightImpact();
                  Navigator.pop(ctx);
                  _activateProfile(p);
                },
                child: const Text('ACTIVATE & CONNECT VEHICLE', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapabilityRow(String title, CapabilitySupportLevel level) {
    final isSupp = level == CapabilitySupportLevel.supported || level == CapabilitySupportLevel.readOnly || level == CapabilitySupportLevel.readWrite;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 13)),
          Text(
            isSupp ? 'Supported' : 'Unavailable',
            style: TextStyle(color: isSupp ? RoadOSColors.apexEmerald : RoadOSColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _activateProfile(UniversalVehicleProfile p) async {
    final profile = VehicleProfile(
      id: p.id,
      manufacturer: p.brand,
      model: p.model,
      variant: p.variant,
      year: p.modelYear,
      category: p.vehicleType,
      fuelType: p.fuelType,
      protocolAdapter: p.connectivity.primaryProtocolAdapterId,
      model3DUrl: p.model3DUrl ?? '',
      thumbnailUrl: p.thumbnailUrl ?? 'assets/garage/generic_bike.png',
      isVerified: p.verification == VerificationSource.verified,
    );

    await GenericVehicleConnectivityEngine().connectVehicle(
      targetIdentifier: p.id,
      protocolAdapterId: p.connectivity.primaryProtocolAdapterId,
    );

    ref.read(activeVehicleContextProvider.notifier).switchVehicle(profile);
    if (mounted) {
      showLuxSnack(context, 'Activated profile for ${p.fullName}', variant: LuxSnackVariant.info);
    }
  }
}
