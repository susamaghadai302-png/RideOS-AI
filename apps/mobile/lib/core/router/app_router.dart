import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/screens/auth_gate.dart';
import '../../features/auth/presentation/screens/auth_loading_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/phone_otp_auth_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/landing/presentation/screens/web_landing_screen.dart';
import '../../features/shell/presentation/screens/roados_app_shell.dart';
import '../utils/platform_web_helper.dart';

class AppRouter {
  // Public Route Paths
  static const String root = '/';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String otp = '/otp';

  // Protected Cockpit Routes (Mapped to RoadOSAppShell indices)
  static const String dashboard = '/dashboard';
  static const String drive = '/drive';
  static const String navigation = '/navigation';
  static const String vehicles = '/vehicles';
  static const String connect = '/connect';
  static const String garage = '/garage';
  static const String telemetry = '/telemetry';
  static const String connectionCenter = '/connection-center';
  static const String trips = '/trips';
  static const String diagnostics = '/diagnostics';
  static const String maintenance = '/maintenance';
  static const String safety = '/safety';
  static const String dashcam = '/dashcam';
  static const String documents = '/documents';
  static const String settings = '/settings';
  static const String squad = '/squad';
  static const String aiAssistant = '/ai-assistant';

  static String routeForIndex(int index) {
    switch (index) {
      case 0:
        return dashboard;
      case 1:
        return drive;
      case 2:
        return navigation;
      case 3:
        return vehicles;
      case 4:
        return connect;
      case 5:
        return garage;
      case 6:
        return telemetry;
      case 7:
        return connectionCenter;
      case 8:
        return trips;
      case 9:
        return diagnostics;
      case 10:
        return maintenance;
      case 11:
        return safety;
      case 12:
        return dashcam;
      case 13:
        return documents;
      case 14:
        return settings;
      case 15:
        return squad;
      case 16:
        return aiAssistant;
      default:
        return dashboard;
    }
  }

  static int? indexForRoute(String path) {
    switch (path) {
      case dashboard:
        return 0;
      case drive:
        return 1;
      case navigation:
        return 2;
      case vehicles:
        return 3;
      case connect:
        return 4;
      case garage:
        return 5;
      case telemetry:
        return 6;
      case connectionCenter:
        return 7;
      case trips:
        return 8;
      case diagnostics:
        return 9;
      case maintenance:
        return 10;
      case safety:
        return 11;
      case dashcam:
        return 12;
      case documents:
        return 13;
      case settings:
        return 14;
      case squad:
        return 15;
      case aiAssistant:
        return 16;
      default:
        return null;
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? '/');
    final path = uri.path.isEmpty ? '/' : uri.path;

    switch (path) {
      case root:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => kIsWeb ? const WebLandingScreen() : const AuthGate(),
        );

      case landing:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const WebLandingScreen(),
        );

      case login:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );

      case register:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const RegisterScreen(),
        );

      case forgotPassword:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const ForgotPasswordScreen(),
        );

      case otp:
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => const PhoneOtpAuthScreen(),
        );

      default:
        final shellIndex = indexForRoute(path);
        if (shellIndex != null) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ProtectedRoute(
              child: RoadOSAppShell(initialIndex: shellIndex),
            ),
          );
        }

        // Unknown route fallback
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => kIsWeb ? const WebLandingScreen() : const AuthGate(),
        );
    }
  }
}

/// ProtectedRoute — Enforces authentication for protected cockpit routes.
///
/// If authenticated: renders [child].
/// If unauthenticated: redirects to [AppRouter.login].
/// If loading/verifying session: displays [AuthLoadingScreen].
class ProtectedRoute extends StatelessWidget {
  final Widget child;
  const ProtectedRoute({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous is AuthenticatedState && current is! AuthenticatedState,
      listener: (context, state) {
        if (state is UnauthenticatedState || state is AuthFailureState) {
          PlatformWebHelper.replaceUrl(AppRouter.login);
          SystemNavigator.routeInformationUpdated(uri: Uri.parse(AppRouter.login));
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.login,
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        if (state is AuthenticatedState) {
          return child;
        }

        if (state is UnauthenticatedState || state is AuthFailureState) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            PlatformWebHelper.replaceUrl(AppRouter.login);
            SystemNavigator.routeInformationUpdated(uri: Uri.parse(AppRouter.login));
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pushReplacementNamed(AppRouter.login);
            } else {
              Navigator.of(context).pushReplacementNamed(AppRouter.login);
            }
          });
          return const AuthLoadingScreen(key: ValueKey('auth_redirecting'));
        }

        // AuthInitialState or AuthLoadingState (verifying persistent token)
        return const AuthLoadingScreen(key: ValueKey('auth_verifying'));
      },
    );
  }
}
