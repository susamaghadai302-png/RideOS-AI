import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../../../core/services/lux_haptics_audio_service.dart';
import '../../../../core/widgets/cinematic_background.dart';
import '../../../../core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_catalog/models/vehicle_catalog_models.dart';
import '../../../../core/vehicle_catalog/services/universal_vehicle_catalog_service.dart';
import '../../../../core/vehicle_connectivity/models/vehicle_capabilities.dart';
import '../../../../core/vehicle_connectivity/models/vehicle_variant_taxonomy.dart';
import '../../../../core/vehicle_verification_lab/models/verification_lab_models.dart';
import '../../../../core/vehicle_verification_lab/services/vehicle_connection_lab_service.dart';

class VehicleConnectionLabScreen extends StatefulWidget {
  final UniversalVehicleProfile? initialProfile;
  const VehicleConnectionLabScreen({super.key, this.initialProfile});

  @override
  State<VehicleConnectionLabScreen> createState() => _VehicleConnectionLabScreenState();
}

class _VehicleConnectionLabScreenState extends State<VehicleConnectionLabScreen> {
  final _catalogService = UniversalVehicleCatalogService();
  final _labService = VehicleConnectionLabService();

  UniversalVehicleProfile? _selectedProfile;
  VehicleConnectivityType _selectedMethod = VehicleConnectivityType.ble;
  bool _isSimulatedBenchMode = false;
  bool _isRunningTest = false;
  ProtocolVerificationReport? _activeReport;

  @override
  void initState() {
    super.initState();
    _selectedProfile = widget.initialProfile ?? _catalogService.allProfiles.first;
    if (_selectedProfile != null && _selectedProfile!.connectivity.supportedMethods.isNotEmpty) {
      _selectedMethod = _selectedProfile!.connectivity.supportedMethods.first;
    }
  }

