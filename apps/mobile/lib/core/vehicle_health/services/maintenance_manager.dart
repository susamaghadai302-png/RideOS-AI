import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../bluetooth/bluetooth_engine.dart';
import '../../vehicle_resolution/models/vehicle_profile.dart';
import '../models/maintenance_record_model.dart';

final maintenanceRecordsProvider =
    StateNotifierProvider<MaintenanceNotifier, List<MaintenanceRecordModel>>(
        (ref) {
  return MaintenanceNotifier();
});

class MaintenanceNotifier extends StateNotifier<List<MaintenanceRecordModel>> {
  MaintenanceNotifier() : super([]);

  void setRecords(List<MaintenanceRecordModel> records) {
    state = records;
  }

  void addRecord(MaintenanceRecordModel record) {
    state = [record, ...state];
  }
}

enum ServiceStatus {
  ok('OK'),
  dueSoon('Due Soon'),
  dueNow('Due Now'),
  overdue('Overdue'),
  insufficientData('Insufficient Data'),
  unknown('Interval Not Specified');

  final String label;
  const ServiceStatus(this.label);
}

class ServiceScheduleItem {
  final String serviceType;
  final String title;
  final int intervalKm;
  final int intervalMonths;
  final double? lastPerformedKm;
  final DateTime? lastPerformedDate;
  final double currentOdometerKm;
  final bool isVehicleOdometer;
  final ServiceStatus status;
  final String statusDetail;
  final String explanation;
  final bool isGenericEstimate;

  const ServiceScheduleItem({
    required this.serviceType,
    required this.title,
    required this.intervalKm,
    required this.intervalMonths,
    this.lastPerformedKm,
    this.lastPerformedDate,
    required this.currentOdometerKm,
    required this.isVehicleOdometer,
    required this.status,
    required this.statusDetail,
    required this.explanation,
    this.isGenericEstimate = true,
  });
}

class MaintenanceManager {
  static final MaintenanceManager _instance = MaintenanceManager._internal();
  factory MaintenanceManager() => _instance;
  MaintenanceManager._internal();

  WidgetRef? _ref;
  final List<MaintenanceRecordModel> _records = [];
  List<MaintenanceRecordModel> get records => List.unmodifiable(_records);

  double? _vehicleOdometerKm;
  double _userOdometerKm = 0.0;

  double get currentOdometer => _vehicleOdometerKm ?? _userOdometerKm;
  bool get isVehicleOdometer => _vehicleOdometerKm != null;

  void initialize(WidgetRef ref) {
    _ref = ref;
    _loadLocalRecords();
    _listenToTelemetry();
  }

  void setUserOdometer(double km) {
    _userOdometerKm = km;
  }

  void _listenToTelemetry() {
    BluetoothEngine().telemetryStream.listen((telemetry) {
      if (telemetry.odometer.available &&
          telemetry.odometer.value != null &&
          telemetry.odometer.value! > 0) {
        _vehicleOdometerKm = telemetry.odometer.value!;
      }
    });
  }

  Future<void> addServiceRecord(MaintenanceRecordModel record) async {
    _records.insert(0, record);
    _ref?.read(maintenanceRecordsProvider.notifier).addRecord(record);
    await _saveLocalRecords();
  }

