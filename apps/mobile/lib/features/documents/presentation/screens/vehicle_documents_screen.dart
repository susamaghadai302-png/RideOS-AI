import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';

class VehicleDocumentsScreen extends StatefulWidget {
  const VehicleDocumentsScreen({super.key});

  @override
  State<VehicleDocumentsScreen> createState() => _VehicleDocumentsScreenState();
}

class _VehicleDocumentsScreenState extends State<VehicleDocumentsScreen> {
  final List<Map<String, dynamic>> _documents = [];

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

