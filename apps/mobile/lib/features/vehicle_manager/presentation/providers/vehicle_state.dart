import 'package:equatable/equatable.dart';
import '../../domain/entities/motorcycle_entity.dart';

class VehicleState extends Equatable {
  final List<MotorcycleEntity> garage;
  final MotorcycleEntity? activeMotorcycle;
  final bool isLoading;

  const VehicleState({
    this.garage = const [],
    this.activeMotorcycle,
    this.isLoading = false,
  });

  VehicleState copyWith({
    List<MotorcycleEntity>? garage,
    MotorcycleEntity? activeMotorcycle,
    bool? isLoading,
  }) {
    return VehicleState(
      garage: garage ?? this.garage,
      activeMotorcycle: activeMotorcycle ?? this.activeMotorcycle,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  List<Object?> get props => [garage, activeMotorcycle, isLoading];
}
