import 'package:flutter/foundation.dart';
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

  List<MaintenancePredictionItem> getPredictions({int? currentOdometerKm}) {
    final now = DateTime.now();
    final expiringDocs = VehicleDocumentVaultService().getExpiringDocuments(daysThreshold: 30);
    final List<MaintenancePredictionItem> list = [];

    // REAL DATA COMPLIANCE:
    // Predictive maintenance via AI/Telematics is currently unavailable without a backend
    // historical model. No synthetic data is injected.
    
    // If documents are expiring soon, add administrative maintenance alerts
    for (final doc in expiringDocs) {
      list.add(
        MaintenancePredictionItem(
          id: 'maint_doc_${doc.id}',
          title: 'Document Renewal: ${doc.title}',
          remainingLifePct: doc.daysUntilExpiry > 0 ? (doc.daysUntilExpiry / 365 * 100).clamp(0, 100) : 0.0,
          remainingKm: 0,
          statusText: 'Expires in ${doc.daysUntilExpiry} days',
          estimatedCostUsd: 0.0, // We cannot estimate renewal costs reliably
          nextDueDate: doc.expiryDate ?? now.add(const Duration(days: 15)),
          urgency: doc.daysUntilExpiry <= 7 ? MaintenanceUrgencyLevel.critical : MaintenanceUrgencyLevel.warning,
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
