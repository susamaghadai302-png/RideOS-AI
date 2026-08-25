import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AppStartedEvent extends AuthEvent {}

class LoginSubmittedEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginSubmittedEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class GoogleLoginEvent extends AuthEvent {}
class GoogleSignInSubmittedEvent extends AuthEvent {}

/// Real Google Sign-In with actual credentials from the native SDK
class GoogleSignInWithCredentialEvent extends AuthEvent {
  final String email;
  final String fullName;
  final String? idToken;
  final String? accessToken;

  const GoogleSignInWithCredentialEvent({
    required this.email,
    required this.fullName,
    this.idToken,
    this.accessToken,
  });

  @override
  List<Object?> get props => [email, fullName, idToken, accessToken];
}

class AppleLoginEvent extends AuthEvent {}
class AppleSignInSubmittedEvent extends AuthEvent {}

/// Real Apple Sign-In with actual credentials from the native SDK
class AppleSignInWithCredentialEvent extends AuthEvent {
  final String? email;
  final String? fullName;
  final String? identityToken;
  final String? authorizationCode;

  const AppleSignInWithCredentialEvent({
    this.email,
    this.fullName,
    this.identityToken,
    this.authorizationCode,
  });

  @override
  List<Object?> get props => [email, fullName, identityToken, authorizationCode];
}

class BiometricAuthRequestedEvent extends AuthEvent {}

class RegisterSubmittedEvent extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String phone;
  final String? emergencyContact;
  final String? bikeMake;
  final String? bikeModel;
  final int? bikeYear;
  final int? engineCC;
  final double? maxLeanAngleLimit;

  const RegisterSubmittedEvent({
    required this.email,
    required this.password,
    required this.fullName,
    required this.phone,
    this.emergencyContact,
    this.bikeMake,
    this.bikeModel,
    this.bikeYear,
    this.engineCC,
    this.maxLeanAngleLimit,
  });

  @override
  List<Object?> get props => [
        email, password, fullName, phone, emergencyContact,
        bikeMake, bikeModel, bikeYear, engineCC, maxLeanAngleLimit,
      ];
}

class AddBikeSubmittedEvent extends AuthEvent {
  final String make;
  final String model;
  final int year;
  final int engineCC;
  final double? maxLeanAngleLimit;

  const AddBikeSubmittedEvent({
    required this.make,
    required this.model,
    required this.year,
    required this.engineCC,
    this.maxLeanAngleLimit,
  });

  @override
  List<Object?> get props => [make, model, year, engineCC, maxLeanAngleLimit];
}

class DeleteBikeSubmittedEvent extends AuthEvent {
  final String bikeId;

  const DeleteBikeSubmittedEvent({required this.bikeId});

  @override
  List<Object?> get props => [bikeId];
}

class SetPrimaryBikeSubmittedEvent extends AuthEvent {
  final String bikeId;

  const SetPrimaryBikeSubmittedEvent({required this.bikeId});

  @override
  List<Object?> get props => [bikeId];
}

class LogoutEvent extends AuthEvent {}
