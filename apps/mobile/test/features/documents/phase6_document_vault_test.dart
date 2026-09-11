import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/documents/core/services/vehicle_document_vault_service.dart';
import 'package:rideos_mobile/features/documents/domain/entities/vehicle_document_entity.dart';

void main() {
  group('Phase 6 - Vehicle Document Vault Tests', () {
    late VehicleDocumentVaultService vaultService;

    setUp(() {
      vaultService = VehicleDocumentVaultService();
    });

    test('Initializes with empty document list', () {
      expect(vaultService.documents.isEmpty, isTrue);
    });

    test('Calculates expiring documents within 30-day threshold accurately', () {
      final now = DateTime.now();
      vaultService.addDocument(VehicleDocumentEntity(
        id: 'doc_expiring_01',
        title: 'Expiring Insurance',
        documentNumber: 'INS-001',
        category: DocumentCategory.insurancePolicy,
        expiryDate: now.add(const Duration(days: 15)),
        filePath: '/vault/encrypted/ins.pdf',
        uploadDate: now,
      ));

      final expiring = vaultService.getExpiringDocuments(daysThreshold: 30);
      expect(expiring.isNotEmpty, isTrue);
      expect(expiring.first.daysUntilExpiry, lessThanOrEqualTo(30));
      expect(expiring.first.daysUntilExpiry, greaterThanOrEqualTo(0));
      expect(expiring.first.status, equals(DocumentStatus.renewSoon));
    });

    test('Adds and removes encrypted documents seamlessly', () {
      final now = DateTime.now();
      final newDoc = VehicleDocumentEntity(
        id: 'doc_custom_01',
        title: 'Track Day Insurance Pass',
        documentNumber: 'TRK-9821- Laguna',
        category: DocumentCategory.insurancePolicy,
        expiryDate: now.add(const Duration(days: 90)),
        filePath: '/vault/encrypted/track_pass.pdf',
        uploadDate: now,
      );

      vaultService.addDocument(newDoc);
      expect(vaultService.documents.any((d) => d.id == 'doc_custom_01'), isTrue);

      vaultService.removeDocument('doc_custom_01');
      expect(vaultService.documents.any((d) => d.id == 'doc_custom_01'), isFalse);
    });
  });
}
