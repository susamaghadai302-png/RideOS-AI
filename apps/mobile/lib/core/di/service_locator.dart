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
import '../../features/squad_ride/data/datasources/squad_remote_datasource.dart';
import '../../features/obd_tpms/core/ble/obd_ble_service.dart';
import '../../features/obd_tpms/data/datasources/obd_remote_datasource.dart';
import '../../features/telematics/core/services/digital_twin_service.dart';
import '../../features/telematics/core/services/smart_city_service.dart';
import '../../features/telematics/core/services/v2v_mesh_service.dart';
import '../notifications/services/push_notification_service.dart';

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
  }

  void reset() {
    _getIt.reset();
  }
}

final getIt = ServiceLocator();
