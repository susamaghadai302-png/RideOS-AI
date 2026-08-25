import 'package:flutter/foundation.dart';
import '../../../../core/vehicle_health/models/maintenance_record_model.dart';
import '../../../documents/core/services/vehicle_document_vault_service.dart';

enum MaintenanceUrgencyLevel {
  info,
  upcoming,
  warning,
  critical,
}

@immutable
class MaintenancePredictionItem {
  final String id;
  final String title;
  final double remainingLifePct;
  final int remainingKm;
  final String statusText;
  final double estimatedCostUsd;
  final DateTime nextDueDate;
  final MaintenanceUrgencyLevel urgency;
  final String reasoning;

  const MaintenancePredictionItem({
    required this.id,
    required this.title,
    required this.remainingLifePct,
    required this.remainingKm,
    required this.statusText,
    required this.estimatedCostUsd,
    required this.nextDueDate,
    this.urgency = MaintenanceUrgencyLevel.info,
    required this.reasoning,
  });

  bool get isUrgent =>
      urgency == MaintenanceUrgencyLevel.warning || urgency == MaintenanceUrgencyLevel.critical;
}

class PredictiveMaintenanceEngine {
  static final PredictiveMaintenanceEngine _instance = PredictiveMaintenanceEngine._internal();
  factory PredictiveMaintenanceEngine() => _instance;
  PredictiveMaintenanceEngine._internal();

  List<MaintenancePredictionItem> getPredictions({int currentOdometerKm = 12450}) {
    final now = DateTime.now();
    final expiringDocs = VehicleDocumentVaultService().getExpiringDocuments(daysThreshold: 30);

    final List<MaintenancePredictionItem> list = [
      MaintenancePredictionItem(
        id: 'maint_oil_01',
        title: 'Engine Oil & Filter Service',
        remainingLifePct: 82.0,
        remainingKm: 4100,
        statusText: 'Optimal viscosity & filtration',
        estimatedCostUsd: 65.0,
        nextDueDate: now.add(const Duration(days: 90)),
        urgency: MaintenanceUrgencyLevel.info,
        reasoning: 'Oil degradation model indicates 4,100 km remaining based on average operating RPM.',
      ),
      MaintenancePredictionItem(
        id: 'maint_chain_01',
        title: 'Drive Chain Lube & Tension',
        remainingLifePct: 35.0,
        remainingKm: 350,
        statusText: 'Lubrication interval approaching',
        estimatedCostUsd: 25.0,
        nextDueDate: now.add(const Duration(days: 7)),
        urgency: MaintenanceUrgencyLevel.upcoming,
        reasoning: 'O-ring drive chains require cleaning and lubrication every 500 km.',
      ),
      MaintenancePredictionItem(
        id: 'maint_brakes_01',
        title: 'Brembo Sintered Brake Pads',
        remainingLifePct: 68.0,
        remainingKm: 2800,
        statusText: 'Pad thickness nominal (4.2mm)',
        estimatedCostUsd: 110.0,
        nextDueDate: now.add(const Duration(days: 60)),
        urgency: MaintenanceUrgencyLevel.info,
        reasoning: 'Braking G-force telemetry indicates even pad wear across front twin discs.',
      ),
      MaintenancePredictionItem(
        id: 'maint_battery_01',
        title: '12V AGM Battery Cell Check',
        remainingLifePct: 92.0,
        remainingKm: 12000,
        statusText: 'Cold cranking amps nominal',
        estimatedCostUsd: 140.0,
        nextDueDate: now.add(const Duration(days: 240)),
        urgency: MaintenanceUrgencyLevel.info,
        reasoning: 'Resting bus voltage stable at 12.8V with consistent charging curve.',
      ),
      MaintenancePredictionItem(
        id: 'maint_coolant_01',
        title: 'Radiator Coolant Flush',
        remainingLifePct: 79.0,
        remainingKm: 5100,
        statusText: 'Ethylene glycol boiling protection nominal',
        estimatedCostUsd: 35.0,
        nextDueDate: now.add(const Duration(days: 100)),
        urgency: MaintenanceUrgencyLevel.info,
        reasoning: 'Cooling efficiency within factory thermal dispersion specifications.',
      ),
    ];

    // If documents are expiring soon, add administrative maintenance alerts
    for (final doc in expiringDocs) {
      list.add(
        MaintenancePredictionItem(
          id: 'maint_doc_${doc.id}',
          title: 'Document Renewal: ${doc.title}',
          remainingLifePct: 15.0,
          remainingKm: 0,
          statusText: 'Expires in ${doc.daysUntilExpiry} days',
          estimatedCostUsd: 40.0,
          nextDueDate: doc.expiryDate ?? now.add(const Duration(days: 15)),
          urgency: MaintenanceUrgencyLevel.warning,
          reasoning: 'Official ${doc.category.name} renewal required to maintain legal road compliance.',
        ),
      );
    }

    return list;
  }

  double calculateTotalEstimatedCost() {
    final predictions = getPredictions();
    return predictions.fold(0.0, (acc, item) => acc + item.estimatedCostUsd);
  }
}
