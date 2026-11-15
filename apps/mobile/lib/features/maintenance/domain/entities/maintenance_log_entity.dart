import 'package:equatable/equatable.dart';

/// Supported Maintenance Task Types matching backend taxonomy
class MaintenanceTaskTypes {
  static const String oilChange = 'OIL_CHANGE';
  static const String chainLube = 'CHAIN_LUBE';
  static const String chainTension = 'CHAIN_TENSION';
  static const String brakePads = 'BRAKE_PADS';
  static const String tireChange = 'TIRE_CHANGE';
  static const String sparkPlugs = 'SPARK_PLUGS';
  static const String valveClearance = 'VALVE_CLEARANCE';
  static const String generalInspection = 'GENERAL_INSPECTION';

  static const List<String> all = [
    oilChange,
    chainLube,
    chainTension,
    brakePads,
    tireChange,
    sparkPlugs,
    valveClearance,
    generalInspection,
  ];

  static String getDisplayName(String type) {
    switch (type) {
      case oilChange:
        return 'Engine Oil & Filter Change';
      case chainLube:
        return 'Drive Chain Clean & Lube';
      case chainTension:
        return 'Chain Tension & Alignment';
      case brakePads:
        return 'Brake Pads & Fluid Flush';
      case tireChange:
        return 'Tire Inspection & Replacement';
      case sparkPlugs:
        return 'Spark Plug Replacement';
      case valveClearance:
        return 'Valve Clearance Inspection';
      case generalInspection:
        return 'General Multipoint Inspection';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  static int getDefaultIntervalKm(String type) {
    switch (type) {
      case chainLube:
        return 500;
      case chainTension:
        return 1000;
      case oilChange:
        return 5000;
      case generalInspection:
        return 6000;
      case sparkPlugs:
        return 12000;
      case brakePads:
        return 15000;
      case tireChange:
        return 18000;
      case valveClearance:
        return 24000;
      default:
        return 5000;
    }
  }
}

/// Domain entity representing a completed or scheduled maintenance log
class MaintenanceLogEntity extends Equatable {
  final String id;
  final String bikeId;
  final String taskType;
  final int performedAtKm;
  final DateTime performedAtDate;
  final int nextDueKm;
  final DateTime? nextDueDate;
  final String notes;
  final bool isCompleted;
  final double? cost;
  final String? serviceProvider;

  const MaintenanceLogEntity({
    required this.id,
    required this.bikeId,
    required this.taskType,
    required this.performedAtKm,
    required this.performedAtDate,
    required this.nextDueKm,
    this.nextDueDate,
    this.notes = '',
    this.isCompleted = true,
    this.cost,
    this.serviceProvider,
  });

  MaintenanceLogEntity copyWith({
    String? id,
    String? bikeId,
    String? taskType,
    int? performedAtKm,
    DateTime? performedAtDate,
    int? nextDueKm,
    DateTime? nextDueDate,
    String? notes,
    bool? isCompleted,
    double? cost,
    String? serviceProvider,
  }) {
    return MaintenanceLogEntity(
      id: id ?? this.id,
      bikeId: bikeId ?? this.bikeId,
      taskType: taskType ?? this.taskType,
      performedAtKm: performedAtKm ?? this.performedAtKm,
      performedAtDate: performedAtDate ?? this.performedAtDate,
      nextDueKm: nextDueKm ?? this.nextDueKm,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
      cost: cost ?? this.cost,
      serviceProvider: serviceProvider ?? this.serviceProvider,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bikeId': bikeId,
      'taskType': taskType,
      'performedAtKm': performedAtKm,
      'performedAtDate': performedAtDate.toIso8601String(),
      'nextDueKm': nextDueKm,
      if (nextDueDate != null) 'nextDueDate': nextDueDate!.toIso8601String(),
      'notes': notes,
      'isCompleted': isCompleted,
      if (cost != null) 'cost': cost,
      if (serviceProvider != null) 'serviceProvider': serviceProvider,
    };
  }

  factory MaintenanceLogEntity.fromJson(Map<String, dynamic> json) {
    return MaintenanceLogEntity(
      id: json['id']?.toString() ?? '',
      bikeId: json['bikeId']?.toString() ?? '',
      taskType: json['taskType']?.toString() ?? MaintenanceTaskTypes.generalInspection,
      performedAtKm: (json['performedAtKm'] as num?)?.toInt() ?? 0,
      performedAtDate: json['performedAtDate'] != null
          ? DateTime.tryParse(json['performedAtDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      nextDueKm: (json['nextDueKm'] as num?)?.toInt() ?? 0,
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.tryParse(json['nextDueDate'].toString())
          : null,
      notes: json['notes']?.toString() ?? '',
      isCompleted: json['isCompleted'] as bool? ?? true,
      cost: (json['cost'] as num?)?.toDouble(),
      serviceProvider: json['serviceProvider']?.toString(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        bikeId,
        taskType,
        performedAtKm,
        performedAtDate,
        nextDueKm,
        nextDueDate,
        notes,
        isCompleted,
        cost,
        serviceProvider,
      ];
}

/// Urgency status for a scheduled maintenance task
enum MaintenanceScheduleStatus {
  optimal,
  dueSoon,
  dueNow,
  overdue,
  pendingOdometer,
}

/// Calculated upkeep reminder item based on odometer & intervals
class MaintenanceScheduleEntity extends Equatable {
  final String taskType;
  final String title;
  final int intervalKm;
  final int? lastPerformedKm;
  final DateTime? lastPerformedDate;
  final int currentOdometerKm;
  final int dueInKm;
  final MaintenanceScheduleStatus status;
  final String statusDetail;
  final String recommendation;

  const MaintenanceScheduleEntity({
    required this.taskType,
    required this.title,
    required this.intervalKm,
    this.lastPerformedKm,
    this.lastPerformedDate,
    required this.currentOdometerKm,
    required this.dueInKm,
    required this.status,
    required this.statusDetail,
    required this.recommendation,
  });

  double get progressRatio {
    if (intervalKm <= 0) return 0.0;
    if (lastPerformedKm != null) {
      final elapsed = currentOdometerKm - lastPerformedKm!;
      return (elapsed / intervalKm).clamp(0.0, 1.0);
    }
    return (currentOdometerKm / intervalKm).clamp(0.0, 1.0);
  }

  @override
  List<Object?> get props => [
        taskType,
        title,
        intervalKm,
        lastPerformedKm,
        lastPerformedDate,
        currentOdometerKm,
        dueInKm,
        status,
        statusDetail,
        recommendation,
      ];
}
