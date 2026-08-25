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
    final vehicles = [
      const VehicleProfile(
        vehicleId: 'veh_ducati_panigale_v4',
        make: 'Ducati',
        model: 'Panigale V4 S',
        year: 2024,
        vin: 'ZDM1234567890ABCD',
        currentOdometerKm: 14250.0,
        isPrimaryVehicle: true,
      ),
      const VehicleProfile(
        vehicleId: 'veh_bmw_r1250_gs',
        make: 'BMW',
        model: 'R 1250 GS Adventure',
        year: 2023,
        vin: 'WB1084900PZ998123',
        currentOdometerKm: 28400.0,
        isPrimaryVehicle: false,
      ),
    ];
    _garageStreamController.add(vehicles);
    return vehicles;
  }

  List<DigitalDocumentItem> fetchEncryptedDocumentVault({required String vehicleId}) {
    return const [
      DigitalDocumentItem(
        documentId: 'doc_ins_9981',
        title: 'Comprehensive Motorcycle Insurance Policy',
        documentType: 'Insurance',
        expiryDate: '2027-04-15',
        isEncryptedCloudBacked: true,
      ),
      DigitalDocumentItem(
        documentId: 'doc_puc_4412',
        title: 'Pollution Under Control (PUC) Certificate',
        documentType: 'PUC',
        expiryDate: '2026-11-20',
        isEncryptedCloudBacked: true,
      ),
    ];
  }

  void dispose() {
    _garageStreamController.close();
  }
}
