import 'package:flutter/foundation.dart';

enum DocumentCategory {
  drivingLicense,
  registrationCertificate,
  insurancePolicy,
  emissionPuc,
  warrantyPass,
  serviceInvoice,
  other,
}

enum DocumentStatus {
  valid,
  renewSoon,
  expired,
  archived,
}

@immutable
class VehicleDocumentEntity {
  final String id;
  final String title;
  final String documentNumber;
  final DocumentCategory category;
  final DateTime? expiryDate;
  final String filePath;
  final bool isEncrypted;
  final DateTime uploadDate;

  const VehicleDocumentEntity({
    required this.id,
    required this.title,
    required this.documentNumber,
    required this.category,
    this.expiryDate,
    required this.filePath,
    this.isEncrypted = true,
    required this.uploadDate,
  });

  int get daysUntilExpiry {
    if (expiryDate == null) return 9999;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  DocumentStatus get status {
    if (expiryDate == null) return DocumentStatus.archived;
    final days = daysUntilExpiry;
    if (days < 0) return DocumentStatus.expired;
    if (days <= 30) return DocumentStatus.renewSoon;
    return DocumentStatus.valid;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'documentNumber': documentNumber,
      'category': category.name,
      'expiryDate': expiryDate?.toIso8601String(),
      'filePath': filePath,
      'isEncrypted': isEncrypted,
      'uploadDate': uploadDate.toIso8601String(),
    };
  }

  factory VehicleDocumentEntity.fromJson(Map<String, dynamic> json) {
    return VehicleDocumentEntity(
      id: json['id'] as String,
      title: json['title'] as String,
      documentNumber: json['documentNumber'] as String,
      category: DocumentCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => DocumentCategory.other,
      ),
      expiryDate: json['expiryDate'] != null ? DateTime.parse(json['expiryDate'] as String) : null,
      filePath: json['filePath'] as String,
      isEncrypted: json['isEncrypted'] as bool? ?? true,
      uploadDate: DateTime.parse(json['uploadDate'] as String),
    );
  }
}
