import '../../domain/entities/rider_entity.dart';
import '../../../orders/data/models/order_model.dart';

class MotorcycleModel extends MotorcycleEntity {
  const MotorcycleModel({
    required super.bikeId,
    required super.make,
    required super.model,
    required super.year,
    required super.engineCC,
    required super.maxLeanAngleLimit,
    required super.isPrimary,
    super.frontPsi,
    super.rearPsi,
    super.imageUrl,
    super.topSpeed,
    super.horsePower,
    super.weightKg,
    super.aiHealthScore,
    super.liveryColorHex,
  });

  factory MotorcycleModel.fromJson(Map<String, dynamic> json) {
    return MotorcycleModel(
      bikeId: json['bikeId'] ?? '',
      make: json['make'] ?? '',
      model: json['model'] ?? '',
      year: (json['year'] as num?)?.toInt() ?? 2024,
      engineCC: (json['engineCC'] as num?)?.toInt() ?? 600,
      maxLeanAngleLimit: (json['maxLeanAngleLimit'] as num?)?.toDouble() ?? 45.0,
      isPrimary: json['isPrimary'] ?? false,
      frontPsi: (json['frontPsi'] as num?)?.toDouble() ?? 36.0,
      rearPsi: (json['rearPsi'] as num?)?.toDouble() ?? 42.0,
      imageUrl: json['imageUrl'],
      topSpeed: json['topSpeed'] ?? '299 km/h',
      horsePower: json['horsePower'] ?? '200 HP',
      weightKg: json['weightKg'] ?? '198 kg',
      aiHealthScore: (json['aiHealthScore'] as num?)?.toDouble() ?? 98.0,
      liveryColorHex: json['liveryColorHex'] ?? 'FF5E00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bikeId': bikeId,
      'make': make,
      'model': model,
      'year': year,
      'engineCC': engineCC,
      'maxLeanAngleLimit': maxLeanAngleLimit,
      'isPrimary': isPrimary,
      'frontPsi': frontPsi,
      'rearPsi': rearPsi,
      'imageUrl': imageUrl,
      'topSpeed': topSpeed,
      'horsePower': horsePower,
      'weightKg': weightKg,
      'aiHealthScore': aiHealthScore,
      'liveryColorHex': liveryColorHex,
    };
  }
}

class RiderModel extends RiderEntity {
  const RiderModel({
    required super.id,
    required super.email,
    required super.fullName,
    required super.phone,
    required super.garage,
    super.savedAddresses,
  });

  factory RiderModel.fromJson(Map<String, dynamic> json) {
    return RiderModel(
      id: json['id'] ?? json['_id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      phone: json['phone'] ?? '',
      garage: json['garage'] != null
          ? (json['garage'] as List).map((b) => MotorcycleModel.fromJson(b)).toList()
          : [],
      savedAddresses: json['savedAddresses'] != null
          ? (json['savedAddresses'] as List).map((a) => OrderAddressModel.fromJson(a)).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'phone': phone,
      'garage': (garage as List<MotorcycleModel>).map((b) => b.toJson()).toList(),
      'savedAddresses': (savedAddresses as List<OrderAddressModel>).map((a) => a.toJson()).toList(),
    };
  }
}
