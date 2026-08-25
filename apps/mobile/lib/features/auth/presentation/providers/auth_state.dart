import 'package:equatable/equatable.dart';
import '../../domain/entities/rider_entity.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthState extends Equatable {
  final AuthStatus status;
  final RiderEntity? rider;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.rider,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    RiderEntity? rider,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      rider: rider ?? this.rider,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, rider, errorMessage];
}
