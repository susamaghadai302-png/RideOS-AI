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
    final now = DateTime.now();
    _documents.addAll([
      VehicleDocumentEntity(
        id: 'doc_dl_01',
        title: 'Driver License (Motorcycle Endorsement)',
        documentNumber: 'DL-9820-2024-CA',
        category: DocumentCategory.drivingLicense,
        expiryDate: now.add(const Duration(days: 720)),
        filePath: '/vault/encrypted/license.pdf',
        uploadDate: now.subtract(const Duration(days: 30)),
      ),
      VehicleDocumentEntity(
        id: 'doc_rc_01',
        title: 'Vehicle Registration Certificate (RC)',
        documentNumber: 'CA-9201-R1M',
        category: DocumentCategory.registrationCertificate,
        expiryDate: now.add(const Duration(days: 1800)),
        filePath: '/vault/encrypted/rc_book.pdf',
        uploadDate: now.subtract(const Duration(days: 30)),
      ),
      VehicleDocumentEntity(
        id: 'doc_ins_01',
        title: 'Comprehensive Superbike Insurance',
        documentNumber: 'POL-ALLIANZ-8820',
        category: DocumentCategory.insurancePolicy,
        expiryDate: now.add(const Duration(days: 25)), // Renew soon (<30 days)
        filePath: '/vault/encrypted/insurance.pdf',
        uploadDate: now.subtract(const Duration(days: 340)),
      ),
      VehicleDocumentEntity(
        id: 'doc_puc_01',
        title: 'PUC Emission Compliance Pass',
        documentNumber: 'PUC-LEVEL1-982',
        category: DocumentCategory.emissionPuc,
        expiryDate: now.add(const Duration(days: 15)), // Renew soon (<30 days)
        filePath: '/vault/encrypted/puc.pdf',
        uploadDate: now.subtract(const Duration(days: 165)),
      ),
    ]);
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
