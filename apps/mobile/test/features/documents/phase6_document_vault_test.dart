import 'package:flutter_test/flutter_test.dart';
import 'package:rideos_mobile/features/documents/core/services/vehicle_document_vault_service.dart';
import 'package:rideos_mobile/features/documents/domain/entities/vehicle_document_entity.dart';

void main() {
  group('Phase 6 - Vehicle Document Vault Tests', () {
    late VehicleDocumentVaultService vaultService;

    setUp(() {
      vaultService = VehicleDocumentVaultService();
    });

    test('Initializes with default required motorcycle documents', () {
      expect(vaultService.documents.isNotEmpty, isTrue);
      expect(vaultService.documents.any((d) => d.category == DocumentCategory.drivingLicense), isTrue);
      expect(vaultService.documents.any((d) => d.category == DocumentCategory.registrationCertificate), isTrue);
      expect(vaultService.documents.any((d) => d.category == DocumentCategory.insurancePolicy), isTrue);
    });

    test('Calculates expiring documents within 30-day threshold accurately', () {
      final expiring = vaultService.getExpiringDocuments(daysThreshold: 30);
      expect(expiring.isNotEmpty, isTrue);
      for (final doc in expiring) {
        expect(doc.daysUntilExpiry, lessThanOrEqualTo(30));
        expect(doc.daysUntilExpiry, greaterThanOrEqualTo(0));
        expect(doc.status, equals(DocumentStatus.renewSoon));
      }
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
