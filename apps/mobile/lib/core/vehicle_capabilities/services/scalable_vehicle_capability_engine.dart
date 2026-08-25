import '../models/universal_vehicle_capability_models.dart';
import '../interfaces/vehicle_connection_provider.dart';

class ScalableVehicleCapabilityEngine implements VehicleCapabilityProvider {
  static final ScalableVehicleCapabilityEngine _instance = ScalableVehicleCapabilityEngine._internal();
  factory ScalableVehicleCapabilityEngine() => _instance;

  final List<VehicleManufacturer> _catalog = [];
  List<VehicleManufacturer> get catalog => List.unmodifiable(_catalog);

  ScalableVehicleCapabilityEngine._internal() {
    _populateDefaultOpenCatalog();
  }

  /// Extensible runtime registration of future vehicle profiles
  void registerNewVehicleProfile(VehicleManufacturer manufacturer) {
    final existingIdx = _catalog.indexWhere((m) => m.manufacturerId == manufacturer.manufacturerId);
    if (existingIdx != -1) {
      _catalog[existingIdx] = manufacturer;
    } else {
      _catalog.add(manufacturer);
    }
  }

  void _populateDefaultOpenCatalog() {
    // 1. Yamaha Supersport & Hyper Naked (2018+)
    _catalog.add(const VehicleManufacturer(
      manufacturerId: 'yamaha',
      name: 'Yamaha Motor Co.',
      country: 'Japan',
      families: [
        VehicleFamily(
          familyId: 'yamaha_yzf',
          familyName: 'YZF Supersport Series',
          models: [
            VehicleModel(
              modelId: 'yamaha_r15',
              modelName: 'YZF-R15',
              startYear: 2018,
              variants: [
                ModelVariant(
                  variantId: 'yamaha_r15_base',
                  variantName: 'R15 Standard (Analog/LCD)',
                  trimLevel: VariantTrimLevel.base,
                  connectivity: ConnectivityCapabilities(hasBle: false),
                  protocol: ProtocolCapabilities(
                    protocolName: 'None (Requires OBD Adapter)',
                    gattServiceUuid: '',
                    readCharacteristicUuid: '',
                  ),
                  telemetry: TelemetryCapabilities(supportsSpeed: true, supportsRpm: true),
                  display: DisplayCapabilities(displayType: 'Standard Segment LCD'),
                  compatibility: CompatibilityLevel.hardwareRequired,
                ),
                ModelVariant(
                  variantId: 'yamaha_r15_m',
                  variantName: 'R15M (Y-Connect CCU)',
                  trimLevel: VariantTrimLevel.topPremium,
                  connectivity: ConnectivityCapabilities(hasBle: true),
                  protocol: ProtocolCapabilities(
                    protocolName: 'Yamaha Y-Connect CCU',
                    gattServiceUuid: '0000fee0-0000-1000-8000-00805f9b34fb',
                    readCharacteristicUuid: '0000fee1-0000-1000-8000-00805f9b34fb',
                    writeCharacteristicUuid: '0000fee2-0000-1000-8000-00805f9b34fb',
                    supportsTurnByTurnMirror: true,
                    supportsCallerIdAlerts: true,
                    supportsDtcDiagnostics: true,
                  ),
                  telemetry: TelemetryCapabilities(
                    supportsSpeed: true,
                    supportsRpm: true,
                    supportsFuelLevel: true,
                    supportsBatteryVoltage: true,
                    supportsCoolantTemp: true,
                    supportsAbsStatus: true,
                    supportsTractionControl: true,
                  ),
                  display: DisplayCapabilities(
                    displayType: 'Full-Color TFT Dash',
                    supportsNavigationArrows: true,
                    supportsStreetNameText: true,
                    supportsIncomingCallNotification: true,
                  ),
                  compatibility: CompatibilityLevel.fullySupported,
                ),
              ],
            ),
          ],
        ),
      ],
    ));

    // 2. Royal Enfield Himalayan & Scram (2020+)
    _catalog.add(const VehicleManufacturer(
      manufacturerId: 'royal_enfield',
      name: 'Royal Enfield',
      country: 'India / UK',
      families: [
        VehicleFamily(
          familyId: 're_himalayan',
          familyName: 'Himalayan Adventure',
          models: [
            VehicleModel(
              modelId: 're_himalayan_450',
              modelName: 'Himalayan 450 (Sherpa)',
              startYear: 2023,
              variants: [
                ModelVariant(
                  variantId: 're_himalayan_450_tripper',
                  variantName: 'Tripper Dash TFT',
                  trimLevel: VariantTrimLevel.topPremium,
                  connectivity: ConnectivityCapabilities(hasBle: true, hasWifi: true),
                  protocol: ProtocolCapabilities(
                    protocolName: 'Royal Enfield Sherpa / Tripper',
                    gattServiceUuid: '0000fe50-0000-1000-8000-00805f9b34fb',
                    readCharacteristicUuid: '0000fe51-0000-1000-8000-00805f9b34fb',
                    writeCharacteristicUuid: '0000fe52-0000-1000-8000-00805f9b34fb',
                    supportsTurnByTurnMirror: true,
                    supportsCallerIdAlerts: true,
                  ),
                  telemetry: TelemetryCapabilities(
                    supportsSpeed: true,
                    supportsRpm: true,
                    supportsFuelLevel: true,
                    supportsGearIndicator: true,
                    supportsAbsStatus: true,
                  ),
                  display: DisplayCapabilities(
                    displayType: 'Round 4-inch TFT Display',
                    supportsNavigationArrows: true,
                    supportsStreetNameText: true,
                  ),
                  compatibility: CompatibilityLevel.fullySupported,
                ),
              ],
            ),
          ],
        ),
      ],
    ));

    // 3. Ather Energy Connected EV Scooters (2018+)
    _catalog.add(const VehicleManufacturer(
      manufacturerId: 'ather_energy',
      name: 'Ather Energy',
      country: 'India',
      families: [
        VehicleFamily(
          familyId: 'ather_450_series',
          familyName: '450 Smart EV Series',
          models: [
            VehicleModel(
              modelId: 'ather_450x',
              modelName: 'Ather 450X Gen 3',
              startYear: 2022,
              variants: [
                ModelVariant(
                  variantId: 'ather_450x_pro',
                  variantName: '450X Pro Pack (AtherStack 5.0)',
                  trimLevel: VariantTrimLevel.topPremium,
                  connectivity: ConnectivityCapabilities(hasBle: true, hasWifi: true, hasManufacturerApi: true),
                  protocol: ProtocolCapabilities(
                    protocolName: 'AtherStack Telematics API & BLE Gateway',
                    gattServiceUuid: '000018f0-0000-1000-8000-00805f9b34fb',
                    readCharacteristicUuid: '000018f1-0000-1000-8000-00805f9b34fb',
                    supportsTurnByTurnMirror: true,
                    supportsDtcDiagnostics: true,
                  ),
                  telemetry: TelemetryCapabilities(
                    supportsSpeed: true,
                    supportsRpm: false,
                    supportsFuelLevel: false,
                    supportsBatterySoc: true,
                    supportsBatteryVoltage: true,
                    supportsMotorTemp: true,
                    supportsTpms: true,
                    supportsChargingStatus: true,
                  ),
                  display: DisplayCapabilities(
                    displayType: '7-inch Android Touchscreen TFT',
                    supportsNavigationArrows: true,
                    supportsStreetNameText: true,
                  ),
                  compatibility: CompatibilityLevel.supportedWithManufacturerApi,
                ),
              ],
            ),
          ],
        ),
      ],
    ));
  }