  void _runVerification() async {
    if (_selectedProfile == null) return;
    setState(() {
      _isRunningTest = true;
      _activeReport = null;
    });

    // Simulate real hardware diagnostics delay for pipeline execution
    await Future.delayed(const Duration(milliseconds: 600));

    final report = await _labService.runVerificationPipeline(
      profile: _selectedProfile!,
      selectedMethod: _selectedMethod,
      isSimulatedBenchMode: _isSimulatedBenchMode,
    );

    if (mounted) {
      setState(() {
        _activeReport = report;
        _isRunningTest = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'VEHICLE CONNECTION LAB',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
        ),
        centerTitle: true,
      ),
      body: CinematicBackground(child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildLabIntroductionBanner(),
          const SizedBox(height: 16),
          _buildVehicleAndMethodSelector(),
          const SizedBox(height: 16),
          _buildBenchModeToggle(),
          const SizedBox(height: 20),
          _buildRunTestButton(),
          if (_isRunningTest) ...[
            const SizedBox(height: 32),
            _buildTestingIndicator(),
          ],
          if (_activeReport != null) ...[
            const SizedBox(height: 24),
            _buildVerificationReportCard(_activeReport!),
          ],
        ],
      )),
    );
  }

  Widget _buildLabIntroductionBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RoadOSColors.electricBlue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.biotech_rounded, color: RoadOSColors.electricBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'PROTOCOL VERIFICATION LAB',
                style: TextStyle(color: RoadOSColors.electricBlue, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.5),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Live hardware & bench-testing diagnostic suite. Discovers GATT services, verifies telemetry packet stability, measures round-trip latency, and validates technical evidence before certifying vehicle profiles.',
            style: TextStyle(color: RoadOSColors.textSecondary, fontSize: 12, height: 1.4),
          ),
          if (kIsWeb) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Browser Sandbox: Web Chrome runs bench testing mode. Real hardware BLE requires native Android/iOS app.',
                      style: TextStyle(color: Colors.amber, fontSize: 10),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVehicleAndMethodSelector() {
    final profiles = _catalogService.allProfiles;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '1. TARGET VEHICLE PROFILE',
            style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<UniversalVehicleProfile>(
            dropdownColor: RoadOSColors.cardSurface,
            initialValue: _selectedProfile,
            style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.black,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: RoadOSColors.borderTranslucent)),
            ),
            items: profiles.map((p) => DropdownMenuItem(value: p, child: Text(p.fullName, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (p) {
              if (p != null) {
                setState(() {
                  _selectedProfile = p;
                  if (p.connectivity.supportedMethods.isNotEmpty) {
                    _selectedMethod = p.connectivity.supportedMethods.first;
                  }
                });
              }
            },
          ),
          const SizedBox(height: 16),
          const Text(
            '2. CONNECTION TRANSPORT METHOD',
            style: TextStyle(color: RoadOSColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          if (_selectedProfile != null)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedProfile!.connectivity.supportedMethods.map((m) {
                final isSelected = _selectedMethod == m;
                return ChoiceChip(
                  label: Text(m.name.toUpperCase(), style: TextStyle(color: isSelected ? Colors.white : RoadOSColors.textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                  selected: isSelected,
                  selectedColor: RoadOSColors.electricBlue,
                  backgroundColor: Colors.black,
                  onSelected: (_) => setState(() => _selectedMethod = m),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: isSelected ? RoadOSColors.electricBlue : RoadOSColors.borderTranslucent)),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildBenchModeToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.precision_manufacturing_rounded, color: RoadOSColors.neonViolet, size: 20),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Automated Bench Loopback Test', style: TextStyle(color: RoadOSColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  Text('Simulate verified hardware response packet loop', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
                ],
              ),
            ],
          ),
          Switch(
            value: _isSimulatedBenchMode,
            activeThumbColor: RoadOSColors.neonViolet,
            onChanged: (val) => setState(() => _isSimulatedBenchMode = val),
          ),
        ],
      ),
    );
  }

  Widget _buildRunTestButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.play_arrow_rounded),
        label: const Text('RUN PROTOCOL VERIFICATION PIPELINE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        style: ElevatedButton.styleFrom(
          backgroundColor: RoadOSColors.electricBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: _isRunningTest ? null : _runVerification,
      ),
    );
  }

  Widget _buildTestingIndicator() {
    return const Column(
      children: [
        CircularProgressIndicator(color: RoadOSColors.electricBlue),
        SizedBox(height: 16),
        Text('Scanning GATT Services & Measuring Round-Trip Latency...', style: TextStyle(color: RoadOSColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildVerificationReportCard(ProtocolVerificationReport report) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF080C1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getGradeColor(report.verificationGrade).withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(report.vehicleFullName, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('Protocol: ${report.detectedProtocolName} (${report.connectionMethod.name.toUpperCase()})',
                        style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              _buildGradeBadge(report.verificationGrade),
            ],
          ),
          const Divider(color: RoadOSColors.borderTranslucent, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricTile('SCORE', '${report.overallScorePercentage}%', Icons.verified_rounded, RoadOSColors.apexEmerald),
              _buildMetricTile('LATENCY', '${report.qualityMetrics.latencyMs}ms', Icons.speed_rounded, RoadOSColors.electricBlue),
              _buildMetricTile('SIGNAL', '${report.qualityMetrics.signalStrengthRssi} dBm', Icons.wifi_tethering_rounded, RoadOSColors.warningAmber),
              _buildMetricTile('PACKETS', '${report.qualityMetrics.packetSuccessRatePct}%', Icons.check_circle_outline_rounded, RoadOSColors.neonViolet),
            ],
          ),
          const Divider(color: RoadOSColors.borderTranslucent, height: 24),
          const Text('DISCOVERED GATT SERVICES & CHARACTERISTICS', style: TextStyle(color: RoadOSColors.electricBlue, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ...report.discoveredServices.map((s) => _buildServiceTile(s)),
          const Divider(color: RoadOSColors.borderTranslucent, height: 24),
          const Text('CAPABILITY EVIDENCE AUDIT', style: TextStyle(color: RoadOSColors.electricBlue, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          const SizedBox(height: 8),
          ...report.capabilityAudits.map((a) => _buildCapabilityAuditTile(a)),
          const SizedBox(height: 16),
          if (report.requiresExternalGateway) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cable_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Required Gateway: ${report.gatewayRequiredDescription ?? "Standard CAN/OBD Diagnostic Interface"}',
                      style: const TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.bookmark_added_rounded, size: 16),
              label: const Text('SAVE LAB REPORT & CERTIFY PROFILE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: RoadOSColors.apexEmerald,
                side: const BorderSide(color: RoadOSColors.apexEmerald),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
        LuxAudioHapticsService.lightImpact();
                showLuxSnack(context, 'Saved Verification Report ${report.reportId} to Vehicle Catalog', variant: LuxSnackVariant.info);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, letterSpacing: 0.5)),
      ],
    );
  }

  Widget _buildServiceTile(DiscoveredGattServiceInfo s) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1A2035)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.serviceName, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          Text('UUID: ${s.uuid}', style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9)),
          const SizedBox(height: 6),
          ...s.characteristics.map((c) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_right_rounded, color: RoadOSColors.electricBlue, size: 14),
                    Expanded(child: Text('${c.name} (${c.canRead ? "R" : ""}${c.canWrite ? "W" : ""}${c.canNotify ? "N" : ""})', style: const TextStyle(color: RoadOSColors.textSecondary, fontSize: 11))),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCapabilityAuditTile(CapabilityDetectionAuditItem a) {
    final isSupp = a.detectedLevel == CapabilitySupportLevel.supported || a.detectedLevel == CapabilitySupportLevel.readOnly || a.detectedLevel == CapabilitySupportLevel.readWrite;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.capabilityName, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(a.technicalEvidence, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 10)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: (isSupp ? RoadOSColors.apexEmerald : RoadOSColors.textMuted).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              a.dataSource,
              style: TextStyle(color: isSupp ? RoadOSColors.apexEmerald : RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Color _getGradeColor(HardwareVerificationGrade grade) {
    switch (grade) {
      case HardwareVerificationGrade.realHardwareVerified:
        return RoadOSColors.apexEmerald;
      case HardwareVerificationGrade.automatedBenchVerified:
        return RoadOSColors.electricBlue;
      case HardwareVerificationGrade.requiresPhysicalHardware:
        return RoadOSColors.warningAmber;
      default:
        return RoadOSColors.textMuted;
    }
  }

  Widget _buildGradeBadge(HardwareVerificationGrade grade) {
    Color color = _getGradeColor(grade);
    String label;
    switch (grade) {
      case HardwareVerificationGrade.realHardwareVerified:
        label = 'REAL HARDWARE VERIFIED';
        break;
      case HardwareVerificationGrade.automatedBenchVerified:
        label = 'AUTOMATED BENCH TESTED';
        break;
      case HardwareVerificationGrade.requiresPhysicalHardware:
        label = 'REQUIRES PHYSICAL HARDWARE';
        break;
      default:
        label = 'UNVERIFIED';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
    );
  }
}
