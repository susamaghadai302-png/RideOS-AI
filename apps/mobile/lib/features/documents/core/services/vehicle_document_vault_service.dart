import 'dart:async';
import '../../domain/entities/vehicle_document_entity.dart';

class VehicleDocumentVaultService {
  static final VehicleDocumentVaultService _instance = VehicleDocumentVaultService._internal();
  factory VehicleDocumentVaultService() => _instance;
  VehicleDocumentVaultService._internal() {
    _initializeDefaultDocuments();
  }

  final List<VehicleDocumentEntity> _documents = [];
  final StreamController<List<VehicleDocumentEntity>> _vaultStreamController =
      StreamController<List<VehicleDocumentEntity>>.broadcast();

  Stream<List<VehicleDocumentEntity>> get vaultStream => _vaultStreamController.stream;
  List<VehicleDocumentEntity> get documents => List.unmodifiable(_documents);

  void _initializeDefaultDocuments() {
    // Left empty for production. Documents must be explicitly uploaded.
  }

  void addDocument(VehicleDocumentEntity doc) {
    _documents.insert(0, doc);
    _vaultStreamController.add(List.unmodifiable(_documents));
  }

  void removeDocument(String documentId) {
    _documents.removeWhere((d) => d.id == documentId);
    _vaultStreamController.add(List.unmodifiable(_documents));
  }

  List<VehicleDocumentEntity> getExpiringDocuments({int daysThreshold = 30}) {
    return _documents.where((d) => d.daysUntilExpiry <= daysThreshold && d.daysUntilExpiry >= 0).toList();
  }

  List<VehicleDocumentEntity> getDocumentsByCategory(DocumentCategory category) {
    return _documents.where((d) => d.category == category).toList();
  }

  void clearVault() {
    _documents.clear();
    _vaultStreamController.add(const []);
  }

  void dispose() {
    _vaultStreamController.close();
  }
}
