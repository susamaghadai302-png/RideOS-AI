import 'package:equatable/equatable.dart';
import '../../domain/entities/rider_entity.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitialState extends AuthState {}

class AuthLoadingState extends AuthState {}

class AuthenticatedState extends AuthState {
  final RiderEntity rider;

  const AuthenticatedState({required this.rider});

  @override
  List<Object?> get props => [rider];
}

class UnauthenticatedState extends AuthState {}

class AuthFailureState extends AuthState {
  final String errorMessage;

  const AuthFailureState({required this.errorMessage});

  @override
  List<Object?> get props => [errorMessage];
}
