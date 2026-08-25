import '../models/vehicle_profile.dart';
import '../models/vehicle_catalog_models.dart';
import 'vehicle_catalog_data.dart';

class VehicleRegistry {
  static final VehicleRegistry _instance = VehicleRegistry._internal();
  factory VehicleRegistry() => _instance;
  VehicleRegistry._internal();

  /// Authoritative list of all multi-brand catalog vehicle profiles
  List<VehicleProfile> get verifiedProfiles => List.unmodifiable(VehicleCatalogData.catalogProfiles);

  /// All supported major brands
  List<VehicleBrand> get allBrands => List.unmodifiable(VehicleCatalogData.allBrands);

  /// Default verified vehicle profile
  VehicleProfile get defaultProfile => VehicleCatalogData.catalogProfiles.first;

  /// Retrieve a specific profile by unique ID
  VehicleProfile? getProfileById(String id) {
    try {
      return VehicleCatalogData.catalogProfiles.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Resolve vehicle profile by Bluetooth advertisement identifier
  VehicleProfile? findProfileByBluetoothName(String deviceName) {
    final lower = deviceName.toLowerCase().replaceAll('_', '-');
    final rawLower = deviceName.toLowerCase();
    VehicleProfile? bestMatch;
    int longestMatchLength = 0;

    for (final profile in VehicleCatalogData.catalogProfiles) {
      for (final identifier in profile.bluetoothIdentifiers) {
        final idLower = identifier.toLowerCase();
        final idNormalized = idLower.replaceAll('_', '-');
        if ((rawLower.contains(idLower) || lower.contains(idNormalized)) && idNormalized.length > longestMatchLength) {
          longestMatchLength = idNormalized.length;
          bestMatch = profile;
        }
      }
    }
    return bestMatch;
  }

  /// Filter vehicles by brand / manufacturer
  List<VehicleProfile> getProfilesByManufacturer(String manufacturer) {
    if (manufacturer.toLowerCase() == 'all' || manufacturer.toLowerCase() == 'all brands') {
      return verifiedProfiles;
    }
    return VehicleCatalogData.catalogProfiles
        .where((p) => p.manufacturer.toLowerCase() == manufacturer.toLowerCase())
        .toList();
  }

  /// Filter vehicles by category
  List<VehicleProfile> getProfilesByCategory(VehicleTypeCategory category) {
    return VehicleCatalogData.catalogProfiles
        .where((p) => VehicleTypeCategory.fromLabel(p.category) == category)
        .toList();
  }

  /// General search across make, model, variant, category, engine
  List<VehicleProfile> search(String query) {
    if (query.trim().isEmpty) return verifiedProfiles;
    final q = query.toLowerCase().trim();
    return VehicleCatalogData.catalogProfiles.where((p) {
      final text = '${p.manufacturer} ${p.model} ${p.variant} ${p.category} ${p.engineType ?? ''}'.toLowerCase();
      return text.contains(q);
    }).toList();
  }

  /// Advanced composite filter
  List<VehicleProfile> filter(CatalogFilterState state, {Set<String> favoriteIds = const {}}) {
    return VehicleCatalogData.catalogProfiles
        .where((p) => state.matches(p, favoriteIds: favoriteIds))
        .toList();
  }
}
