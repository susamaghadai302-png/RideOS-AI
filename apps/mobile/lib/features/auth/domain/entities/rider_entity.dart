import 'package:equatable/equatable.dart';
import '../../../orders/domain/entities/order_entity.dart';

class MotorcycleEntity extends Equatable {
  final String bikeId;
  final String make;
  final String model;
  final int year;
  final int engineCC;
  final double maxLeanAngleLimit;
  final bool isPrimary;
  final double? frontPsi;
  final double? rearPsi;
  final String? imageUrl;
  final String? topSpeed;
  final String? horsePower;
  final String? weightKg;
  final double aiHealthScore;
  final String? liveryColorHex;

  const MotorcycleEntity({
    required this.bikeId,
    required this.make,
    required this.model,
    required this.year,
    required this.engineCC,
    required this.maxLeanAngleLimit,
    required this.isPrimary,
    this.frontPsi = 36.0,
    this.rearPsi = 42.0,
    this.imageUrl,
    this.topSpeed = '299 km/h',
    this.horsePower = '200 HP',
    this.weightKg = '198 kg',
    this.aiHealthScore = 98.0,
    this.liveryColorHex = 'FF5E00',
  });

  MotorcycleEntity copyWith({
    String? bikeId,
    String? make,
    String? model,
    int? year,
    int? engineCC,
    double? maxLeanAngleLimit,
    bool? isPrimary,
    double? frontPsi,
    double? rearPsi,
    String? imageUrl,
    String? topSpeed,
    String? horsePower,
    String? weightKg,
    double? aiHealthScore,
    String? liveryColorHex,
  }) {
    return MotorcycleEntity(
      bikeId: bikeId ?? this.bikeId,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      engineCC: engineCC ?? this.engineCC,
      maxLeanAngleLimit: maxLeanAngleLimit ?? this.maxLeanAngleLimit,
      isPrimary: isPrimary ?? this.isPrimary,
      frontPsi: frontPsi ?? this.frontPsi,
      rearPsi: rearPsi ?? this.rearPsi,
      imageUrl: imageUrl ?? this.imageUrl,
      topSpeed: topSpeed ?? this.topSpeed,
      horsePower: horsePower ?? this.horsePower,
      weightKg: weightKg ?? this.weightKg,
      aiHealthScore: aiHealthScore ?? this.aiHealthScore,
      liveryColorHex: liveryColorHex ?? this.liveryColorHex,
    );
  }

  @override
  List<Object?> get props => [
        bikeId,
        make,
        model,
        year,
        engineCC,
        maxLeanAngleLimit,
        isPrimary,
        frontPsi,
        rearPsi,
        imageUrl,
        topSpeed,
        horsePower,
        weightKg,
        aiHealthScore,
        liveryColorHex,
      ];
}

class RiderEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String phone;
  final List<MotorcycleEntity> garage;
  final List<OrderAddressEntity> savedAddresses;

  const RiderEntity({
    required this.id,
    required this.email,
    required this.fullName,
    required this.phone,
    required this.garage,
    this.savedAddresses = const [],
  });

  @override
  List<Object?> get props => [id, email, fullName, phone, garage, savedAddresses];
}
