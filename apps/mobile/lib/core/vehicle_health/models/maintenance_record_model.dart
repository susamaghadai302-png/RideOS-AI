class MaintenanceRecordModel {
  final String id;
  final String vehicleId;
  final String serviceType;
  final DateTime date;
  final double odometerKm;
  final bool isVehicleOdometer;
  final String notes;
  final double cost;
  final String serviceProvider;
  final List<String> attachments;
  final DateTime? nextDueDate;
  final double? nextDueOdometerKm;

  const MaintenanceRecordModel({
    required this.id,
    required this.vehicleId,
    required this.serviceType,
    required this.date,
    required this.odometerKm,
    this.isVehicleOdometer = true,
    this.notes = '',
    this.cost = 0.0,
    this.serviceProvider = '',
    this.attachments = const [],
    this.nextDueDate,
    this.nextDueOdometerKm,
  });

  String get odometerLabel => '${odometerKm.toStringAsFixed(0)} km (${isVehicleOdometer ? "VEHICLE" : "USER ENTERED"})';

  Map<String, dynamic> toJson() => {
    'id': id,
    'vehicleId': vehicleId,
    'serviceType': serviceType,
    'date': date.toIso8601String(),
    'odometerKm': odometerKm,
    'isVehicleOdometer': isVehicleOdometer,
    'notes': notes,
    'cost': cost,
    'serviceProvider': serviceProvider,
    'attachments': attachments,
    'nextDueDate': nextDueDate?.toIso8601String(),
    'nextDueOdometerKm': nextDueOdometerKm,
  };

  factory MaintenanceRecordModel.fromJson(Map<String, dynamic> json) => MaintenanceRecordModel(
    id: json['id'] as String,
    vehicleId: json['vehicleId'] as String,
    serviceType: json['serviceType'] as String,
    date: DateTime.parse(json['date'] as String),
    odometerKm: (json['odometerKm'] as num).toDouble(),
    isVehicleOdometer: json['isVehicleOdometer'] as bool? ?? true,
    notes: json['notes'] as String? ?? '',
    cost: (json['cost'] as num? ?? 0.0).toDouble(),
    serviceProvider: json['serviceProvider'] as String? ?? '',
    attachments: (json['attachments'] as List? ?? []).map((e) => e.toString()).toList(),
    nextDueDate: json['nextDueDate'] != null ? DateTime.parse(json['nextDueDate'] as String) : null,
    nextDueOdometerKm: json['nextDueOdometerKm'] != null ? (json['nextDueOdometerKm'] as num).toDouble() : null,
  );
}
