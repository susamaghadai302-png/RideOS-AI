import 'dart:async' show unawaited;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';
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
import 'features/navigation/domain/services/route_service.dart';
import 'features/navigation/domain/services/location_service.dart';
import 'features/navigation/domain/services/navigation_voice_service.dart';
import 'features/navigation/presentation/bloc/navigation_bloc.dart';
import 'features/navigation/presentation/bloc/navigation_state.dart';
import 'core/vehicle_connectivity/services/smart_display_connection_manager.dart';
import 'core/vehicle_connectivity/models/rideos_display_packet.dart';
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

  try {
    final options = DefaultFirebaseOptions.currentPlatform;

    // RIDEOS AI - FAIL CLOSED SECURITY GATE
    // Prevent mock configurations from passing production release constraints.
    if (kReleaseMode &&
        (options.projectId == 'rideos-mock-project' ||
            options.appId.contains('1234567890'))) {
      throw UnsupportedError(
          'Production deployment blocked: Detected mock Firebase configuration in release build.');
    }

    await Firebase.initializeApp(
      options: options,
    );
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kReleaseMode
          ? const AndroidPlayIntegrityProvider()
          : const AndroidDebugProvider(),
      providerApple: const AppleDeviceCheckProvider(),
    );
  } catch (e) {
    debugPrint('[Firebase Init Warning]: $e');
  }

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
  final originalOnError = FlutterError.onError;
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kReleaseMode) {
      FlutterError.presentError(details);
    } else if (originalOnError != null) {
      originalOnError(details);
    }
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
            border: Border.all(
                color: const Color(0xFFFF3366).withValues(alpha: 0.4)),
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
  final AiAssistantRemoteDatasource? aiRemoteDatasource;
  final SquadRemoteDatasource? squadRemoteDatasource;
  final ObdRemoteDatasource? obdRemoteDatasource;
  final ObdBleService? obdBleService;
  final ApiClient? apiClient;
  final RouteService? routeService;
  final LocationService? locationService;
  final NavigationVoiceService? voiceService;
  final VehicleBloc? vehicleBloc;

  const RideOSApp({
    super.key,
    this.authRepository,
    this.aiRemoteDatasource,
    this.squadRemoteDatasource,
    this.obdRemoteDatasource,
    this.obdBleService,
    this.apiClient,
    this.routeService,
    this.locationService,
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
                routeService: widget.routeService ?? getIt<RouteService>(),
                locationService:
                    widget.locationService ?? getIt<LocationService>(),
                voiceService:
                    widget.voiceService ?? getIt<NavigationVoiceService>(),
              );

              if (Platform.isIOS) {
                navBloc.stream.listen((state) {
                  CarPlayStateBridge.onNavigationUpdate(state);

                  // Also send to Bluetooth Smart Display if connected
                  if (state is NavigationActiveState) {
                    final packet = RideOSDisplayPacket(
                      timestamp: DateTime.now(),
                      navigationState: 'ACTIVE',
                      maneuverType: state.currentStep?.instruction,
                      maneuverDistanceMeters:
                          (state.distanceRemainingKm ?? 0) * 1000,
                      distanceToDestinationMeters:
                          (state.distanceRemainingKm ?? 0) *
                              1000, // Or route total
                      eta: state.durationRemainingMins?.toString(),
                      streetName: state.currentStep?.instruction,
                      speedKmh: state.currentFix?.speedKmh,
                      connectionStatus: SmartDisplayConnectionManager()
                          .currentState
                          .name
                          .toUpperCase(),
                    );
                    SmartDisplayConnectionManager()
                        .sendNavigationUpdate(packet);
                  }
                });
              } else {
                navBloc.stream.listen((state) {
                  if (state is NavigationActiveState) {
                    final packet = RideOSDisplayPacket(
                      timestamp: DateTime.now(),
                      navigationState: 'ACTIVE',
                      maneuverType: state.currentStep?.instruction,
                      maneuverDistanceMeters:
                          (state.distanceRemainingKm ?? 0) * 1000,
                      distanceToDestinationMeters:
                          (state.distanceRemainingKm ?? 0) *
                              1000, // Or route total
                      eta: state.durationRemainingMins?.toString(),
                      streetName: state.currentStep?.instruction,
                      speedKmh: state.currentFix?.speedKmh,
                      connectionStatus: SmartDisplayConnectionManager()
                          .currentState
                          .name
                          .toUpperCase(),
                    );
                    SmartDisplayConnectionManager()
                        .sendNavigationUpdate(packet);
                  }
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
                  ? RemoteAiAssistantGatewayAdapter(
                      remoteDatasource: widget.aiRemoteDatasource!)
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
              remoteDatasource: widget.squadRemoteDatasource ??
                  getIt<SquadRemoteDatasource>(),
            ),
          ),
          BlocProvider(
            create: (context) => ObdBloc(
              bleService: widget.obdBleService ?? getIt<ObdBleService>(),
              remoteDatasource:
                  widget.obdRemoteDatasource ?? getIt<ObdRemoteDatasource>(),
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
