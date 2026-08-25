import 'package:flutter/material.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_capabilities/models/universal_protocol_detection_models.dart';

class UniversalCompatibilityReportScreen extends StatelessWidget {
  final DetailedCompatibilityBreakdown report;

  const UniversalCompatibilityReportScreen({
    super.key,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.verified_user_rounded, color: RoadOSColors.electricBlue, size: 20),
            SizedBox(width: 8),
            Text(
              'COMPATIBILITY REPORT',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: CinematicBackground(child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSummaryHeader(),
          const SizedBox(height: 16),
          _buildProtocolDetailsCard(),
          const SizedBox(height: 16),
          _buildCapabilityMatrixCard(),
          const SizedBox(height: 16),
          _buildExplanationCard(),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: RoadOSColors.electricBlue,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('PROCEED TO VEHICLE DASHBOARD', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ),
        ],
      )),
    );
  }

  Widget _buildSummaryHeader() {
    Color statusColor = RoadOSColors.electricBlue;
    if (report.overallStatus == CompatibilityReportStatus.supported) {
      statusColor = RoadOSColors.apexEmerald;
    } else if (report.overallStatus == CompatibilityReportStatus.protocolNotVerified) {
      statusColor = Colors.amber;
    } else if (report.overallStatus == CompatibilityReportStatus.unsupported) {
      statusColor = Colors.redAccent;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(report.manufacturer.toUpperCase(), style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  report.overallStatus.label,
                  style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('${report.modelName} (${report.variantTrim})', style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('${report.modelYear} | ${report.vehicleType.label} | ${(report.confidenceScore * 100).toInt()}% Confidence Match', style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildProtocolDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoadOSColors.borderTranslucent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('PROTOCOL & VERSIONING', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(report.protocolName, style: const TextStyle(color: RoadOSColors.electricBlue, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 4),
          Text('Profile Ver: ${report.versionMetadata.vehicleProfileVersion} | Supported Since: ${report.versionMetadata.supportedSinceYear}', style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildCapabilityMatrixCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoadOSColors.borderTranslucent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('CAPABILITY MATRIX', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _buildCapabilityRow('Turn-by-Turn Navigation HUD', report.hasTurnByTurnNav),
          _buildCapabilityRow('Speed Telemetry', report.hasSpeedTelemetry),
          _buildCapabilityRow('RPM Telemetry', report.hasRpmTelemetry),
          _buildCapabilityRow('Battery State-of-Charge (SoC)', report.hasBatterySoc),
          _buildCapabilityRow('OBD-II Diagnostics', report.hasObdDiagnostics),
          _buildCapabilityRow('Active Safety Command Lock', report.areActiveCommandsBlocked, isLock: true),
        ],
      ),
    );
  }

  Widget _buildCapabilityRow(String title, bool isAvailable, {bool isLock = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 12)),
          Row(
            children: [
              Icon(
                isAvailable ? (isLock ? Icons.lock_rounded : Icons.check_circle_rounded) : Icons.cancel_rounded,
                color: isAvailable ? (isLock ? Colors.amber : RoadOSColors.apexEmerald) : RoadOSColors.textMuted,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                isAvailable ? (isLock ? 'ACTIVE' : 'SUPPORTED') : 'UNSUPPORTED',
                style: TextStyle(
                  color: isAvailable ? (isLock ? Colors.amber : RoadOSColors.apexEmerald) : RoadOSColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExplanationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoadOSColors.borderTranslucent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('COMPATIBILITY BREAKDOWN & EXPLANATION', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            report.statusExplanation,
            style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
