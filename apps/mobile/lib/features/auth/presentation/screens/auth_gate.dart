import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_state.dart';
import 'auth_loading_screen.dart';
import 'welcome_screen.dart';
import '../../../shell/presentation/screens/main_shell.dart';

/// AuthGate — the single authoritative navigation gateway for RideOS-AI.
///
/// Serves as the persistent root router:
///  • Renders [AuthLoadingScreen] during initial session check / restoration.
///  • Renders [WelcomeScreen] when unauthenticated or on session failure.
///  • Renders [MainShell] when authenticated.
///
/// On auth transitions (e.g. Login success, Register success, Logout, 401 Expiry):
///  - Automatically pops any open subroutes/modals back to root via [Navigator.popUntil((r) => r.isFirst)].
///  - Rebuilds in-place with zero flashing or route-stack corruption.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          (previous is AuthenticatedState) != (current is AuthenticatedState),
      listener: (context, state) {
        // When transitioning between Authenticated and Unauthenticated states,
        // clear any pushed subroutes (LoginScreen, RegisterScreen, Modals, Settings)
        // so the root screen is clean.
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
      builder: (context, state) {
        if (state is AuthenticatedState) {
          return const MainShell(key: ValueKey('main_shell'));
        }
        if (state is UnauthenticatedState || state is AuthFailureState) {
          return const WelcomeScreen(key: ValueKey('welcome_screen'));
        }
        // AuthInitialState or AuthLoadingState
        return const AuthLoadingScreen(key: ValueKey('auth_loading'));
      },
    );
  }
}
