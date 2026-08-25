import 'dart:async' show unawaited;
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/design_system/roados_tokens.dart';
import 'core/widgets/cinematic_background.dart';
import 'core/design_system/theme_engine.dart';
import 'core/graphics/global_pointer_provider.dart';
import 'core/di/service_locator.dart';
import 'core/network/api_client.dart';
import 'core/network/api_config.dart';
import 'features/ai_assistant/data/datasources/ai_assistant_remote_datasource.dart';
import 'features/ai_assistant/presentation/bloc/ai_assistant_bloc.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/screens/welcome_screen.dart';
import 'features/navigation/core/services/gps_tracking_service.dart';
import 'features/navigation/core/services/voice_guidance_service.dart';
import 'features/navigation/domain/repositories/navigation_repository.dart';
import 'features/navigation/presentation/bloc/navigation_bloc.dart';
import 'features/obd_tpms/core/ble/obd_ble_service.dart';
import 'features/obd_tpms/data/datasources/obd_remote_datasource.dart';
import 'features/obd_tpms/presentation/bloc/obd_bloc.dart';
import 'features/shell/presentation/screens/main_shell.dart';
import 'features/sos_safety/presentation/bloc/sos_bloc.dart';
import 'features/splash/presentation/screens/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/onboarding/presentation/screens/onboarding_flow_screen.dart';
import 'features/squad_ride/data/datasources/squad_remote_datasource.dart';
import 'features/squad_ride/presentation/bloc/squad_bloc.dart';

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
  });

  @override
  State<RideOSApp> createState() => _RideOSAppState();
}

class _RideOSAppState extends State<RideOSApp> {
  bool _splashFinished = false;
  bool _onboardingCompleted = false;

  @override
  void initState() {
    super.initState();
    _checkOnboarding();
  }

  Future<void> _checkOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final done = prefs.getBool('onboarding_completed') ?? false;
      if (mounted) {
        setState(() => _onboardingCompleted = kIsWeb ? true : done);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _onboardingCompleted = true);
      }
    }
  }

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
            create: (context) => NavigationBloc(
              repository: widget.navRepository ?? getIt<NavigationRepository>(),
              gpsTrackingService: widget.gpsService ?? getIt<GpsTrackingService>(),
              voiceGuidanceService: widget.voiceService ?? getIt<VoiceGuidanceService>(),
            ),
          ),
          BlocProvider(
            create: (context) => AiAssistantBloc(
              remoteDatasource: widget.aiRemoteDatasource ?? getIt<AiAssistantRemoteDatasource>(),
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
            return GlobalPointerTracker(
              child: MaterialApp(
              title: 'RideOS Pro',
              debugShowCheckedModeBanner: false,
              theme: LuxThemeEngine.lightTheme,
              darkTheme: LuxThemeEngine.darkTheme,
              themeMode: LuxThemeEngine().themeMode,
              home: kIsWeb
                  ? const MainShell()
                  : !_splashFinished
                      ? SplashScreen(
                          onInitialized: () {
                            setState(() => _splashFinished = true);
                          },
                        )
                      : !_onboardingCompleted
                          ? OnboardingFlowScreen(
                              onComplete: () {
                                setState(() => _onboardingCompleted = true);
                              },
                            )
                          : BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            if (state is AuthenticatedState) {
                              return const MainShell();
                            }
                            if (state is UnauthenticatedState || state is AuthFailureState) {
                              if (kIsWeb) {
                                return const MainShell();
                              }
                              return const WelcomeScreen();
                            }
                            return Scaffold(
                              backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
                              body: CinematicBackground(child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.navigation_rounded, size: 64, color: RoadOSColors.roadCyan),
                                    SizedBox(height: 16),
                                    CircularProgressIndicator(color: RoadOSColors.roadCyan),
                                  ],
                                ),
                              )),
                            );
                          },
                        ),
              ),
            );
          },
        ),
      ),
    );
  }
}