  /// Calculates upcoming maintenance tasks strictly from verified vehicle profile intervals or defaults
  List<ServiceScheduleItem> getSchedule(VehicleProfile? profile) {
    final bool hasProfileIntervals =
        profile?.maintenanceIntervals.isNotEmpty == true;
    final Map<String, dynamic> intervals = hasProfileIntervals
        ? profile!.maintenanceIntervals
        : {
            'engine_oil': {
              'km': 5000,
              'months': 6,
              'description': 'Engine Oil & Filter Change'
            },
            'chain_lube': {
              'km': 500,
              'months': 1,
              'description': 'Drive Chain Clean & Lubricate'
            },
            'brake_fluid': {
              'km': 20000,
              'months': 24,
              'description': 'Brake Fluid Flush'
            },
            'spark_plugs': {
              'km': 15000,
              'months': 24,
              'description': 'Spark Plug Replacement'
            },
            'coolant': {
              'km': 30000,
              'months': 36,
              'description': 'Engine Coolant Flush'
            },
            'tyre_inspection': {
              'km': 1000,
              'months': 1,
              'description': 'Tyre Pressure & Tread Inspection'
            },
            'air_filter': {
              'km': 10000,
              'months': 12,
              'description': 'Air Filter Inspection/Replacement'
            },
          };

    final List<ServiceScheduleItem> items = [];
    final currentOdo = currentOdometer;
    final now = DateTime.now();

    for (final entry in intervals.entries) {
      final key = entry.key;
      final data = entry.value as Map<String, dynamic>;
      final title = data['description']?.toString() ?? key;
      final int intKm = (data['km'] as num?)?.toInt() ?? 5000;
      final int intMonths = (data['months'] as num?)?.toInt() ?? 12;

      // Find last service record for this type
      final lastRec = _records
          .where((r) => r.serviceType.toLowerCase() == key.toLowerCase())
          .firstOrNull;

      final lastKm = lastRec?.odometerKm;
      final lastDate = lastRec?.date;

      ServiceStatus status = ServiceStatus.ok;
      String detail = '';
      String explanation = '';

      if (currentOdo <= 0) {
        status = ServiceStatus.insufficientData;
        detail = 'Waiting for Odometer';
        explanation =
            'Cannot predict service because the vehicle odometer is unavailable or zero. Please connect to the vehicle or enter it manually.';
      } else {
        // If no record exists, we assume it's due from 0 km.
        final kmSinceService = currentOdo - (lastKm ?? 0.0);
        final kmUntilDue = intKm - kmSinceService;

        int monthsSinceService = 0;
        int monthsUntilDue = intMonths;
        if (lastDate != null) {
          monthsSinceService = (now.difference(lastDate).inDays / 30).floor();
          monthsUntilDue = intMonths - monthsSinceService;
        }

        if (kmUntilDue < -50 || monthsUntilDue < 0) {
          status = ServiceStatus.overdue;
          if (kmUntilDue < -50) {
            detail = 'Overdue by ${(-kmUntilDue).toStringAsFixed(0)} km';
            explanation =
                'Exceeded the recommended distance interval of $intKm km.';
          } else {
            detail = 'Overdue by ${(-monthsUntilDue)} months';
            explanation =
                'Exceeded the recommended time interval of $intMonths months.';
          }
        } else if (kmUntilDue <= 0 || monthsUntilDue == 0) {
          status = ServiceStatus.dueNow;
          detail = 'Due Now';
          explanation =
              'Service is required immediately based on distance or time.';
        } else if (kmUntilDue <= 500 || monthsUntilDue <= 1) {
          status = ServiceStatus.dueSoon;
          if (kmUntilDue <= 500) {
            detail = 'Due in ${kmUntilDue.toStringAsFixed(0)} km';
            explanation = 'Approaching distance limit of $intKm km.';
          } else {
            detail = 'Due in 1 month';
            explanation = 'Approaching time limit of $intMonths months.';
          }
        } else {
          status = ServiceStatus.ok;
          detail =
              'Due in ${kmUntilDue.toStringAsFixed(0)} km / $monthsUntilDue mo';
          explanation = 'Service is up to date.';
        }
      }

      if (!hasProfileIntervals) {
        explanation +=
            ' (Note: These are generic estimates. Check manufacturer manual.)';
      }

      items.add(
        ServiceScheduleItem(
          serviceType: key,
          title: title,
          intervalKm: intKm,
          intervalMonths: intMonths,
          lastPerformedKm: lastKm,
          lastPerformedDate: lastDate,
          currentOdometerKm: currentOdo,
          isVehicleOdometer: isVehicleOdometer,
          status: status,
          statusDetail: detail,
          explanation: explanation.trim(),
          isGenericEstimate: !hasProfileIntervals,
        ),
      );
    }

    return items;
  }

  Future<void> _saveLocalRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _records.map((r) => jsonEncode(r.toJson())).toList();
      await prefs.setStringList('local_maintenance_records', list);
    } catch (e) {
      debugPrint('[MaintenanceManager] Save error: $e');
    }
  }

  Future<void> _loadLocalRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('local_maintenance_records') ?? [];
      _records.clear();
      for (final item in list) {
        _records.add(MaintenanceRecordModel.fromJson(
            jsonDecode(item) as Map<String, dynamic>));
      }
      _ref?.read(maintenanceRecordsProvider.notifier).setRecords(_records);
    } catch (e) {
      debugPrint('[MaintenanceManager] Load error: $e');
    }
  }
}
