import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_state.dart';
import '../../domain/entities/rider_entity.dart';
import '../../../../core/storage/token_storage.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final TokenStorage tokenStorage;

  AuthNotifier({required this.tokenStorage}) : super(const AuthState()) {
    checkAuthStatus();
  }

  void setAuthenticatedRider(RiderEntity rider) {
    state = state.copyWith(
      status: AuthStatus.authenticated,
      rider: rider,
    );
  }

  Future<void> checkAuthStatus() async {
    state = state.copyWith(status: AuthStatus.loading);
    final token = await tokenStorage.getAccessToken();

    if (token != null && token.isNotEmpty) {
      state = state.copyWith(status: AuthStatus.authenticated);
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated, rider: null);
    }
  }

  Future<void> logout() async {
    await tokenStorage.clearTokens();
    state = state.copyWith(status: AuthStatus.unauthenticated, rider: null);
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  return AuthNotifier(tokenStorage: tokenStorage);
});
