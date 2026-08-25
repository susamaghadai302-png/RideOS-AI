enum DigitalTwinQuality {
  low('LOW', 'Fast Web / Mobile Tier (15k Polys)', 15000),
  medium('MEDIUM', 'Balanced Real-Time Tier (45k Polys)', 45000),
  high('HIGH', 'Showroom Studio Tier (120k Polys)', 120000),
  ultra('ULTRA', 'Photorealistic Precision Tier (350k Polys)', 350000);

  final String code;
  final String description;
  final int targetTriangles;
  const DigitalTwinQuality(this.code, this.description, this.targetTriangles);

  static DigitalTwinQuality fromString(String val) {
    return DigitalTwinQuality.values.firstWhere(
      (q) => q.code.toUpperCase() == val.toUpperCase(),
      orElse: () => DigitalTwinQuality.high,
    );
  }
}

class DigitalTwinMeshStats {
  final int polygonCount;
  final int vertexCount;
  final double lengthMeters;
  final double widthMeters;
  final double heightMeters;
  final bool isGroundAligned;
  final bool isManifold;
  final int textureResolution;

  const DigitalTwinMeshStats({
    required this.polygonCount,
    required this.vertexCount,
    required this.lengthMeters,
    required this.widthMeters,
    required this.heightMeters,
    this.isGroundAligned = true,
    this.isManifold = true,
    this.textureResolution = 2048,
  });

  Map<String, dynamic> toJson() => {
    'polygonCount': polygonCount,
    'vertexCount': vertexCount,
    'lengthMeters': lengthMeters,
    'widthMeters': widthMeters,
    'heightMeters': heightMeters,
    'isGroundAligned': isGroundAligned,
    'isManifold': isManifold,
    'textureResolution': textureResolution,
  };

  factory DigitalTwinMeshStats.fromJson(Map<String, dynamic> json) => DigitalTwinMeshStats(
    polygonCount: json['polygonCount'] ?? 50000,
    vertexCount: json['vertexCount'] ?? 30000,
    lengthMeters: (json['lengthMeters'] ?? 2.05).toDouble(),
    widthMeters: (json['widthMeters'] ?? 0.82).toDouble(),
    heightMeters: (json['heightMeters'] ?? 1.15).toDouble(),
    isGroundAligned: json['isGroundAligned'] ?? true,
    isManifold: json['isManifold'] ?? true,
    textureResolution: json['textureResolution'] ?? 2048,
  );
}

class DigitalTwinModel {
  final String twinId; // vt_...
  final String vehicleId;
  final String manufacturer;
  final String model;
  final String variant;
  final int year;
  final String category;
  final String modelGlbPath; // Path or Blob URL
  final String thumbnailUrl;
  final DigitalTwinQuality quality;
  final double scanCoveragePercent; // 0.0 to 100.0
  final DateTime scanDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version; // 1, 2, 3...
  final String versionTag; // "v1.0", "v2.0"...
  final int sourceImageCount;
  final DigitalTwinMeshStats meshStats;
  final List<Map<String, dynamic>> componentHotspots;
  final String source; // 'OEM_CAD', 'USER_PHOTOGRAMMETRY', 'AR_SCAN'
  final String license; // 'OEM_LICENSED', 'USER_PRIVATE'
  final String verificationStatus; // 'VERIFIED_OEM', 'USER_VERIFIED', 'PENDING'
  final bool isPrimary;
  final bool isCloudSynced;
  final bool sourcePhotosPurged;

  const DigitalTwinModel({
    required this.twinId,
    required this.vehicleId,
    required this.manufacturer,
    required this.model,
    this.variant = '',
    required this.year,
    required this.category,
    required this.modelGlbPath,
    required this.thumbnailUrl,
    this.quality = DigitalTwinQuality.high,
    required this.scanCoveragePercent,
    required this.scanDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.version = 1,
    this.versionTag = 'v1.0',
    required this.sourceImageCount,
    required this.meshStats,
    this.componentHotspots = const [],
    this.source = 'USER_PHOTOGRAMMETRY',
    this.license = 'USER_PRIVATE',
    this.verificationStatus = 'USER_VERIFIED',
    this.isPrimary = true,
    this.isCloudSynced = false,
    this.sourcePhotosPurged = false,
  }) : createdAt = createdAt ?? scanDate,
       updatedAt = updatedAt ?? scanDate;

