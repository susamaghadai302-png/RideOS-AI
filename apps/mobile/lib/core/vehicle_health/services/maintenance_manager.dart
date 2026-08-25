import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../bluetooth/bluetooth_engine.dart';
import '../../vehicle_resolution/models/vehicle_profile.dart';
import '../models/maintenance_record_model.dart';

final maintenanceRecordsProvider = StateNotifierProvider<MaintenanceNotifier, List<MaintenanceRecordModel>>((ref) {
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
  overdue('Overdue'),
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
      if (telemetry.odometer.available && telemetry.odometer.value != null && telemetry.odometer.value! > 0) {
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
    final Map<String, dynamic> intervals = profile?.maintenanceIntervals.isNotEmpty == true
        ? profile!.maintenanceIntervals
        : {
            'engine_oil': {'km': 5000, 'months': 6, 'description': 'Engine Oil & Filter Change'},
            'chain_lube': {'km': 500, 'months': 1, 'description': 'Drive Chain Clean & Lubricate'},
            'brake_fluid': {'km': 20000, 'months': 24, 'description': 'Brake Fluid Flush'},
            'spark_plugs': {'km': 15000, 'months': 24, 'description': 'Spark Plug Replacement'},
            'coolant': {'km': 30000, 'months': 36, 'description': 'Engine Coolant Flush'},
          };

    final List<ServiceScheduleItem> items = [];
    final currentOdo = currentOdometer;

    for (final entry in intervals.entries) {
      final key = entry.key;
      final data = entry.value as Map<String, dynamic>;
      final title = data['description']?.toString() ?? key;
      final int intKm = (data['km'] as num?)?.toInt() ?? 5000;
      final int intMonths = (data['months'] as num?)?.toInt() ?? 12;

      // Find last service record for this type
      final lastRec = _records.where((r) => r.serviceType.toLowerCase() == key.toLowerCase()).firstOrNull;

      final lastKm = lastRec?.odometerKm ?? 0.0;
      final lastDate = lastRec?.date;

      final kmSinceService = currentOdo - lastKm;
      final kmUntilDue = intKm - kmSinceService;

      ServiceStatus status = ServiceStatus.ok;
      String detail = 'Due in ${kmUntilDue.toStringAsFixed(0)} km';

      if (kmUntilDue <= 0) {
        status = ServiceStatus.overdue;
        detail = 'Overdue by ${(-kmUntilDue).toStringAsFixed(0)} km';
      } else if (kmUntilDue <= 500) {
        status = ServiceStatus.dueSoon;
        detail = 'Due in ${kmUntilDue.toStringAsFixed(0)} km';
      }

      items.add(
        ServiceScheduleItem(
          serviceType: key,
          title: title,
          intervalKm: intKm,
          intervalMonths: intMonths,
          lastPerformedKm: lastRec != null ? lastKm : null,
          lastPerformedDate: lastDate,
          currentOdometerKm: currentOdo,
          isVehicleOdometer: isVehicleOdometer,
          status: status,
          statusDetail: detail,
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
        _records.add(MaintenanceRecordModel.fromJson(jsonDecode(item) as Map<String, dynamic>));
      }
      _ref?.read(maintenanceRecordsProvider.notifier).setRecords(_records);
    } catch (e) {
      debugPrint('[MaintenanceManager] Load error: $e');
    }
  }
}
