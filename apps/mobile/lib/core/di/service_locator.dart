import 'package:get_it/get_it.dart';
import '../network/api_client.dart';
import '../offline/offline_sync_engine.dart';
import '../security/security_service.dart';
import '../storage/token_storage.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/navigation/core/services/gps_tracking_service.dart';
import '../../features/navigation/core/services/voice_guidance_service.dart';
import '../../features/navigation/data/datasources/navigation_local_datasource.dart';
import '../../features/navigation/data/datasources/navigation_remote_datasource.dart';
import '../../features/navigation/data/repositories/navigation_repository_impl.dart';
import '../../features/navigation/domain/repositories/navigation_repository.dart';
import '../../features/ai_assistant/data/datasources/ai_assistant_remote_datasource.dart';
import '../../features/ai_assistant/domain/services/ai_intent_resolver.dart';
import '../../features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import '../../features/squad_ride/data/datasources/squad_remote_datasource.dart';
import '../../features/obd_tpms/core/ble/obd_ble_service.dart';
import '../../features/obd_tpms/data/datasources/obd_remote_datasource.dart';
import '../../features/telematics/core/services/digital_twin_service.dart';
import '../../features/telematics/core/services/smart_city_service.dart';
import '../../features/telematics/core/services/v2v_mesh_service.dart';
import '../notifications/services/push_notification_service.dart';
import '../contracts/vehicle_data_gateway.dart';
import '../contracts/navigation_gateway.dart';
import '../contracts/ai_provider_gateway.dart';
import '../contracts/text_to_speech_gateway.dart';
import '../contracts/voice_gateway.dart';
import '../../features/voice_assistant/data/adapters/platform_text_to_speech_adapter.dart';
import '../../features/voice_assistant/data/adapters/platform_voice_input_adapter.dart';
import '../vehicle_resolution/repositories/my_vehicles_repository.dart';
import '../../features/vehicle/presentation/bloc/vehicle_bloc.dart';
import '../../features/navigation/presentation/bloc/navigation_bloc.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  final GetIt _getIt = GetIt.instance;

  T call<T extends Object>() => _getIt<T>();
  T get<T extends Object>() => _getIt<T>();

  bool get isInitialized => _getIt.isRegistered<SecurityService>();

  SecurityService get securityService => _getIt<SecurityService>();
  OfflineSyncEngine get offlineSyncEngine => _getIt<OfflineSyncEngine>();
  DigitalTwinService get digitalTwinService => _getIt<DigitalTwinService>();
  V2vMeshService get v2vMeshService => _getIt<V2vMeshService>();
  SmartCityService get smartCityService => _getIt<SmartCityService>();
  VehicleDataGateway get vehicleDataGateway => _getIt<VehicleDataGateway>();
  NavigationGateway get navigationGateway => _getIt<NavigationGateway>();
  AIProviderGateway get aiProviderGateway => _getIt<AIProviderGateway>();
  VoiceGateway get voiceGateway => _getIt<VoiceGateway>();
  TextToSpeechGateway get textToSpeechGateway => _getIt<TextToSpeechGateway>();
  MyVehiclesRepository get myVehiclesRepository => _getIt<MyVehiclesRepository>();
  VehicleBloc get vehicleBloc => _getIt<VehicleBloc>();
  NavigationBloc get navigationBloc => _getIt<NavigationBloc>();
  AiAssistantBloc get aiAssistantBloc => _getIt<AiAssistantBloc>();

  void setupLocator() {
    if (_getIt.isRegistered<SecurityService>()) return;

    // Core Singletons
    _getIt.registerLazySingleton<TokenStorage>(() => TokenStorage());
    _getIt.registerLazySingleton<ApiClient>(() => ApiClient(tokenStorage: _getIt<TokenStorage>()));
    _getIt.registerLazySingleton<SecurityService>(() => SecurityService());
    _getIt.registerLazySingleton<OfflineSyncEngine>(() => OfflineSyncEngine());
    _getIt.registerLazySingleton<DigitalTwinService>(() => DigitalTwinService());
    _getIt.registerLazySingleton<V2vMeshService>(() => V2vMeshService());
    _getIt.registerLazySingleton<SmartCityService>(() => SmartCityService());
    _getIt.registerLazySingleton<GpsTrackingService>(() => GpsTrackingService());
    _getIt.registerLazySingleton<VoiceGuidanceService>(() => VoiceGuidanceService());
    _getIt.registerLazySingleton<ObdBleService>(() => ObdBleService());
    _getIt.registerLazySingleton<PushNotificationService>(() => PushNotificationService());

    // Data Sources
    _getIt.registerLazySingleton<AuthRemoteDatasource>(
      () => AuthRemoteDatasourceImpl(apiClient: _getIt<ApiClient>(), tokenStorage: _getIt<TokenStorage>()),
    );
    _getIt.registerLazySingleton<NavigationRemoteDatasource>(
      () => NavigationRemoteDatasourceImpl(apiClient: _getIt<ApiClient>()),
    );
    _getIt.registerLazySingleton<NavigationLocalDatasource>(
      () => NavigationLocalDatasource(),
    );
    _getIt.registerLazySingleton<AiAssistantRemoteDatasource>(
      () => AiAssistantRemoteDatasource(apiClient: _getIt<ApiClient>()),
    );
    _getIt.registerLazySingleton<SquadRemoteDatasource>(
      () => SquadRemoteDatasource(apiClient: _getIt<ApiClient>()),
    );
    _getIt.registerLazySingleton<ObdRemoteDatasource>(
      () => ObdRemoteDatasource(apiClient: _getIt<ApiClient>()),
    );

    // Repositories
    _getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(
        remoteDatasource: _getIt<AuthRemoteDatasource>(),
        tokenStorage: _getIt<TokenStorage>(),
      ),
    );
    _getIt.registerLazySingleton<NavigationRepository>(
      () => NavigationRepositoryImpl(
        remoteDatasource: _getIt<NavigationRemoteDatasource>(),
        localDatasource: _getIt<NavigationLocalDatasource>(),
      ),
    );

    // Tier 1 Canonical Gateways & Adapters
    _getIt.registerLazySingleton<VehicleDataGateway>(
      () => DeviceProviderVehicleDataGateway(),
    );
    _getIt.registerLazySingleton<NavigationGateway>(
      () => NavigationRepositoryGatewayAdapter(
        repository: _getIt<NavigationRepository>(),
      ),
    );
    _getIt.registerLazySingleton<AIProviderGateway>(
      () => RemoteAiAssistantGatewayAdapter(
        remoteDatasource: _getIt<AiAssistantRemoteDatasource>(),
      ),
    );
    _getIt.registerLazySingleton<VoiceGateway>(
      () => PlatformVoiceInputAdapter(),
    );
    _getIt.registerLazySingleton<TextToSpeechGateway>(
      () => PlatformTextToSpeechAdapter(),
    );

    // AI Domain Services
    _getIt.registerLazySingleton<AiIntentResolver>(
      () => AiIntentResolver(
        navigationGateway: _getIt<NavigationGateway>(),
      ),
    );

    // Tier 3 Consolidated Domain State Machines (ADR-02 / ADR-03)
    _getIt.registerLazySingleton<MyVehiclesRepository>(
      () => MyVehiclesRepository(),
    );
    _getIt.registerLazySingleton<VehicleBloc>(
      () => VehicleBloc(
        repository: _getIt<MyVehiclesRepository>(),
      ),
    );
    _getIt.registerLazySingleton<NavigationBloc>(
      () => NavigationBloc(
        repository: _getIt<NavigationRepository>(),
        gateway: _getIt<NavigationGateway>(),
        gpsTrackingService: _getIt<GpsTrackingService>(),
        voiceGuidanceService: _getIt<VoiceGuidanceService>(),
      ),
    );
    _getIt.registerLazySingleton<AiAssistantBloc>(
      () => AiAssistantBloc(
        gateway: _getIt<AIProviderGateway>(),
        intentResolver: _getIt<AiIntentResolver>(),
      ),
    );
  }

  void reset() {
    _getIt.reset();
  }
}

final getIt = ServiceLocator();
