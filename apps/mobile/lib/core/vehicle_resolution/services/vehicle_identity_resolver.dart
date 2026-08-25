import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/vehicle_profile.dart';
import '../models/vehicle_identity.dart';
import '../models/vehicle_identity_resolution_result.dart';
import '../repositories/my_vehicles_repository.dart';
import 'vehicle_registry.dart';
import 'vehicle_model_registry.dart';
import '../../utils/constants.dart';

class VehicleIdentityResolver {
  static final VehicleIdentityResolver _instance = VehicleIdentityResolver._internal();
  factory VehicleIdentityResolver() => _instance;
  VehicleIdentityResolver._internal();

  final _repo = MyVehiclesRepository();
  final _registry = VehicleRegistry();
  final _modelRegistry = VehicleModelRegistry();
  String get _apiUrl => '${ApiConstants.baseUrl}/vehicles';

  /// Primary multi-platform BLE resolution method (Web Bluetooth & Native BLE).
  /// Resolves hardware signatures to exact VehicleProfile, IdentityConfidence, and 3D Asset Config.
  VehicleIdentityResolutionResult resolveBleDevice({
    required String deviceName,
    required String deviceId,
    List<String> gattServices = const [],
    String? manufacturerName,
    String? modelNumber,
    ConnectionTransportType transportType = ConnectionTransportType.ble,
  }) {
    final cleanName = deviceName.trim();
    final cleanUpper = cleanName.toUpperCase();
    final logBuffer = StringBuffer();

    logBuffer.writeln('[RideOS BLE Pipeline] [1/4 BLE Device Detected]: {name: "$cleanName", id: "$deviceId", servicesCount: ${gattServices.length}, transport: "${transportType.userFacingLabel}"}');

    // Step 1: Check exact model match in local catalog
    final exactProfile = _matchExactProfile(cleanUpper, modelNumber);

    if (exactProfile != null) {
      final isObd = exactProfile.id == 'v_generic_obd2' || _isObdGateway(cleanUpper, gattServices);
      final resolvedTransport = isObd ? ConnectionTransportType.obdGateway : transportType;

      final identity = VehicleIdentity(
        connectionType: resolvedTransport,
        deviceIdentifier: deviceId,
        manufacturer: exactProfile.manufacturer,
        make: exactProfile.manufacturer,
        model: exactProfile.model,
        variant: exactProfile.variant,
        modelYear: exactProfile.year,
        protocolAdapterId: exactProfile.protocolAdapter,
        confidence: IdentityConfidence.exactMatch, // VERIFIED
        fieldProvenance: {
          'model': IdentityFieldProvenance.advertisedName,
          'manufacturer': IdentityFieldProvenance.advertisedName,
          'gattServices': IdentityFieldProvenance.gattDiscovery,
        },
      );

      final model3DConfig = _modelRegistry.getModelConfigForProfile(exactProfile);

      logBuffer.writeln('[RideOS BLE Pipeline] [2/4 Identity Resolved]: {make: "${identity.make}", model: "${identity.model}", variant: "${identity.variant}", confidence: "${identity.confidence.statusCategory}"}');
      logBuffer.writeln('[RideOS BLE Pipeline] [3/4 Vehicle Profile Activated]: {id: "${exactProfile.id}", category: "${exactProfile.category}", verified: ${exactProfile.isVerified}}');
      logBuffer.writeln('[RideOS BLE Pipeline] [4/4 3D Asset Resolution]: {model3D: "${model3DConfig.modelAssetPath}", status: "${model3DConfig.modelStatus}", isVerified: ${model3DConfig.isVerified}}');

      final result = VehicleIdentityResolutionResult(
        identity: identity,
        profile: exactProfile,
        model3DConfig: model3DConfig,
        diagnosticLog: logBuffer.toString(),
      );

      debugPrint(result.diagnosticLog);
      return result;
    }

    // Step 2: Check brand/family match without exact model certainty (IDENTIFIED / MODEL_VALIDATION_PENDING)
    final familyResult = _matchBrandFamily(cleanUpper, deviceId, transportType, gattServices);
    if (familyResult != null) {
      logBuffer.writeln('[RideOS BLE Pipeline] [2/4 Identity Resolved]: {make: "${familyResult.identity.make}", model: "${familyResult.identity.model}", confidence: "${familyResult.identity.confidence.statusCategory}"}');
      logBuffer.writeln('[RideOS BLE Pipeline] [3/4 Vehicle Profile Activated]: {id: "${familyResult.profile?.id ?? 'pending'}", isPendingValidation: true}');
      logBuffer.writeln('[RideOS BLE Pipeline] [4/4 3D Asset Resolution]: {model3D: "", status: "MODEL_VALIDATION_PENDING", reason: "Exact vehicle model not confirmed by hardware"}');

      final finalResult = VehicleIdentityResolutionResult(
        identity: familyResult.identity,
        profile: familyResult.profile,
        model3DConfig: familyResult.model3DConfig,
        diagnosticLog: logBuffer.toString(),
      );

      debugPrint(finalResult.diagnosticLog);
      return finalResult;
    }

    // Step 3: Check Universal OBD-II Gateway signature
    if (_isObdGateway(cleanUpper, gattServices)) {
      final obdProfile = _registry.getProfileById('v_generic_obd2');
      final identity = VehicleIdentity(
        connectionType: ConnectionTransportType.obdGateway,
        deviceIdentifier: deviceId,
        manufacturer: 'Universal',
        make: 'Universal',
        model: 'OBD-II Telematics Gateway',
        variant: cleanName.isNotEmpty ? cleanName : 'Standard',
        modelYear: 2024,
        protocolAdapterId: 'generic_obd2',
        confidence: IdentityConfidence.verifiedMatch, // IDENTIFIED
        fieldProvenance: {
          'model': IdentityFieldProvenance.advertisedName,
        },
      );

      final model3DConfig = obdProfile != null ? _modelRegistry.getModelConfigForProfile(obdProfile) : null;

      logBuffer.writeln('[RideOS BLE Pipeline] [2/4 Identity Resolved]: {make: "Universal", model: "OBD-II Telematics Gateway", confidence: "IDENTIFIED"}');
      logBuffer.writeln('[RideOS BLE Pipeline] [3/4 Vehicle Profile Activated]: {id: "v_generic_obd2", transport: "OBD-II GATEWAY"}');
      logBuffer.writeln('[RideOS BLE Pipeline] [4/4 3D Asset Resolution]: {model3D: "", status: "NO_MODEL_FOR_GATEWAY"}');

      final result = VehicleIdentityResolutionResult(
        identity: identity,
        profile: obdProfile,
        model3DConfig: model3DConfig,
        diagnosticLog: logBuffer.toString(),
      );

      debugPrint(result.diagnosticLog);
      return result;
    }

    // Step 4: Unknown Hardware Signature (UNKNOWN / MODEL_VALIDATION_PENDING)
    // NEVER fallback to Yamaha YZF-R1M or another default motorcycle!
    final unknownIdentity = VehicleIdentity.unknown(
      connectionType: transportType,
      deviceIdentifier: deviceId,
      rawAdvertisementName: cleanName.isNotEmpty ? cleanName : 'Unknown BLE Device',
    );

    logBuffer.writeln('[RideOS BLE Pipeline] [2/4 Identity Resolved]: {make: "Unknown", model: "${unknownIdentity.model}", confidence: "UNKNOWN"}');
    logBuffer.writeln('[RideOS BLE Pipeline] [3/4 Vehicle Profile Activated]: {profile: null, manualSelectionRequired: true}');
    logBuffer.writeln('[RideOS BLE Pipeline] [4/4 3D Asset Resolution]: {model3D: "", status: "3D MODEL NOT AVAILABLE / MODEL VALIDATION PENDING / NO DUMMY GEOMETRY LOADED"}');

    final result = VehicleIdentityResolutionResult(
      identity: unknownIdentity,
      profile: null,
      model3DConfig: const Vehicle3DConfig(
        id: 'unknown',
        manufacturer: 'Unknown',
        model: 'Vehicle',
        model3d: '',
        thumbnail: '',
        verificationStatus: 'MODEL_VALIDATION_PENDING',
        modelAvailable: false,
      ),
      diagnosticLog: logBuffer.toString(),
    );

    debugPrint(result.diagnosticLog);
    return result;
  }