  DigitalTwinModel copyWith({
    String? twinId,
    String? vehicleId,
    String? manufacturer,
    String? model,
    String? variant,
    int? year,
    String? category,
    String? modelGlbPath,
    String? thumbnailUrl,
    DigitalTwinQuality? quality,
    double? scanCoveragePercent,
    DateTime? scanDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    String? versionTag,
    int? sourceImageCount,
    DigitalTwinMeshStats? meshStats,
    List<Map<String, dynamic>>? componentHotspots,
    String? source,
    String? license,
    String? verificationStatus,
    bool? isPrimary,
    bool? isCloudSynced,
    bool? sourcePhotosPurged,
  }) {
    return DigitalTwinModel(
      twinId: twinId ?? this.twinId,
      vehicleId: vehicleId ?? this.vehicleId,
      manufacturer: manufacturer ?? this.manufacturer,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      year: year ?? this.year,
      category: category ?? this.category,
      modelGlbPath: modelGlbPath ?? this.modelGlbPath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      quality: quality ?? this.quality,
      scanCoveragePercent: scanCoveragePercent ?? this.scanCoveragePercent,
      scanDate: scanDate ?? this.scanDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      versionTag: versionTag ?? this.versionTag,
      sourceImageCount: sourceImageCount ?? this.sourceImageCount,
      meshStats: meshStats ?? this.meshStats,
      componentHotspots: componentHotspots ?? this.componentHotspots,
      source: source ?? this.source,
      license: license ?? this.license,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isPrimary: isPrimary ?? this.isPrimary,
      isCloudSynced: isCloudSynced ?? this.isCloudSynced,
      sourcePhotosPurged: sourcePhotosPurged ?? this.sourcePhotosPurged,
    );
  }

  Map<String, dynamic> toJson() => {
    'twinId': twinId,
    'vehicleId': vehicleId,
    'manufacturer': manufacturer,
    'model': model,
    'variant': variant,
    'year': year,
    'category': category,
    'modelGlbPath': modelGlbPath,
    'thumbnailUrl': thumbnailUrl,
    'quality': quality.code,
    'scanCoveragePercent': scanCoveragePercent,
    'scanDate': scanDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'version': version,
    'versionTag': versionTag,
    'sourceImageCount': sourceImageCount,
    'meshStats': meshStats.toJson(),
    'componentHotspots': componentHotspots,
    'source': source,
    'license': license,
    'verificationStatus': verificationStatus,
    'isPrimary': isPrimary,
    'isCloudSynced': isCloudSynced,
    'sourcePhotosPurged': sourcePhotosPurged,
  };

  factory DigitalTwinModel.fromJson(Map<String, dynamic> json) => DigitalTwinModel(
    twinId: json['twinId'] ?? 'vt_${DateTime.now().millisecondsSinceEpoch}',
    vehicleId: json['vehicleId'] ?? '',
    manufacturer: json['manufacturer'] ?? '',
    model: json['model'] ?? '',
    variant: json['variant'] ?? '',
    year: json['year'] ?? 2024,
    category: json['category'] ?? 'Motorcycle',
    modelGlbPath: json['modelGlbPath'] ?? '',
    thumbnailUrl: json['thumbnailUrl'] ?? '',
    quality: DigitalTwinQuality.fromString(json['quality'] ?? 'HIGH'),
    scanCoveragePercent: (json['scanCoveragePercent'] ?? 100.0).toDouble(),
    scanDate: DateTime.tryParse(json['scanDate'] ?? '') ?? DateTime.now(),
    createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
    version: json['version'] ?? 1,
    versionTag: json['versionTag'] ?? 'v1.0',
    sourceImageCount: json['sourceImageCount'] ?? 18,
    meshStats: DigitalTwinMeshStats.fromJson(json['meshStats'] ?? {}),
    componentHotspots: List<Map<String, dynamic>>.from(json['componentHotspots'] ?? []),
    source: json['source'] ?? 'USER_PHOTOGRAMMETRY',
    license: json['license'] ?? 'USER_PRIVATE',
    verificationStatus: json['verificationStatus'] ?? 'USER_VERIFIED',
    isPrimary: json['isPrimary'] ?? true,
    isCloudSynced: json['isCloudSynced'] ?? false,
    sourcePhotosPurged: json['sourcePhotosPurged'] ?? false,
  );
}
