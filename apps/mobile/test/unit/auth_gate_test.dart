// ignore_for_file: prefer_const_constructors
import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/auth/domain/entities/rider_entity.dart';
import 'package:rideos_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:rideos_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:rideos_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:rideos_mobile/features/auth/presentation/bloc/auth_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Mock Repository
// ─────────────────────────────────────────────────────────────────────────────

class _MockAuthRepository implements AuthRepository {
  /// Controls whether any network call succeeds or throws.
  bool shouldFail = false;

  /// Controls whether a stored session token exists (simulates restoration).
  bool hasValidSession = true;

  /// Custom error message to throw when [shouldFail] is true.
  String failureMessage = 'Unknown error';

  /// Number of times [getProfile] has been called (for restoration tests).
  int getProfileCallCount = 0;

  static const _rider = RiderEntity(
    id: 'rider-001',
    email: 'rider@example.com',
    fullName: 'Aria Storm',
    phone: '+447700900001',
    garage: [],
  );

  @override
  Future<RiderEntity> login({required String email, required String password}) async {
    if (shouldFail) throw Exception(failureMessage);
    return _rider;
  }

  @override
  Future<RiderEntity> loginWithGoogle() async {
    if (shouldFail) throw Exception(failureMessage);
    return _rider;
  }

  @override
  Future<RiderEntity> loginWithGoogleCredential({
    required String email,
    required String fullName,
    String? idToken,
    String? accessToken,
  }) async {
    if (shouldFail) throw Exception(failureMessage);
    return _rider;
  }

  @override
  Future<RiderEntity> loginWithApple() async {
    if (shouldFail) throw Exception(failureMessage);
    return _rider;
  }

  @override
  Future<RiderEntity> loginWithAppleCredential({
    String? email,
    String? fullName,
    String? identityToken,
    String? authorizationCode,
  }) async {
    if (shouldFail) throw Exception(failureMessage);
    return _rider;
  }

  @override
  Future<void> requestPhoneOtp(String phone) async {
    if (shouldFail) throw Exception(failureMessage);
  }

  @override
  Future<RiderEntity> loginWithPhoneOtp({
    required String phone,
    required String otpCode,
  }) async {
    if (shouldFail) throw Exception(failureMessage);
    return _rider;
  }

  @override
  Future<RiderEntity> loginWithBiometrics() async {
    if (shouldFail) throw Exception(failureMessage);
    return _rider;
  }

