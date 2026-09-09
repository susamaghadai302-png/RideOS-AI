import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design_system/theme_engine.dart';

import 'core/di/service_locator.dart';
import 'core/network/api_client.dart';
import 'core/network/api_config.dart';
import 'core/contracts/ai_provider_gateway.dart';
import 'features/ai_assistant/data/datasources/ai_assistant_remote_datasource.dart';
import 'features/ai_assistant/domain/services/ai_intent_resolver.dart';
import 'features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/screens/auth_gate.dart';
import 'features/navigation/core/services/gps_tracking_service.dart';
import 'features/navigation/core/services/voice_guidance_service.dart';
import 'features/navigation/domain/repositories/navigation_repository.dart';
import 'features/navigation/presentation/bloc/navigation_bloc.dart';
import 'features/obd_tpms/core/ble/obd_ble_service.dart';
import 'features/obd_tpms/data/datasources/obd_remote_datasource.dart';
import 'features/obd_tpms/presentation/bloc/obd_bloc.dart';

import 'features/calling/presentation/widgets/call_overlay.dart';
import 'features/sos_safety/presentation/bloc/sos_bloc.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'features/squad_ride/data/datasources/squad_remote_datasource.dart';
import 'features/squad_ride/presentation/bloc/squad_bloc.dart';
import 'features/vehicle/presentation/bloc/vehicle_bloc.dart';
import 'features/vehicle/presentation/bloc/vehicle_event.dart';
import 'core/contracts/voice_gateway.dart';
import 'features/voice_assistant/presentation/bloc/voice_bloc.dart';
import 'core/carplay/carplay_state_bridge.dart';
import 'dart:io' show Platform;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 0. Restore persisted theme preference before first frame
  await LuxThemeEngine().init();

  // 1. Initialize Network & API Configuration (USB / LAN dual-mode)
  try {
    await ApiConfig.initialize();
    unawaited(ApiConfig.autoDetectWorkingEndpoint());
  } catch (e) {
    debugPrint('[RideOS API Config Warning]: $e');
  }

  // 2. Safe Service Locator Initializer
  try {
    getIt.setupLocator();
  } catch (e) {
    debugPrint('[Rideo Pro DI Initialization Warning]: $e');
  }

  // 3. Global Platform Dispatcher Error Catch (Non-fatal async error logging)
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[Rideo Pro Platform Error]: $error');
    return true;
  };

  // 3. Safe Framework Rendering Error Catch (Does NOT disrupt Flutter build scope)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  // 4. Safe Component Error Boundary (In-place widget fallback)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1422),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF3366).withValues(alpha: 0.4)),
          ),
          child: Text(
            'Render issue: ${details.exceptionAsString()}',
            style: const TextStyle(color: Color(0xFFFF3366), fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  runApp(const RideOSApp());
}

class RideOSApp extends StatefulWidget {
  final AuthRepository? authRepository;
  final NavigationRepository? navRepository;
  final AiAssistantRemoteDatasource? aiRemoteDatasource;
  final SquadRemoteDatasource? squadRemoteDatasource;
  final ObdRemoteDatasource? obdRemoteDatasource;
  final ObdBleService? obdBleService;
  final ApiClient? apiClient;
  final GpsTrackingService? gpsService;
  final VoiceGuidanceService? voiceService;
  final VehicleBloc? vehicleBloc;

  const RideOSApp({
    super.key,
    this.authRepository,
    this.navRepository,
    this.aiRemoteDatasource,
    this.squadRemoteDatasource,
    this.obdRemoteDatasource,
    this.obdBleService,
    this.apiClient,
    this.gpsService,
    this.voiceService,
    this.vehicleBloc,
  });

  @override
  State<RideOSApp> createState() => _RideOSAppState();
}

class _RideOSAppState extends State<RideOSApp> {
  bool _splashFinished = false;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: widget.authRepository ?? getIt<AuthRepository>(),
            )..add(AppStartedEvent()),
          ),
          BlocProvider(
            create: (context) {
              final navBloc = NavigationBloc(
                repository: widget.navRepository ?? getIt<NavigationRepository>(),
                gpsTrackingService: widget.gpsService ?? getIt<GpsTrackingService>(),
                voiceGuidanceService: widget.voiceService ?? getIt<VoiceGuidanceService>(),
              );
              
              if (Platform.isIOS) {
                navBloc.stream.listen((state) {
                  CarPlayStateBridge.onNavigationUpdate(state);
                });
              }
              
              return navBloc;
            },
          ),
          BlocProvider(
            create: (context) => (widget.vehicleBloc ?? getIt<VehicleBloc>())
              ..add(const LoadVehiclesEvent()),
          ),
          BlocProvider(
            create: (context) => AiAssistantBloc(
              gateway: widget.aiRemoteDatasource != null 
                  ? RemoteAiAssistantGatewayAdapter(remoteDatasource: widget.aiRemoteDatasource!)
                  : getIt<AIProviderGateway>(),
              intentResolver: getIt<AiIntentResolver>(),
            ),
          ),
          BlocProvider(
            create: (context) => VoiceBloc(
              gateway: getIt<VoiceGateway>(),
            ),
          ),
          BlocProvider(
            create: (context) => SosBloc(
              apiClient: widget.apiClient ?? getIt<ApiClient>(),
            ),
          ),
          BlocProvider(
            create: (context) => SquadBloc(
              remoteDatasource: widget.squadRemoteDatasource ?? getIt<SquadRemoteDatasource>(),
            ),
          ),
          BlocProvider(
            create: (context) => ObdBloc(
              bleService: widget.obdBleService ?? getIt<ObdBleService>(),
              remoteDatasource: widget.obdRemoteDatasource ?? getIt<ObdRemoteDatasource>(),
            ),
          ),
        ],
        child: AnimatedBuilder(
          animation: LuxThemeEngine(),
          builder: (context, child) {
            return MaterialApp(
              title: 'RideOS Pro',
              debugShowCheckedModeBanner: false,
              theme: LuxThemeEngine.lightTheme,
              darkTheme: LuxThemeEngine.darkTheme,
              themeMode: LuxThemeEngine().themeMode,
              builder: (context, child) {
                return GlobalCallOverlay(child: child!);
              },
              home: !_splashFinished
                  ? SplashScreen(
                      onInitialized: () {
                        setState(() => _splashFinished = true);
                      },
                    )
                  : const AuthGate(),
            );
          },
        ),
      ),
    );
  }
}
