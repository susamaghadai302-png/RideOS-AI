import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/models/rider_model.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(AuthInitialState()) {
    on<AppStartedEvent>(_onAppStarted);
    on<LoginSubmittedEvent>(_onLoginSubmitted);
    on<GoogleLoginEvent>(_onGoogleLoginLegacy);
    on<GoogleSignInSubmittedEvent>((e, emit) => _onGoogleLoginLegacy(GoogleLoginEvent(), emit));
    on<GoogleSignInWithCredentialEvent>(_onGoogleSignInWithCredential);
    on<AppleLoginEvent>(_onAppleLoginLegacy);
    on<AppleSignInSubmittedEvent>((e, emit) => _onAppleLoginLegacy(AppleLoginEvent(), emit));
    on<AppleSignInWithCredentialEvent>(_onAppleSignInWithCredential);
    on<BiometricAuthRequestedEvent>(_onBiometricAuth);
    on<RegisterSubmittedEvent>(_onRegisterSubmitted);
    on<AddBikeSubmittedEvent>(_onAddBikeSubmitted);
    on<DeleteBikeSubmittedEvent>(_onDeleteBikeSubmitted);
    on<SetPrimaryBikeSubmittedEvent>(_onSetPrimaryBikeSubmitted);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onAppStarted(AppStartedEvent event, Emitter<AuthState> emit) async {
    try {
      final rider = await authRepository.getProfile();
      emit(AuthenticatedState(rider: rider));
    } catch (_) {
      emit(UnauthenticatedState());
    }
  }

  Future<void> _onLoginSubmitted(LoginSubmittedEvent event, Emitter<AuthState> emit) async {
    if (state is AuthLoadingState) return;
    emit(AuthLoadingState());
    try {
      final rider = await authRepository.login(
        email: event.email.trim().toLowerCase(),
        password: event.password,
      );
      emit(AuthenticatedState(rider: rider));
    } catch (e) {
      emit(AuthFailureState(errorMessage: ApiClient.formatErrorMessage(e)));
    }
  }

  // Legacy Google login (falls back to getProfile — kept for backward compat)
  Future<void> _onGoogleLoginLegacy(GoogleLoginEvent event, Emitter<AuthState> emit) async {
    if (state is AuthLoadingState) return;
    emit(AuthLoadingState());
    try {
      final rider = await authRepository.loginWithGoogle();
      emit(AuthenticatedState(rider: rider));
    } catch (e) {
      emit(AuthFailureState(errorMessage: ApiClient.formatErrorMessage(e)));
    }
  }

  /// Real Google Sign-In with credentials from the native SDK
  Future<void> _onGoogleSignInWithCredential(GoogleSignInWithCredentialEvent event, Emitter<AuthState> emit) async {
    if (state is AuthLoadingState) return;
    emit(AuthLoadingState());
    try {
      final rider = await authRepository.loginWithGoogleCredential(
        email: event.email,
        fullName: event.fullName,
        idToken: event.idToken,
        accessToken: event.accessToken,
      );
      emit(AuthenticatedState(rider: rider));
    } catch (e) {
      emit(AuthFailureState(errorMessage: ApiClient.formatErrorMessage(e)));
    }
  }

  // Legacy Apple login (kept for backward compat)
  Future<void> _onAppleLoginLegacy(AppleLoginEvent event, Emitter<AuthState> emit) async {
    if (state is AuthLoadingState) return;
    emit(AuthLoadingState());
    try {
      final rider = await authRepository.loginWithApple();
      emit(AuthenticatedState(rider: rider));
    } catch (e) {
      emit(AuthFailureState(errorMessage: ApiClient.formatErrorMessage(e)));
    }
  }

  /// Real Apple Sign-In with credentials from the native SDK
  Future<void> _onAppleSignInWithCredential(AppleSignInWithCredentialEvent event, Emitter<AuthState> emit) async {
    if (state is AuthLoadingState) return;
    emit(AuthLoadingState());
    try {
      final rider = await authRepository.loginWithAppleCredential(
        email: event.email,
        fullName: event.fullName,
        identityToken: event.identityToken,
        authorizationCode: event.authorizationCode,
      );
      emit(AuthenticatedState(rider: rider));
    } catch (e) {
      emit(AuthFailureState(errorMessage: ApiClient.formatErrorMessage(e)));
    }
  }

  /// Real Biometric Auth — uses stored session token
  Future<void> _onBiometricAuth(BiometricAuthRequestedEvent event, Emitter<AuthState> emit) async {
    if (state is AuthLoadingState) return;
    emit(AuthLoadingState());
    try {
      final rider = await authRepository.loginWithBiometrics();
      emit(AuthenticatedState(rider: rider));
    } catch (e) {
      emit(AuthFailureState(errorMessage: ApiClient.formatErrorMessage(e)));
    }
  }

  Future<void> _onRegisterSubmitted(RegisterSubmittedEvent event, Emitter<AuthState> emit) async {
    if (state is AuthLoadingState) return;
    emit(AuthLoadingState());
    try {
      final rider = await authRepository.register(
        email: event.email.trim().toLowerCase(),
        password: event.password,
        fullName: event.fullName.trim(),
        phone: event.phone.trim(),
      );
      emit(AuthenticatedState(rider: rider));
    } catch (e) {
      emit(AuthFailureState(errorMessage: ApiClient.formatErrorMessage(e)));
    }
  }

  Future<void> _onAddBikeSubmitted(AddBikeSubmittedEvent event, Emitter<AuthState> emit) async {
    if (state is AuthenticatedState) {
      try {
        final updatedRider = await authRepository.addBike(
          make: event.make,
          model: event.model,
          year: event.year,
          engineCC: event.engineCC,
          maxLeanAngleLimit: event.maxLeanAngleLimit,
        );
        emit(AuthenticatedState(rider: updatedRider));
      } catch (e) {
        emit(AuthFailureState(errorMessage: ApiClient.formatErrorMessage(e)));
      }
    }
  }

  Future<void> _onDeleteBikeSubmitted(DeleteBikeSubmittedEvent event, Emitter<AuthState> emit) async {
    if (state is AuthenticatedState) {
      try {
        final updatedRider = await authRepository.deleteBike(bikeId: event.bikeId);
        emit(AuthenticatedState(rider: updatedRider));
      } catch (e) {
        emit(AuthFailureState(errorMessage: ApiClient.formatErrorMessage(e)));
      }
    }
  }

  Future<void> _onSetPrimaryBikeSubmitted(SetPrimaryBikeSubmittedEvent event, Emitter<AuthState> emit) async {
    if (state is AuthenticatedState) {
      try {
        final updatedRider = await authRepository.setPrimaryBike(bikeId: event.bikeId);
        emit(AuthenticatedState(rider: updatedRider));
      } catch (e) {
        emit(AuthFailureState(errorMessage: ApiClient.formatErrorMessage(e)));
      }
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    await authRepository.logout();
    emit(UnauthenticatedState());
  }
}