  @override
  Future<ModelVariant> resolveCapabilities({
    required String deviceName,
    required List<String> advertisedServiceUuids,
    required String? macAddress,
  }) async {
    final lowerName = deviceName.toLowerCase();

    if (lowerName.contains('yamaha') || advertisedServiceUuids.any((u) => u.toLowerCase().contains('fee0'))) {
      return _catalog[0].families[0].models[0].variants[1]; // R15M CCU
    }

    if (lowerName.contains('tripper') || lowerName.contains('royal enfield') || advertisedServiceUuids.any((u) => u.toLowerCase().contains('fe50'))) {
      return _catalog[1].families[0].models[0].variants[0]; // RE Tripper
    }

    if (lowerName.contains('ather') || advertisedServiceUuids.any((u) => u.toLowerCase().contains('18f0'))) {
      return _catalog[2].families[0].models[0].variants[0]; // Ather 450X Pro
    }

    // Default Universal Diagnostic Gateway profile
    return const ModelVariant(
      variantId: 'universal_generic_obd',
      variantName: 'Generic SAE J1979 / OBD-II Adapter',
      trimLevel: VariantTrimLevel.base,
      connectivity: ConnectivityCapabilities(hasBle: true, hasObdGateway: true),
      protocol: ProtocolCapabilities(
        protocolName: 'Standard OBD-II ISO 15765-4',
        gattServiceUuid: '0000fff0-0000-1000-8000-00805f9b34fb',
        readCharacteristicUuid: '0000fff1-0000-1000-8000-00805f9b34fb',
        supportsDtcDiagnostics: true,
      ),
      telemetry: TelemetryCapabilities(
        supportsSpeed: true,
        supportsRpm: true,
        supportsBatteryVoltage: true,
        supportsCoolantTemp: true,
      ),
      display: DisplayCapabilities(
        displayType: 'External Phone HUD',
        requiresDisplayGateway: true,
      ),
      compatibility: CompatibilityLevel.supportedWithGateway,
    );
  }
}