  /// Attempts to resolve a device to a VehicleProfile (Native BluetoothDevice wrapper).
  Future<VehicleProfile?> resolveDevice(BluetoothDevice device, List<BluetoothService> services) async {
    // 1. Check if device MAC is already associated with an owned vehicle
    final associatedId = await _repo.getAssociatedVehicleIdForMac(device.remoteId.str);
    if (associatedId != null) {
      final owned = await _repo.getOwnedVehicles();
      try {
        return owned.firstWhere((v) => v.id == associatedId);
      } catch (_) {}
    }

    // 2. Resolve via local authoritative BLE matching pipeline
    final res = resolveBleDevice(
      deviceName: device.advName,
      deviceId: device.remoteId.str,
      gattServices: services.map((s) => s.uuid.toString()).toList(),
    );

    if (res.profile != null) {
      return res.profile;
    }

    // 3. Try auto-detection via backend API if available
    try {
      final queryParams = {
        'deviceName': device.advName,
        'services': services.map((s) => s.uuid.toString()).join(','),
      };
      
      final uri = Uri.parse('$_apiUrl/resolve').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('id') || data.containsKey('_id')) {
          return VehicleProfile.fromJson(data);
        }
      }
    } catch (_) {}

    return null;
  }

  // ==========================================
  // Internal Matching Helpers
  // ==========================================

  VehicleProfile? _matchExactProfile(String cleanUpper, String? modelNumber) {
    final searchTarget = '${cleanUpper}_${(modelNumber ?? '').toUpperCase()}';

    // Honda
    if (searchTarget.contains('ACTIVA 6G') || searchTarget.contains('ACTIVA-6G') || searchTarget.contains('ACTIVA_6G') || searchTarget.contains('ACTIVA SMART') || searchTarget.contains('ACTIVA-SMART')) {
      return _registry.getProfileById('v_honda_activa_6g');
    }
    if (searchTarget.contains('ACTIVA 125') || searchTarget.contains('ACTIVA-125') || searchTarget.contains('ACTIVA_125')) {
      return _registry.getProfileById('v_honda_activa_125');
    }
    if (searchTarget.contains('DIO 125') || searchTarget.contains('DIO-125') || searchTarget.contains('HONDA DIO') || searchTarget.contains('HONDA-DIO')) {
      return _registry.getProfileById('v_honda_dio_125');
    }
    if (searchTarget.contains('SHINE') || searchTarget.contains('SHINE-125') || searchTarget.contains('HONDA SHINE')) {
      return _registry.getProfileById('v_honda_shine_125');
    }
    if (searchTarget.contains('SP125') || searchTarget.contains('SP 125') || searchTarget.contains('HONDA-SP125')) {
      return _registry.getProfileById('v_honda_sp125');
    }
    if (searchTarget.contains('UNICORN') || searchTarget.contains('HONDA-UNICORN')) {
      return _registry.getProfileById('v_honda_unicorn');
    }
    if (searchTarget.contains('HORNET') || searchTarget.contains('HORNET 2.0') || searchTarget.contains('HORNET-20')) {
      return _registry.getProfileById('v_honda_hornet_20');
    }
    if (searchTarget.contains('CB200X') || searchTarget.contains('CB-200X')) {
      return _registry.getProfileById('v_honda_cb200x');
    }
    if (searchTarget.contains('CB350RS') || searchTarget.contains('CB-350RS')) {
      return _registry.getProfileById('v_honda_cb350rs');
    }
    if (searchTarget.contains('HNESS') || searchTarget.contains("H'NESS") || searchTarget.contains('H-NESS') || searchTarget.contains('CB350-HNESS')) {
      return _registry.getProfileById('v_honda_hness_cb350');
    }
    if (searchTarget.contains('CB350') || searchTarget.contains('HONDA CB350')) {
      return _registry.getProfileById('v_honda_cb350');
    }

    // Yamaha
    if (searchTarget.contains('R1M') || searchTarget.contains('YZF-R1M') || searchTarget.contains('CCU-R1M') || searchTarget.contains('YAMAHA R1M')) {
      return _registry.getProfileById('v_yamaha_r1m');
    }
    if (searchTarget.contains('MT-15') || searchTarget.contains('MT15') || searchTarget.contains('YAMAHA-MT15')) {
      return _registry.getProfileById('v_yamaha_mt15_v2');
    }
    if (searchTarget.contains('R15') || searchTarget.contains('YZF-R15') || searchTarget.contains('R15-V4')) {
      return _registry.getProfileById('v_yamaha_r15_v4');
    }
    if (searchTarget.contains('R3') || searchTarget.contains('YZF-R3') || searchTarget.contains('YAMAHA-R3')) {
      return _registry.getProfileById('v_yamaha_r3');
    }
    if (searchTarget.contains('MT-09 SP') || searchTarget.contains('MT09-SP') || searchTarget.contains('MT-09SP')) {
      return _registry.getProfileById('v_yamaha_mt09_sp');
    }
    if (searchTarget.contains('MT-09') || searchTarget.contains('MT09')) {
      return _registry.getProfileById('v_yamaha_mt09');
    }
    if (searchTarget.contains('MT-07') || searchTarget.contains('MT07')) {
      return _registry.getProfileById('v_yamaha_mt07');
    }
    if (searchTarget.contains('MT-03') || searchTarget.contains('MT03')) {
      return _registry.getProfileById('v_yamaha_mt03');
    }
    if (searchTarget.contains('MT-10') || searchTarget.contains('MT10')) {
      return _registry.getProfileById('v_yamaha_mt10');
    }

    // Ducati
    if (searchTarget.contains('PANIGALE V4 S') || searchTarget.contains('PANIGALE-V4S') || searchTarget.contains('V4S') || searchTarget.contains('DMS-V4S') || searchTarget.contains('DUCATI-V4S')) {
      return _registry.getProfileById('v_ducati_v4s');
    }
    if (searchTarget.contains('PANIGALE V4') || searchTarget.contains('PANIGALE-V4') || searchTarget.contains('DUCATI-V4')) {
      return _registry.getProfileById('v_ducati_v4');
    }
    if (searchTarget.contains('PANIGALE V2') || searchTarget.contains('PANIGALE-V2') || searchTarget.contains('DUCATI-V2')) {
      return _registry.getProfileById('v_ducati_v2');
    }
    if (searchTarget.contains('STREETFIGHTER V4') || searchTarget.contains('STREETFIGHTER-V4')) {
      return _registry.getProfileById('v_ducati_streetfighter_v4');
    }
    if (searchTarget.contains('STREETFIGHTER V2') || searchTarget.contains('STREETFIGHTER-V2')) {
      return _registry.getProfileById('v_ducati_streetfighter_v2');
    }
    if (searchTarget.contains('MULTISTRADA V4') || searchTarget.contains('MULTISTRADA-V4')) {
      return _registry.getProfileById('v_ducati_multistrada_v4');
    }
    if (searchTarget.contains('MULTISTRADA V2') || searchTarget.contains('MULTISTRADA-V2')) {
      return _registry.getProfileById('v_ducati_multistrada_v2');
    }

    // BMW
    if (searchTarget.contains('M1000RR') || searchTarget.contains('M 1000 RR') || searchTarget.contains('BMW-M1000RR') || searchTarget.contains('M1000-RR')) {
      return _registry.getProfileById('v_bmw_m1000rr');
    }
    if (searchTarget.contains('S1000RR') || searchTarget.contains('S 1000 RR') || searchTarget.contains('BMW-S1000RR') || searchTarget.contains('S1000-RR')) {
      return _registry.getProfileById('v_bmw_s1000rr');
    }
    if (searchTarget.contains('G310R') || searchTarget.contains('G 310 R') || searchTarget.contains('BMW-G310R')) {
      return _registry.getProfileById('v_bmw_g310r');
    }
    if (searchTarget.contains('G310GS') || searchTarget.contains('G 310 GS') || searchTarget.contains('BMW-G310GS')) {
      return _registry.getProfileById('v_bmw_g310gs');
    }
    if (searchTarget.contains('F900GS') || searchTarget.contains('F 900 GS') || searchTarget.contains('BMW-F900GS')) {
      return _registry.getProfileById('v_bmw_f900gs');
    }
    if (searchTarget.contains('R1300GS') || searchTarget.contains('R 1300 GS') || searchTarget.contains('BMW-R1300GS')) {
      return _registry.getProfileById('v_bmw_r1300gs');
    }

    // Royal Enfield
    if (searchTarget.contains('CLASSIC 350') || searchTarget.contains('CLASSIC-350') || searchTarget.contains('RE-CLASSIC')) {
      return _registry.getProfileById('v_re_classic_350');
    }
    if (searchTarget.contains('HUNTER 350') || searchTarget.contains('HUNTER-350') || searchTarget.contains('RE-HUNTER')) {
      return _registry.getProfileById('v_re_hunter_350');
    }
    if (searchTarget.contains('METEOR 350') || searchTarget.contains('METEOR-350') || searchTarget.contains('RE-METEOR')) {
      return _registry.getProfileById('v_re_meteor_350');
    }
    if (searchTarget.contains('BULLET 350') || searchTarget.contains('BULLET-350') || searchTarget.contains('RE-BULLET')) {
      return _registry.getProfileById('v_re_bullet_350');
    }
    if (searchTarget.contains('HIMALAYAN') || searchTarget.contains('HIMALAYAN-450') || searchTarget.contains('RE-HIMALAYAN')) {
      return _registry.getProfileById('v_re_himalayan_450');
    }
    if (searchTarget.contains('GUERRILLA') || searchTarget.contains('GUERRILLA-450') || searchTarget.contains('RE-GUERRILLA')) {
      return _registry.getProfileById('v_re_guerrilla_450');
    }
    if (searchTarget.contains('INTERCEPTOR') || searchTarget.contains('INTERCEPTOR-650') || searchTarget.contains('RE-INTERCEPTOR')) {
      return _registry.getProfileById('v_re_interceptor_650');
    }
    if (searchTarget.contains('CONTINENTAL') || searchTarget.contains('CONTINENTAL-GT') || searchTarget.contains('GT650')) {
      return _registry.getProfileById('v_re_continental_gt650');
    }
    if (searchTarget.contains('SUPER METEOR') || searchTarget.contains('SUPER-METEOR')) {
      return _registry.getProfileById('v_re_super_meteor_650');
    }

    // Bajaj
    if (searchTarget.contains('NS200') || searchTarget.contains('PULSAR-NS200') || searchTarget.contains('NS 200')) {
      return _registry.getProfileById('v_bajaj_pulsar_ns200');
    }
    if (searchTarget.contains('N160') || searchTarget.contains('PULSAR-N160') || searchTarget.contains('N 160')) {
      return _registry.getProfileById('v_bajaj_pulsar_n160');
    }
    if (searchTarget.contains('N250') || searchTarget.contains('PULSAR-N250') || searchTarget.contains('N 250')) {
      return _registry.getProfileById('v_bajaj_pulsar_n250');
    }
    if (searchTarget.contains('DOMINAR 400') || searchTarget.contains('DOMINAR-400')) {
      return _registry.getProfileById('v_bajaj_dominar_400');
    }
    if (searchTarget.contains('DOMINAR 250') || searchTarget.contains('DOMINAR-250')) {
      return _registry.getProfileById('v_bajaj_dominar_250');
    }
    if (searchTarget.contains('CHETAK') || searchTarget.contains('CHETAK-EV') || searchTarget.contains('BAJAJ-CHETAK')) {
      return _registry.getProfileById('v_bajaj_chetak');
    }
    if (searchTarget.contains('PULSAR 150') || searchTarget.contains('PULSAR-150')) {
      return _registry.getProfileById('v_bajaj_pulsar_150');
    }
    if (searchTarget.contains('PULSAR 125') || searchTarget.contains('PULSAR-125')) {
      return _registry.getProfileById('v_bajaj_pulsar_125');
    }

    // TVS
    if (searchTarget.contains('NTORQ') || searchTarget.contains('NTORQ-125') || searchTarget.contains('TVS-NTORQ')) {
      return _registry.getProfileById('v_tvs_ntorq_125');
    }
    if (searchTarget.contains('JUPITER') || searchTarget.contains('JUPITER-110') || searchTarget.contains('TVS-JUPITER')) {
      return _registry.getProfileById('v_tvs_jupiter_110');
    }
    if (searchTarget.contains('RAIDER') || searchTarget.contains('RAIDER-125') || searchTarget.contains('TVS-RAIDER')) {
      return _registry.getProfileById('v_tvs_raider_125');
    }
    if (searchTarget.contains('APACHE RR 310') || searchTarget.contains('APACHE-RR310') || searchTarget.contains('RR310')) {
      return _registry.getProfileById('v_tvs_apache_rr310');
    }
    if (searchTarget.contains('APACHE RTR 200') || searchTarget.contains('APACHE-RTR200') || searchTarget.contains('RTR200')) {
      return _registry.getProfileById('v_tvs_apache_rtr200');
    }
    if (searchTarget.contains('APACHE RTR 160') || searchTarget.contains('APACHE-RTR160') || searchTarget.contains('RTR160')) {
      return _registry.getProfileById('v_tvs_apache_rtr160');
    }
    if (searchTarget.contains('RONIN') || searchTarget.contains('RONIN-225') || searchTarget.contains('TVS-RONIN')) {
      return _registry.getProfileById('v_tvs_ronin_225');
    }
    if (searchTarget.contains('IQUBE') || searchTarget.contains('IQUBE-EV') || searchTarget.contains('TVS-IQUBE')) {
      return _registry.getProfileById('v_tvs_iqube');
    }

    // Hero
    if (searchTarget.contains('SPLENDOR') || searchTarget.contains('SPLENDOR-PLUS') || searchTarget.contains('HERO-SPLENDOR')) {
      return _registry.getProfileById('v_hero_splendor_plus');
    }
    if (searchTarget.contains('XTREME 125R') || searchTarget.contains('XTREME-125R')) {
      return _registry.getProfileById('v_hero_xtreme_125r');
    }
    if (searchTarget.contains('XTREME 160R') || searchTarget.contains('XTREME-160R')) {
      return _registry.getProfileById('v_hero_xtreme_160r');
    }
    if (searchTarget.contains('KARIZMA') || searchTarget.contains('KARIZMA-XMR')) {
      return _registry.getProfileById('v_hero_karizma_xmr');
    }
    if (searchTarget.contains('MAVRICK') || searchTarget.contains('MAVRICK-440')) {
      return _registry.getProfileById('v_hero_mavrick_440');
    }
    if (searchTarget.contains('VIDA') || searchTarget.contains('VIDA-V2') || searchTarget.contains('VIDA-EV')) {
      return _registry.getProfileById('v_hero_vida_v2');
    }
    if (searchTarget.contains('HF DELUXE') || searchTarget.contains('HF-DELUXE')) {
      return _registry.getProfileById('v_hero_hf_deluxe');
    }
    if (searchTarget.contains('GLAMOUR') || searchTarget.contains('GLAMOUR-125')) {
      return _registry.getProfileById('v_hero_glamour_125');
    }

    // Suzuki
    if (searchTarget.contains('BURGMAN') || searchTarget.contains('BURGMAN-125') || searchTarget.contains('SUZUKI-BURGMAN')) {
      return _registry.getProfileById('v_suzuki_burgman125') ?? _registry.getProfileById('v_suzuki_burgman_125');
    }
    if (searchTarget.contains('ACCESS') || searchTarget.contains('ACCESS-125') || searchTarget.contains('SUZUKI-ACCESS')) {
      return _registry.getProfileById('v_suzuki_access_125');
    }
    if (searchTarget.contains('AVENIS') || searchTarget.contains('AVENIS-125') || searchTarget.contains('SUZUKI-AVENIS')) {
      return _registry.getProfileById('v_suzuki_avenis_125');
    }
    if (searchTarget.contains('GIXXER SF 250') || searchTarget.contains('GIXXER-SF250') || searchTarget.contains('GIXXER-SF')) {
      return _registry.getProfileById('v_suzuki_gixxer_sf250');
    }
    if (searchTarget.contains('GIXXER') || searchTarget.contains('GIXXER-150')) {
      return _registry.getProfileById('v_suzuki_gixxer_150');
    }
    if (searchTarget.contains('VSTROM') || searchTarget.contains('V-STROM') || searchTarget.contains('VSTROM-SX')) {
      return _registry.getProfileById('v_suzuki_vstrom_sx250');
    }

    // KTM
    if (searchTarget.contains('DUKE 390') || searchTarget.contains('DUKE-390') || searchTarget.contains('KTM-390')) {
      return _registry.getProfileById('v_ktm_duke_390');
    }
    if (searchTarget.contains('DUKE 250') || searchTarget.contains('DUKE-250') || searchTarget.contains('KTM-250')) {
      return _registry.getProfileById('v_ktm_duke_250');
    }
    if (searchTarget.contains('DUKE 200') || searchTarget.contains('DUKE-200') || searchTarget.contains('KTM-200')) {
      return _registry.getProfileById('v_ktm_duke_200');
    }
    if (searchTarget.contains('DUKE 125') || searchTarget.contains('DUKE-125') || searchTarget.contains('KTM-125')) {
      return _registry.getProfileById('v_ktm_duke_125');
    }
    if (searchTarget.contains('RC 390') || searchTarget.contains('RC-390') || searchTarget.contains('KTM-RC390')) {
      return _registry.getProfileById('v_ktm_rc_390');
    }
    if (searchTarget.contains('RC 200') || searchTarget.contains('RC-200') || searchTarget.contains('KTM-RC200')) {
      return _registry.getProfileById('v_ktm_rc_200');
    }
    if (searchTarget.contains('ADV 390') || searchTarget.contains('ADVENTURE 390') || searchTarget.contains('KTM-ADV390')) {
      return _registry.getProfileById('v_ktm_adv_390');
    }
    if (searchTarget.contains('ADV 250') || searchTarget.contains('ADVENTURE 250') || searchTarget.contains('KTM-ADV250')) {
      return _registry.getProfileById('v_ktm_adv_250');
    }

    // Triumph
    if (searchTarget.contains('SPEED 400') || searchTarget.contains('SPEED-400') || searchTarget.contains('TRIUMPH-SPEED400')) {
      return _registry.getProfileById('v_triumph_speed_400');
    }
    if (searchTarget.contains('SCRAMBLER 400') || searchTarget.contains('SCRAMBLER-400X') || searchTarget.contains('400X')) {
      return _registry.getProfileById('v_triumph_scrambler_400x');
    }
    if (searchTarget.contains('DAYTONA 660') || searchTarget.contains('DAYTONA-660')) {
      return _registry.getProfileById('v_triumph_daytona_660');
    }
    if (searchTarget.contains('STREET TRIPLE') || searchTarget.contains('STREET-TRIPLE') || searchTarget.contains('ST765')) {
      return _registry.getProfileById('v_triumph_street_triple_765');
    }
    if (searchTarget.contains('TIGER SPORT') || searchTarget.contains('TIGER-660')) {
      return _registry.getProfileById('v_triumph_tiger_sport_660');
    }

    // Aprilia
    if (searchTarget.contains('RS 457') || searchTarget.contains('RS457') || searchTarget.contains('APRILIA-RS457')) {
      return _registry.getProfileById('v_aprilia_rs457');
    }
    if (searchTarget.contains('TUONO 457') || searchTarget.contains('TUONO-457')) {
      return _registry.getProfileById('v_aprilia_tuono_457');
    }
    if (searchTarget.contains('RSV4') || searchTarget.contains('RSV4-FACTORY') || searchTarget.contains('APRILIA-RSV4')) {
      return _registry.getProfileById('v_aprilia_rsv4');
    }

    // Harley-Davidson
    if (searchTarget.contains('X440') || searchTarget.contains('HD-X440') || searchTarget.contains('HARLEY-X440')) {
      return _registry.getProfileById('v_hd_x440');
    }
    if (searchTarget.contains('NIGHTSTER') || searchTarget.contains('HD-NIGHTSTER')) {
      return _registry.getProfileById('v_hd_nightster_975');
    }
    if (searchTarget.contains('SPORTSTER S') || searchTarget.contains('SPORTSTER-S') || searchTarget.contains('HD-SPORTSTER')) {
      return _registry.getProfileById('v_hd_sportster_s');
    }
    if (searchTarget.contains('FAT BOB') || searchTarget.contains('FAT-BOB') || searchTarget.contains('HD-FATBOB')) {
      return _registry.getProfileById('v_hd_fat_bob_114');
    }

    // Indian Motorcycle
    if (searchTarget.contains('SCOUT BOBBER') || searchTarget.contains('SCOUT-BOBBER') || searchTarget.contains('INDIAN-SCOUT')) {
      return _registry.getProfileById('v_indian_scout_bobber');
    }
    if (searchTarget.contains('CHIEF DARK HORSE') || searchTarget.contains('CHIEF-DARKHORSE')) {
      return _registry.getProfileById('v_indian_chief_dark_horse');
    }
    if (searchTarget.contains('CHALLENGER') || searchTarget.contains('INDIAN-CHALLENGER')) {
      return _registry.getProfileById('v_indian_challenger');
    }

    // Jawa & Yezdi
    if (searchTarget.contains('JAWA 42') || searchTarget.contains('JAWA-42')) {
      return _registry.getProfileById('v_jawa_42');
    }
    if (searchTarget.contains('JAWA 350') || searchTarget.contains('JAWA-350')) {
      return _registry.getProfileById('v_jawa_350');
    }
    if (searchTarget.contains('PERAK') || searchTarget.contains('JAWA-PERAK')) {
      return _registry.getProfileById('v_jawa_perak');
    }
    if (searchTarget.contains('YEZDI ROADSTER') || searchTarget.contains('YEZDI-ROADSTER')) {
      return _registry.getProfileById('v_yezdi_roadster');
    }
    if (searchTarget.contains('YEZDI SCRAMBLER') || searchTarget.contains('YEZDI-SCRAMBLER')) {
      return _registry.getProfileById('v_yezdi_scrambler');
    }
    if (searchTarget.contains('YEZDI ADVENTURE') || searchTarget.contains('YEZDI-ADV')) {
      return _registry.getProfileById('v_yezdi_adventure');
    }

    // Kawasaki
    if (searchTarget.contains('NINJA H2') || searchTarget.contains('NINJA-H2') || searchTarget.contains('KAWASAKI-H2')) {
      return _registry.getProfileById('v_kawasaki_ninja_h2');
    }
    if (searchTarget.contains('ZX-10R') || searchTarget.contains('ZX10R') || searchTarget.contains('NINJA ZX-10R')) {
      return _registry.getProfileById('v_kawasaki_ninja_zx10r');
    }
    if (searchTarget.contains('ZX-6R') || searchTarget.contains('ZX6R') || searchTarget.contains('NINJA ZX-6R')) {
      return _registry.getProfileById('v_kawasaki_ninja_zx6r');
    }
    if (searchTarget.contains('ZX-4R') || searchTarget.contains('ZX4R') || searchTarget.contains('NINJA ZX-4R')) {
      return _registry.getProfileById('v_kawasaki_ninja_zx4r');
    }
    if (searchTarget.contains('NINJA 650') || searchTarget.contains('NINJA-650')) {
      return _registry.getProfileById('v_kawasaki_ninja_650');
    }
    if (searchTarget.contains('NINJA 500') || searchTarget.contains('NINJA-500')) {
      return _registry.getProfileById('v_kawasaki_ninja_500');
    }
    if (searchTarget.contains('NINJA 400') || searchTarget.contains('NINJA-400')) {
      return _registry.getProfileById('v_kawasaki_ninja_400');
    }
    if (searchTarget.contains('NINJA 300') || searchTarget.contains('NINJA-300') || searchTarget.contains('KAWASAKI-NINJA300')) {
      return _registry.getProfileById('v_kawasaki_ninja_300');
    }
    if (searchTarget.contains('Z900') || searchTarget.contains('KAWASAKI-Z900')) {
      return _registry.getProfileById('v_kawasaki_z900');
    }
    if (searchTarget.contains('VERSYS 650') || searchTarget.contains('VERSYS-650')) {
      return _registry.getProfileById('v_kawasaki_versys_650');
    }

    // Ola Electric
    if (searchTarget.contains('S1 PRO') || searchTarget.contains('S1PRO') || searchTarget.contains('OLA-S1PRO')) {
      return _registry.getProfileById('v_ola_s1_pro_gen2');
    }
    if (searchTarget.contains('S1 AIR') || searchTarget.contains('S1AIR') || searchTarget.contains('OLA-S1AIR')) {
      return _registry.getProfileById('v_ola_s1_air');
    }
    if (searchTarget.contains('S1 X') || searchTarget.contains('S1X') || searchTarget.contains('OLA-S1X')) {
      return _registry.getProfileById('v_ola_s1_x');
    }

    // Ather Energy
    if (searchTarget.contains('ATHER 450X') || searchTarget.contains('450X') || searchTarget.contains('ATHER-450X')) {
      return _registry.getProfileById('v_ather_450x_gen3');
    }
    if (searchTarget.contains('ATHER 450S') || searchTarget.contains('450S') || searchTarget.contains('ATHER-450S')) {
      return _registry.getProfileById('v_ather_450s');
    }
    if (searchTarget.contains('RIZTA') || searchTarget.contains('ATHER-RIZTA')) {
      return _registry.getProfileById('v_ather_rizta');
    }

    // Vespa & Piaggio
    if (searchTarget.contains('PRIMAVERA') || searchTarget.contains('VESPA-PRIMAVERA')) {
      return _registry.getProfileById('v_vespa_primavera_150');
    }
    if (searchTarget.contains('GTS 300') || searchTarget.contains('VESPA-GTS300') || searchTarget.contains('GTS300')) {
      return _registry.getProfileById('v_vespa_gts_300');
    }
    if (searchTarget.contains('SXL 125') || searchTarget.contains('VESPA-SXL')) {
      return _registry.getProfileById('v_vespa_sxl_125');
    }
    if (searchTarget.contains('BEVERLY') || searchTarget.contains('PIAGGIO-BEVERLY')) {
      return _registry.getProfileById('v_piaggio_beverly_300');
    }
    if (searchTarget.contains('APE') || searchTarget.contains('PIAGGIO-APE')) {
      return _registry.getProfileById('v_piaggio_ape_ecity');
    }

    // Search by generic registry bluetooth resolver as final exact pass
    return _registry.findProfileByBluetoothName(cleanUpper);
  }

  VehicleIdentityResolutionResult? _matchBrandFamily(
    String cleanUpper,
    String deviceId,
    ConnectionTransportType transportType,
    List<String> gattServices,
  ) {
    String? brand;
    String? protocol;

    if (cleanUpper.contains('HONDA') || cleanUpper.contains('ROADSYNC')) {
      brand = 'Honda';
      protocol = 'honda_roadsync';
    } else if (cleanUpper.contains('YAMAHA') || cleanUpper.contains('Y-CONNECT') || cleanUpper.contains('YCONNECT')) {
      brand = 'Yamaha';
      protocol = 'yamaha_y_connect';
    } else if (cleanUpper.contains('DUCATI') || cleanUpper.contains('DMS')) {
      brand = 'Ducati';
      protocol = 'ducati_multimedia';
    } else if (cleanUpper.contains('BMW') || cleanUpper.contains('MOTORRAD')) {
      brand = 'BMW';
      protocol = 'bmw_motorrad_connected';
    } else if (cleanUpper.contains('ROYAL ENFIELD') || cleanUpper.contains('TRIPPER') || cleanUpper.contains('RE-')) {
      brand = 'Royal Enfield';
      protocol = 'royal_enfield_tripper';
    } else if (cleanUpper.contains('BAJAJ') || cleanUpper.contains('RIDE CONNECT')) {
      brand = 'Bajaj';
      protocol = 'bajaj_ride_connect';
    } else if (cleanUpper.contains('TVS') || cleanUpper.contains('SMARTXONNECT')) {
      brand = 'TVS';
      protocol = 'tvs_smartxonnect';
    } else if (cleanUpper.contains('HERO') || cleanUpper.contains('XCONNECT')) {
      brand = 'Hero';
      protocol = 'hero_connect';
    } else if (cleanUpper.contains('SUZUKI') || cleanUpper.contains('RIDE-CONNECT')) {
      brand = 'Suzuki';
      protocol = 'suzuki_ride_connect';
    } else if (cleanUpper.contains('KTM') || cleanUpper.contains('MY RIDE')) {
      brand = 'KTM';
      protocol = 'ktm_my_ride';
    } else if (cleanUpper.contains('TRIUMPH') || cleanUpper.contains('MY TRIUMPH')) {
      brand = 'Triumph';
      protocol = 'triumph_connectivity';
    } else if (cleanUpper.contains('APRILIA') || cleanUpper.contains('MIA')) {
      brand = 'Aprilia';
      protocol = 'aprilia_mia';
    } else if (cleanUpper.contains('HARLEY') || cleanUpper.contains('H-D CONNECT')) {
      brand = 'Harley-Davidson';
      protocol = 'harley_hd_connect';
    } else if (cleanUpper.contains('KAWASAKI') || cleanUpper.contains('RIDEOLOGY')) {
      brand = 'Kawasaki';
      protocol = 'kawasaki_rideology';
    } else if (cleanUpper.contains('VESPA') || cleanUpper.contains('PIAGGIO')) {
      brand = 'Piaggio';
      protocol = 'piaggio_mia';
    } else if (cleanUpper.contains('OLA') || cleanUpper.contains('MOVEOS')) {
      brand = 'Ola Electric';
      protocol = 'generic_ble';
    } else if (cleanUpper.contains('ATHER') || cleanUpper.contains('WARP')) {
      brand = 'Ather';
      protocol = 'generic_ble';
    } else if (cleanUpper.contains('INDIAN') || cleanUpper.contains('RIDE COMMAND')) {
      brand = 'Indian Motorcycle';
      protocol = 'obd2_standard';
    } else if (cleanUpper.contains('JAWA')) {
      brand = 'Jawa';
      protocol = 'obd2_standard';
    } else if (cleanUpper.contains('YEZDI')) {
      brand = 'Yezdi';
      protocol = 'obd2_standard';
    }

    if (brand != null) {
      final identity = VehicleIdentity(
        connectionType: transportType,
        deviceIdentifier: deviceId,
        manufacturer: brand,
        make: brand,
        model: '$brand Two-Wheeler (Model Validation Pending)',
        variant: 'Connected CCU',
        modelYear: 2024,
        protocolAdapterId: protocol ?? 'generic_ble',
        confidence: IdentityConfidence.verifiedMatch, // IDENTIFIED, but NOT exact match
        fieldProvenance: {
          'manufacturer': IdentityFieldProvenance.advertisedName,
        },
      );

      final familyProfile = VehicleProfile(
        id: 'family_${brand.toLowerCase()}_$deviceId',
        manufacturer: brand,
        model: '$brand Two-Wheeler',
        variant: 'Validation Pending',
        year: 2024,
        category: 'Motorcycle',
        protocolAdapter: protocol ?? 'generic_ble',
        model3DUrl: '',
        thumbnailUrl: 'assets/garage/generic_bike.png',
        isVerified: false,
      );

      return VehicleIdentityResolutionResult(
        identity: identity,
        profile: familyProfile,
        model3DConfig: Vehicle3DConfig(
          id: 'validation_pending',
          manufacturer: brand,
          model: '$brand Two-Wheeler',
          model3d: '',
          thumbnail: 'assets/garage/generic_bike.png',
          verificationStatus: 'MODEL_VALIDATION_PENDING',
          modelAvailable: false,
        ),
        diagnosticLog: 'Brand family matched ($brand). Exact model validation pending.',
      );
    }

    return null;
  }

  bool _isObdGateway(String cleanUpper, List<String> gattServices) {
    if (cleanUpper.contains('OBD') ||
        cleanUpper.contains('ELM327') ||
        cleanUpper.contains('VGATE') ||
        cleanUpper.contains('VLINKER') ||
        cleanUpper.contains('OBDLINK') ||
        cleanUpper.contains('IOS-VLINK') ||
        cleanUpper.contains('VIEOCAR')) {
      return true;
    }

    // Standard OBD-II BLE UUIDs
    final obdServices = {
      '0000fff0-0000-1000-8000-00805f9b34fb',
      '0000ffe0-0000-1000-8000-00805f9b34fb',
      'e7810a71-73ae-499d-8c15-faa9aef0c3f2',
      '49535343-fe7d-4ae5-8fa9-9fafd205e455',
    };

    return gattServices.any((s) => obdServices.contains(s.toLowerCase()));
  }
}
