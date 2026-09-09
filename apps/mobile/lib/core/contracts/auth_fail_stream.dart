import 'dart:async';

/// Canonical integration point for infrastructure/API authentication failures.
///
/// Dispatched when token refresh fails or credentials are fundamentally invalid at
/// the network/transport layer.
///
/// Conceptual flow:
/// API/HTTP layer (401 refresh failure)
///       ↓
/// AuthFailStream.instance.notifyAuthFailure()
///       ↓
/// AuthBloc (subscribes and dispatches LogoutEvent)
///       ↓
/// AuthGate (listens to AuthState.unauthenticated -> displays LoginScreen / disposes session)
abstract class AuthFailStream {
  /// Broadcast stream of authentication failure events.
  Stream<void> get stream;

  /// Triggered by HTTP/network infrastructure when token refresh fails or 401 is fatal.
  void notifyAuthFailure();

  /// Default singleton instance across the application.
  static final AuthFailStream instance = _DefaultAuthFailStream();
}

class _DefaultAuthFailStream implements AuthFailStream {
  final StreamController<void> _controller = StreamController<void>.broadcast();

  @override
  Stream<void> get stream => _controller.stream;

  @override
  void notifyAuthFailure() {
    if (!_controller.isClosed) {
      _controller.add(null);
    }
  }
}