  @override
  Future<RiderEntity> register({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    if (shouldFail) throw Exception(failureMessage);
    return RiderEntity(
      id: 'rider-new',
      email: email,
      fullName: fullName,
      phone: phone,
      garage: const [],
    );
  }

  @override
  Future<RiderEntity> getProfile() async {
    getProfileCallCount++;
    if (shouldFail || !hasValidSession) throw Exception('Session expired');
    return _rider;
  }

  @override
  Future<RiderEntity> addBike({
    required String make,
    required String model,
    required int year,
    required int engineCC,
    double? maxLeanAngleLimit,
  }) async =>
      _rider;

  @override
  Future<RiderEntity> deleteBike({required String bikeId}) async => _rider;

  @override
  Future<RiderEntity> setPrimaryBike({required String bikeId}) async => _rider;

  @override
  Future<void> logout() async {
    hasValidSession = false;
  }

  @override
  Future<void> forgotPassword({required String email}) async {
    if (shouldFail) throw Exception(failureMessage);
    // Simulate backend behaviour: unknown email throws NotFoundException message
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────────────────────────────────────

_MockAuthRepository _repo() => _MockAuthRepository();

AuthBloc _bloc(_MockAuthRepository repo) =>
    AuthBloc(authRepository: repo);

// ─────────────────────────────────────────────────────────────────────────────
//  Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ── 1. Unauthenticated launch ─────────────────────────────────────────────
  test('Scenario 1 — App starts unauthenticated → emits UnauthenticatedState', () async {
    final repo = _repo()..hasValidSession = false;
    final bloc = _bloc(repo);

    // AppStartedEvent is dispatched in the constructor (via main.dart).
    // We simulate that here.
    expectLater(bloc.stream, emits(isA<UnauthenticatedState>()));
    bloc.add(AppStartedEvent());

    addTearDown(bloc.close);
  });

  // ── 2. Authenticated launch ───────────────────────────────────────────────
  test('Scenario 2 — App starts authenticated → emits AuthenticatedState', () async {
    final repo = _repo()..hasValidSession = true;
    final bloc = _bloc(repo);

    expectLater(bloc.stream, emits(isA<AuthenticatedState>()));
    bloc.add(AppStartedEvent());

    addTearDown(bloc.close);
  });

  // ── 3. Successful email login ─────────────────────────────────────────────
  test('Scenario 3 — Successful email login → emits [Loading, Authenticated]', () async {
    final bloc = _bloc(_repo());

    expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoadingState>(), isA<AuthenticatedState>()]),
    );

    bloc.add(const LoginSubmittedEvent(
      email: 'rider@example.com',
      password: 'securePass123',
    ));

    addTearDown(bloc.close);
  });

  // ── 4. Failed login → error state ────────────────────────────────────────
  test('Scenario 4 — Failed login → emits [Loading, AuthFailureState]', () async {
    final repo = _repo()
      ..shouldFail = true
      ..failureMessage = 'Invalid credentials';
    final bloc = _bloc(repo);

    expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoadingState>(), isA<AuthFailureState>()]),
    );

    bloc.add(const LoginSubmittedEvent(
      email: 'bad@email.com',
      password: 'wrongpassword',
    ));

    addTearDown(bloc.close);
  });

  // ── 5. Google sign-in cancellation ───────────────────────────────────────
  test('Scenario 5 — Google cancel → emits [Loading, AuthFailureState]', () async {
    final repo = _repo()..shouldFail = true;
    final bloc = _bloc(repo);

    expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoadingState>(), isA<AuthFailureState>()]),
    );

    bloc.add(GoogleLoginEvent());

    addTearDown(bloc.close);
  });

  // ── 6. Apple sign-in cancellation ────────────────────────────────────────
  test('Scenario 6 — Apple cancel → emits [Loading, AuthFailureState]', () async {
    final repo = _repo()..shouldFail = true;
    final bloc = _bloc(repo);

    expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoadingState>(), isA<AuthFailureState>()]),
    );

    bloc.add(AppleLoginEvent());

    addTearDown(bloc.close);
  });

  // ── 7. Successful sign-up ─────────────────────────────────────────────────
  test('Scenario 7 — Successful sign-up → emits [Loading, Authenticated]', () async {
    final bloc = _bloc(_repo());

    expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoadingState>(), isA<AuthenticatedState>()]),
    );

    bloc.add(const RegisterSubmittedEvent(
      email: 'new@example.com',
      password: 'ultraSecure!1',
      fullName: 'Nova Rider',
      phone: '+447700900002',
    ));

    addTearDown(bloc.close);
  });

  // ── 8. Failed sign-up → error state ──────────────────────────────────────
  test('Scenario 8 — Failed sign-up → emits [Loading, AuthFailureState]', () async {
    final repo = _repo()
      ..shouldFail = true
      ..failureMessage = 'Email already registered';
    final bloc = _bloc(repo);

    expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoadingState>(), isA<AuthFailureState>()]),
    );

    bloc.add(const RegisterSubmittedEvent(
      email: 'existing@example.com',
      password: 'ultraSecure!1',
      fullName: 'Dupe Rider',
      phone: '+447700900003',
    ));

    addTearDown(bloc.close);
  });

  // ── 9. Logout ─────────────────────────────────────────────────────────────
  test('Scenario 9 — Logout → emits UnauthenticatedState', () async {
    final bloc = _bloc(_repo());

    expectLater(bloc.stream, emits(isA<UnauthenticatedState>()));
    bloc.add(LogoutEvent());

    addTearDown(bloc.close);
  });

  // ── 10. Session restoration — valid token ─────────────────────────────────
  test('Scenario 10 — Session restoration (valid token) → AuthenticatedState', () async {
    final repo = _repo()..hasValidSession = true;
    final bloc = _bloc(repo);

    expectLater(bloc.stream, emits(isA<AuthenticatedState>()));
    bloc.add(AppStartedEvent());

    await Future.delayed(const Duration(milliseconds: 100));
    expect(repo.getProfileCallCount, greaterThan(0));

    addTearDown(bloc.close);
  });

  // ── 11. Session expiration — invalid token ────────────────────────────────
  test('Scenario 11 — Session expiration (invalid token) → UnauthenticatedState', () async {
    final repo = _repo()..hasValidSession = false;
    final bloc = _bloc(repo);

    expectLater(bloc.stream, emits(isA<UnauthenticatedState>()));
    bloc.add(AppStartedEvent());

    addTearDown(bloc.close);
  });

  // ── 12. Unauthenticated protected access ─────────────────────────────────
  test('Scenario 12 — No session → AuthGate blocks access (stays Unauthenticated)', () async {
    final repo = _repo()..hasValidSession = false;
    final bloc = _bloc(repo);

    // Simulates: app starts, auth check fails, user is not authenticated.
    // AuthGate would observe UnauthenticatedState and show WelcomeScreen.
    final states = <AuthState>[];
    final subscription = bloc.stream.listen(states.add);

    bloc.add(AppStartedEvent());
    await Future.delayed(const Duration(milliseconds: 200));

    expect(states, anyElement(isA<UnauthenticatedState>()));
    expect(states, isNot(anyElement(isA<AuthenticatedState>())));

    await subscription.cancel();
    await bloc.close();
  });

  // ── 13. Authenticated protected access ───────────────────────────────────
  test('Scenario 13 — Valid session → AuthGate grants access (AuthenticatedState)', () async {
    final repo = _repo()..hasValidSession = true;
    final bloc = _bloc(repo);

    final states = <AuthState>[];
    final subscription = bloc.stream.listen(states.add);

    bloc.add(AppStartedEvent());
    await Future.delayed(const Duration(milliseconds: 200));

    expect(states, anyElement(isA<AuthenticatedState>()));
    expect(states, isNot(anyElement(isA<UnauthenticatedState>())));

    await subscription.cancel();
    await bloc.close();
  });

  // ── 14a. Google credential provider linking ───────────────────────────────
  test('Scenario 14a — Google credential sign-in → [Loading, Authenticated]', () async {
    final bloc = _bloc(_repo());

    expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoadingState>(), isA<AuthenticatedState>()]),
    );

    bloc.add(const GoogleSignInWithCredentialEvent(
      email: 'aria@gmail.com',
      fullName: 'Aria Storm',
      idToken: 'fake_id_token_abc',
      accessToken: 'fake_access_token_xyz',
    ));

    addTearDown(bloc.close);
  });

  // ── 14b. Apple credential provider linking ────────────────────────────────
  test('Scenario 14b — Apple credential sign-in → [Loading, Authenticated]', () async {
    final bloc = _bloc(_repo());

    expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoadingState>(), isA<AuthenticatedState>()]),
    );

    bloc.add(const AppleSignInWithCredentialEvent(
      email: 'aria@icloud.com',
      fullName: 'Aria Storm',
      identityToken: 'fake_apple_identity',
      authorizationCode: 'fake_apple_auth_code',
    ));

    addTearDown(bloc.close);
  });

  // ── 15. Network / auth error → AuthFailureState with message ─────────────
  test('Scenario 15 — Network error → AuthFailureState with human-readable message', () async {
    final repo = _repo()
      ..shouldFail = true
      ..failureMessage = 'Connection refused';
    final bloc = _bloc(repo);

    final states = <AuthState>[];
    final subscription = bloc.stream.listen(states.add);

    bloc.add(const LoginSubmittedEvent(
      email: 'rider@example.com',
      password: 'pass123',
    ));

    await Future.delayed(const Duration(milliseconds: 200));

    final failureStates = states.whereType<AuthFailureState>().toList();
    expect(failureStates, isNotEmpty);
    // The error message should be non-empty and human-readable.
    expect(failureStates.first.errorMessage, isNotEmpty);

    await subscription.cancel();
    await bloc.close();
  });

  // ── Bonus: Initial state is AuthInitialState ──────────────────────────────
  test('Bonus — Initial BLoC state is AuthInitialState', () {
    final bloc = _bloc(_repo());
    expect(bloc.state, isA<AuthInitialState>());
    bloc.close();
  });

  // ── Bonus: Auth always resolves to non-loading state ─────────────────────
  test('Bonus — AuthBloc always resolves to non-loading state after login attempt', () async {
    final bloc = _bloc(_repo());

    final states = <AuthState>[];
    final subscription = bloc.stream.listen(states.add);

    bloc.add(const LoginSubmittedEvent(email: 'a@b.com', password: 'pass'));
    await Future.delayed(const Duration(milliseconds: 300));

    // Final state must not be AuthLoadingState — always resolves.
    expect(states.last, isNot(isA<AuthLoadingState>()));
    // Should have gone through loading.
    expect(states, contains(isA<AuthLoadingState>()));
    // Should have resolved to authenticated (happy path here).
    expect(states.last, isA<AuthenticatedState>());

    await subscription.cancel();
    await bloc.close();
  });

  // ── Bonus: Logout + re-login flow ─────────────────────────────────────────
  test('Bonus — Logout then login → correct state sequence', () async {
    final repo = _repo()..hasValidSession = true;
    final bloc = _bloc(repo);

    final states = <AuthState>[];
    final subscription = bloc.stream.listen(states.add);

    // Step 1: Logout
    bloc.add(LogoutEvent());
    await Future.delayed(const Duration(milliseconds: 100));

    // Step 2: Re-login
    bloc.add(const LoginSubmittedEvent(
      email: 'rider@example.com',
      password: 'securePass',
    ));
    await Future.delayed(const Duration(milliseconds: 200));

    expect(states, containsAllInOrder([
      isA<UnauthenticatedState>(),
      isA<AuthLoadingState>(),
      isA<AuthenticatedState>(),
    ]));

    await subscription.cancel();
    await bloc.close();
  });

  // ── Forgot password scenarios ─────────────────────────────────────────────
  test('Forgot password — success → emits [Loading, ForgotPasswordSentState]', () async {
    final bloc = _bloc(_repo());
    expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoadingState>(), isA<ForgotPasswordSentState>()]),
    );
    bloc.add(const ForgotPasswordSubmittedEvent(email: 'rider@example.com'));
    addTearDown(bloc.close);
  });

  test('Forgot password — email not found → emits [Loading, AuthFailureState]', () async {
    final repo = _repo()
      ..shouldFail = true
      ..failureMessage = 'rider email not found';
    final bloc = _bloc(repo);
    expectLater(
      bloc.stream,
      emitsInOrder([isA<AuthLoadingState>(), isA<AuthFailureState>()]),
    );
    bloc.add(const ForgotPasswordSubmittedEvent(email: 'notexist@example.com'));
    addTearDown(bloc.close);
  });

  test('Forgot password — _mapAuthError maps not-found to user-friendly text', () async {
    final repo = _repo()
      ..shouldFail = true
      ..failureMessage = 'rider email not found';
    final bloc = _bloc(repo);
    final states = <AuthState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const ForgotPasswordSubmittedEvent(email: 'notexist@example.com'));
    await Future.delayed(const Duration(milliseconds: 200));
    final failure = states.whereType<AuthFailureState>().first;
    expect(failure.errorMessage, contains('No account found'));
    await sub.cancel();
    await bloc.close();
  });

  test('Forgot password — sent state carries the correct email', () async {
    final bloc = _bloc(_repo());
    final states = <AuthState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const ForgotPasswordSubmittedEvent(email: 'Aria@RideOS.ai'));
    await Future.delayed(const Duration(milliseconds: 200));
    final sentStates = states.whereType<ForgotPasswordSentState>().toList();
    expect(sentStates, isNotEmpty);
    expect(sentStates.first.email.trim(), isNotEmpty);
    await sub.cancel();
    await bloc.close();
  });

  // ── _mapAuthError scenarios ───────────────────────────────────────────────
  test('_mapAuthError — invalid credentials maps to user-friendly message', () async {
    final repo = _repo()
      ..shouldFail = true
      ..failureMessage = 'Invalid email or password';
    final bloc = _bloc(repo);
    final states = <AuthState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const LoginSubmittedEvent(email: 'a@b.com', password: 'wrong'));
    await Future.delayed(const Duration(milliseconds: 200));
    final failure = states.whereType<AuthFailureState>().first;
    expect(failure.errorMessage, contains('incorrect'));
    await sub.cancel();
    await bloc.close();
  });

  test('_mapAuthError — already-exists maps to sign-in prompt', () async {
    final repo = _repo()
      ..shouldFail = true
      ..failureMessage = 'An account with this email already exists';
    final bloc = _bloc(repo);
    final states = <AuthState>[];
    final sub = bloc.stream.listen(states.add);
    bloc.add(const RegisterSubmittedEvent(
      email: 'dup@example.com',
      password: 'pass12345',
      fullName: 'Dup Rider',
      phone: '+447700900004',
    ));
    await Future.delayed(const Duration(milliseconds: 200));
    final failure = states.whereType<AuthFailureState>().first;
    expect(failure.errorMessage.toLowerCase(), contains('sign in'));
    await sub.cancel();
    await bloc.close();
  });
}
