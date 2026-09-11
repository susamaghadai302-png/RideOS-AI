import 'dart:async';
import 'dart:developer' as developer;

class VehicleProfile {
  final String vehicleId;
  final String make;
  final String model;
  final int year;
  final String vin;
  final double currentOdometerKm;
  final bool isPrimaryVehicle;

  const VehicleProfile({
    required this.vehicleId,
    required this.make,
    required this.model,
    required this.year,
    required this.vin,
    required this.currentOdometerKm,
    required this.isPrimaryVehicle,
  });
}

class DigitalDocumentItem {
  final String documentId;
  final String title;
  final String documentType;
  final String expiryDate;
  final bool isEncryptedCloudBacked;

  const DigitalDocumentItem({
    required this.documentId,
    required this.title,
    required this.documentType,
    required this.expiryDate,
    required this.isEncryptedCloudBacked,
  });
}

class ProductionGaragePlatformEngine {
  static final ProductionGaragePlatformEngine instance = ProductionGaragePlatformEngine._internal();
  ProductionGaragePlatformEngine._internal();

  final _garageStreamController = StreamController<List<VehicleProfile>>.broadcast();

  Stream<List<VehicleProfile>> get garageStream => _garageStreamController.stream;

  List<VehicleProfile> fetchRiderGarageVehicles() {
    developer.log('Fetching Rider Digital Garage Vehicles...', name: 'RideOS.GarageEngine');
    final List<VehicleProfile> vehicles = [];
    _garageStreamController.add(vehicles);
    return vehicles;
  }

  List<DigitalDocumentItem> fetchEncryptedDocumentVault({required String vehicleId}) {
    return [];
  }

  void dispose() {
    _garageStreamController.close();
  }
}
