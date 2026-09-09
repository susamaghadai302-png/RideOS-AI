import '../models/vehicle_identity_confidence.dart';
import 'vehicle_registry.dart';
import 'digital_twin_storage_service.dart';

class VehicleIdentityConfidenceEngine {
  static final VehicleIdentityConfidenceEngine _instance = VehicleIdentityConfidenceEngine._internal();
  factory VehicleIdentityConfidenceEngine() => _instance;
  VehicleIdentityConfidenceEngine._internal();

  final VehicleRegistry _registry = VehicleRegistry();
  final DigitalTwinStorageService _twinStorage = DigitalTwinStorageService();

  /// Evaluates vehicle identity based on Bluetooth advertising name, OBD PID response, or manual info.
  Future<VehicleIdentityResult> evaluateIdentity({
    String? bluetoothName,
    String? vin,
    String? ecuCalibrationId,
    String? protocol,
    String? userSpecifiedMake,
    String? userSpecifiedModel,
    int? userSpecifiedYear,
  }) async {
    final btClean = (bluetoothName ?? '').trim().toUpperCase();
    final vinClean = (vin ?? '').trim().toUpperCase();

    // 1. Check if user already has a saved Digital Twin for this exact device or VIN
    final allTwins = await _twinStorage.getAllDigitalTwins();
    for (final twin in allTwins) {
      if (vinClean.isNotEmpty && twin.vehicleId.toUpperCase().contains(vinClean)) {
        return VehicleIdentityResult(
          confidenceLevel: IdentityConfidenceLevel.userConfirmed,
          confidenceScore: 0.98,
          manufacturer: twin.manufacturer,
          model: twin.model,
          variant: twin.variant,
          year: twin.year,
          vin: vinClean,
          detectionSource: 'SAVED_DIGITAL_TWIN_VIN',
          hasExact3DModel: false,
          hasSavedDigitalTwin: true,
          existingDigitalTwinId: twin.twinId,
        );
      }
      if (btClean.isNotEmpty && twin.vehicleId.toUpperCase().contains(btClean)) {
        return VehicleIdentityResult(
          confidenceLevel: IdentityConfidenceLevel.userConfirmed,
          confidenceScore: 0.95,
          manufacturer: twin.manufacturer,
          model: twin.model,
          variant: twin.variant,
          year: twin.year,
          detectionSource: 'SAVED_DIGITAL_TWIN_BLE',
          hasExact3DModel: false,
          hasSavedDigitalTwin: true,
          existingDigitalTwinId: twin.twinId,
        );
      }
    }

    // 2. Check OEM Verified Vehicle Registry (Predefined authentic profiles)
    final matchedProfile = _registry.findProfileByBluetoothName(btClean);
    if (matchedProfile != null) {
      final has3d = matchedProfile.has3DModel;
      final isObd = matchedProfile.id == 'v_generic_obd2';
      return VehicleIdentityResult(
        confidenceLevel: has3d
            ? IdentityConfidenceLevel.exactMatch
            : (isObd ? IdentityConfidenceLevel.knownModel : IdentityConfidenceLevel.scanRequired),
        confidenceScore: has3d ? 0.99 : (isObd ? 0.85 : 0.75),
        manufacturer: matchedProfile.manufacturer,
        model: matchedProfile.model,
        variant: matchedProfile.variant,
        year: matchedProfile.year,
        detectionSource: 'OEM_VERIFIED_REGISTRY',
        matchedProfile: matchedProfile,
        hasExact3DModel: has3d,
        hasSavedDigitalTwin: false,
      );
    }

    // 3. Heuristic matching based on BT Name keywords
    if (btClean.contains('YAMAHA') || btClean.contains('CCU')) {
      return _buildHeuristicResult('Yamaha', 'Connected Vehicle', btClean, 0.70);
    }
    if (btClean.contains('DUCATI') || btClean.contains('DMS')) {
      return _buildHeuristicResult('Ducati', 'Multimedia Vehicle', btClean, 0.70);
    }
    if (btClean.contains('BMW') || btClean.contains('MOTORRAD')) {
      return _buildHeuristicResult('BMW Motorrad', 'Connected Vehicle', btClean, 0.70);
    }
    if (btClean.contains('SUZUKI') || btClean.contains('BURGMAN') || btClean.contains('RIDE-CONNECT')) {
      return _buildHeuristicResult('Suzuki', 'Ride Connect Scooter', btClean, 0.70);
    }
    if (btClean.contains('HONDA') || btClean.contains('ROADSYNC')) {
      return _buildHeuristicResult('Honda', 'RoadSync Two-Wheeler', btClean, 0.65);
    }
    if (btClean.contains('KTM') || btClean.contains('MY RIDE')) {
      return _buildHeuristicResult('KTM', 'My Ride Motorcycle', btClean, 0.65);
    }
    if (btClean.contains('OBD') || btClean.contains('V-LINK') || btClean.contains('ELM327')) {
      return const VehicleIdentityResult(
        confidenceLevel: IdentityConfidenceLevel.knownModel,
        confidenceScore: 0.80,
        manufacturer: 'Universal',
        model: 'OBD-II Telemetry Device',
        year: 2024,
        detectionSource: 'GENERIC_OBD2_ADAPTER',
        hasExact3DModel: false,
        hasSavedDigitalTwin: false,
      );
    }

    // 4. User specified overrides
    if (userSpecifiedMake != null && userSpecifiedMake.isNotEmpty && userSpecifiedModel != null) {
      return VehicleIdentityResult(
        confidenceLevel: IdentityConfidenceLevel.userConfirmed,
        confidenceScore: 0.90,
        manufacturer: userSpecifiedMake,
        model: userSpecifiedModel,
        year: userSpecifiedYear ?? 2024,
        detectionSource: 'MANUAL_USER_INPUT',
        hasExact3DModel: false,
        hasSavedDigitalTwin: false,
      );
    }

    // 5. Fallback: Unknown vehicle
    return VehicleIdentityResult(
      confidenceLevel: IdentityConfidenceLevel.unknown,
      confidenceScore: 0.10,
      manufacturer: 'Unknown',
      model: btClean.isNotEmpty ? btClean : 'Connected Device',
      year: DateTime.now().year,
      detectionSource: 'UNKNOWN_SIGNATURE',
      hasExact3DModel: false,
      hasSavedDigitalTwin: false,
    );
  }

  VehicleIdentityResult _buildHeuristicResult(String make, String model, String btName, double score) {
    return VehicleIdentityResult(
      confidenceLevel: IdentityConfidenceLevel.scanRequired,
      confidenceScore: score,
      manufacturer: make,
      model: model,
      year: 2024,
      detectionSource: 'BLE_HEURISTIC ($btName)',
      hasExact3DModel: false,
      hasSavedDigitalTwin: false,
    );
  }
}
