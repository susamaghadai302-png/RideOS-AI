import 'package:equatable/equatable.dart';
import '../../../../core/vehicle_resolution/models/active_vehicle_context.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';

class VehicleBlocState extends Equatable {
  final ActiveVehicleContext activeContext;
  final List<VehicleProfile> ownedVehicles;
  final bool isLoading;
  final String? errorMessage;

  // ADR-04: Canonical snapshot stamps
  final int epochMs;
  final int sequenceNumber;
  final String sourceIdentifier;

  const VehicleBlocState({
    required this.activeContext,
    this.ownedVehicles = const [],
    this.isLoading = false,
    this.errorMessage,
    required this.epochMs,
    required this.sequenceNumber,
    required this.sourceIdentifier,
  });

  /// Factory for the initial state before any vehicle or fleet is loaded
  factory VehicleBlocState.initial() {
    return VehicleBlocState(
      activeContext: ActiveVehicleContext.empty(),
      ownedVehicles: const [],
      isLoading: false,
      errorMessage: null,
      epochMs: DateTime.now().millisecondsSinceEpoch,
      sequenceNumber: 0,
      sourceIdentifier: 'init',
    );
  }

  VehicleBlocState copyWith({
    ActiveVehicleContext? activeContext,
    List<VehicleProfile>? ownedVehicles,
    bool? isLoading,
    String? errorMessage,
    int? epochMs,
    int? sequenceNumber,
    String? sourceIdentifier,
  }) {
    return VehicleBlocState(
      activeContext: activeContext ?? this.activeContext,
      ownedVehicles: ownedVehicles ?? this.ownedVehicles,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      epochMs: epochMs ?? DateTime.now().millisecondsSinceEpoch,
      sequenceNumber: sequenceNumber ?? (this.sequenceNumber + 1),
      sourceIdentifier: sourceIdentifier ?? this.sourceIdentifier,
    );
  }

  bool get hasActiveVehicle => activeContext.hasActiveVehicle;
  bool get isConnected => activeContext.isConnected;
  VehicleProfile? get activeProfile => activeContext.profile;

  @override
  List<Object?> get props => [
        activeContext,
        ownedVehicles,
        isLoading,
        errorMessage,
        epochMs,
        sequenceNumber,
        sourceIdentifier,
      ];
}
