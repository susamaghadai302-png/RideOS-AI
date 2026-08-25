import 'package:flutter/material.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';

class VehicleDocumentsScreen extends StatefulWidget {
  const VehicleDocumentsScreen({super.key});

  @override
  State<VehicleDocumentsScreen> createState() => _VehicleDocumentsScreenState();
}

class _VehicleDocumentsScreenState extends State<VehicleDocumentsScreen> {
  final List<Map<String, dynamic>> _documents = [
    {
      'title': 'Driving License (DL)',
      'number': 'DL-9820-2024-CA',
      'category': 'License',
      'expiry': '2028-12-31',
      'daysLeft': 878,
      'status': 'Valid',
      'type': 'PDF / Scan',
    },
    {
      'title': 'Vehicle Insurance Policy',
      'number': 'Allianz Policy #8820-91A',
      'category': 'Insurance',
      'expiry': '2026-11-15',
      'daysLeft': 102,
      'status': 'Renew Soon',
      'type': 'PDF Document',
    },
    {
      'title': 'RC Book Registration',
      'number': 'CA-9201-R1M',
      'category': 'RC',
      'expiry': '2039-05-14',
      'daysLeft': 4664,
      'status': 'Valid',
      'type': 'Image Scan',
    },
    {
      'title': 'PUC Emission Certificate',
      'number': 'PUC-LEVEL1-982',
      'category': 'PUC',
      'expiry': '2026-10-01',
      'daysLeft': 57,
      'status': 'Renew Soon',
      'type': 'PDF Document',
    },
    {
      'title': 'Purchase Invoice',
      'number': 'INV-YAM-2024-091',
      'category': 'Invoice',
      'expiry': 'N/A (Lifetime)',
      'daysLeft': 9999,
      'status': 'Archived',
      'type': 'PDF Document',
    },
    {
      'title': 'Official Service Booklet',
      'number': 'SRV-BOOK-9982',
      'category': 'Service Book',
      'expiry': '2027-01-01',
      'daysLeft': 331,
      'status': 'Valid',
      'type': 'Digital History',
    },
    {
      'title': 'Factory Warranty Pass',
      'number': 'WAR-YAM-3YR-881',
      'category': 'Warranty',
      'expiry': '2027-05-14',
      'daysLeft': 464,
      'status': 'Valid',
      'type': 'PDF Document',
    },
  ];

  void _uploadDocument() {
    LuxAudioHapticsService.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: RoadOSColors.midnightNavy,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('UPLOAD VEHICLE DOCUMENT', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: RoadOSColors.hyperOrange)),
              const SizedBox(height: 8),
              const Text('Select document file type to encrypt and store in Cloud Vault', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 12)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: RoadOSColors.errorCrimson),
                title: const Text('Upload PDF File', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmUpload('PDF Document');
                },
              ),
              const Divider(height: 1, color: RoadOSColors.borderSubtle),
              ListTile(
                leading: const Icon(Icons.image_rounded, color: RoadOSColors.cyberCyan),
                title: const Text('Upload Image Scan (JPG / PNG)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmUpload('Image Scan');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmUpload(String fileType) {
    LuxAudioHapticsService.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Uploaded $fileType to Cloud Vault. Encrypted & Synced.'),
      backgroundColor: RoadOSColors.apexEmerald,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'VEHICLE DOCUMENTS & RENEWALS',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: RoadOSColors.hyperOrange),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.note_add_outlined, color: RoadOSColors.cyberCyan),
            onPressed: _uploadDocument,
          ),
        ],
      ),
      body: CinematicBackground(
        child: ListView(
          padding: EdgeInsets.only(left: 16, right: 16, bottom: 16, top: MediaQuery.of(context).padding.top + 56),
          children: [
              // Cloud Sync Status Banner Card
              RoadOSCard(
                borderColor: RoadOSColors.apexEmerald.withValues(alpha: 0.5),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: RoadOSColors.apexEmerald.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.cloud_done_rounded, color: RoadOSColors.apexEmerald, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VAULT ENCRYPTED & SYNCED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('All 7 documents backed up to RideOS Cloud Vault', style: TextStyle(color: RoadOSColors.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Documents List
              const Text('STORED DOCUMENTS & RENEWAL REMINDERS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: RoadOSColors.textMuted)),
              const SizedBox(height: 8),

              ..._documents.map((doc) {
                final isRenewSoon = doc['status'] == 'Renew Soon';
                final statusColor = isRenewSoon ? RoadOSColors.hyperOrange : RoadOSColors.apexEmerald;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: RoadOSCard(
                    borderColor: statusColor.withValues(alpha: 0.3),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(doc['title'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                doc['status'],
                                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(doc['number'], style: const TextStyle(color: RoadOSColors.cyberCyan, fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Expiry Date: ${doc['expiry']}', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                            Text(doc['type'], style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11)),
                          ],
                        ),
                        if (isRenewSoon) ...[
                          const SizedBox(height: 10),
                          RoadOSButton(
                            label: 'RENEW NOW (${doc['daysLeft']} DAYS LEFT)',
                            icon: Icons.alarm_rounded,
                            gradient: RoadOSGradients.primaryViolet,
                            onPressed: () {
                              LuxAudioHapticsService.selectionClick();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('Initiated renewal reminder flow for ${doc['title']}'),
                                backgroundColor: RoadOSColors.hyperOrange,
                              ));
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
      ),
    );
  }
}

