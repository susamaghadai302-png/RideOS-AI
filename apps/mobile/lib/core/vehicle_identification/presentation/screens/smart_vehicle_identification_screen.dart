import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/design_system/roados_tokens.dart';
import 'package:rideos_mobile/core/ecosystem/rideos_master_architecture.dart';
import 'package:rideos_mobile/core/vehicle_identification/models/universal_vehicle_profile.dart';
import 'package:rideos_mobile/core/vehicle_identification/models/vin_decoder_models.dart';
import 'package:rideos_mobile/core/vehicle_identification/services/smart_scan_orchestrator.dart';
import 'package:rideos_mobile/core/vehicle_identification/services/vin_identification_engine.dart';
import 'package:rideos_mobile/core/vehicle_identification/services/vin_ocr_scanner_engine.dart';

class SmartVehicleIdentificationScreen extends StatefulWidget {
  final SmartScanExecutionMode initialMode;

  const SmartVehicleIdentificationScreen({
    super.key,
    this.initialMode = SmartScanExecutionMode.realHardware,
  });

  @override
  State<SmartVehicleIdentificationScreen> createState() => _SmartVehicleIdentificationScreenState();
}

class _SmartVehicleIdentificationScreenState extends State<SmartVehicleIdentificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _vinInputController = TextEditingController(text: 'JYARN39E8FA000101');
  final TextEditingController _ocrTextController = TextEditingController();

  final SmartScanOrchestrator _orchestrator = SmartScanOrchestrator.instance;
  final VinIdentificationEngine _vinEngine = VinIdentificationEngine.instance;
  final VinOcrScannerEngine _ocrEngine = VinOcrScannerEngine.instance;

  SmartScanExecutionMode _currentExecutionMode = SmartScanExecutionMode.realHardware;
  final PhysicalTransportType _selectedTransport = PhysicalTransportType.bluetoothLowEnergy;

  bool _isScanning = false;
  UniversalVehicleProfile? _identifiedProfile;
  VinIdentificationResult? _vinResult;
  List<VinOcrCandidateMatch> _ocrMatches = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentExecutionMode = widget.initialMode;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _vinInputController.dispose();
    _ocrTextController.dispose();
    super.dispose();
  }

  Future<void> _runSmartScan([String? targetModel]) async {
    setState(() {
      _isScanning = true;
      _errorMessage = null;
      _identifiedProfile = null;
    });

    final profile = await _orchestrator.executeSmartScan(
      mode: _currentExecutionMode,
      preferredTransport: _selectedTransport,
    );

    setState(() {
      _isScanning = false;
      _identifiedProfile = profile;
    });
  }

  void _decodeManualVin() {
    final raw = _vinInputController.text.trim();
    final result = _vinEngine.decodeVin(raw);
    setState(() {
      _vinResult = result;
      if (result.isValid && result.decodedDetails != null) {
        final d = result.decodedDetails!;
        _identifiedProfile = UniversalVehicleProfile(
          vehicleId: 'veh_vin_${d.normalizedVin}',
          vin: d.normalizedVin,
          domain: d.domainType,
          manufacturer: d.manufacturer,
          model: result.resolvedVehicleModel ?? 'Model ${d.vds}',
          generation: 'Gen from VIN',
          year: d.modelYear,
          variant: 'Standard',
          propulsionType: PropulsionType.internalCombustion,
          engineOrMotorCode: 'OEM ENGINE',
          fuelType: FuelType.petrol98,
          transmission: TransmissionType.manual,
          displacementCc: 998,
          maxPowerHp: 200.0,
          maxTorqueNm: 113.3,
          tankOrBatteryCapacity: 17.0,
          ecuProfileId: 'ISO_15765_4',
          diagnosticProfileId: 'OBD2_STANDARD',
          supportedTransports: const [PhysicalTransportType.bluetoothLowEnergy, PhysicalTransportType.bluetoothClassicSpp],
          supportedProtocols: const [DiagnosticProtocolType.iso15765_4_Can_11bit_500k],
          capabilities: const UniversalVehicleCapabilities(),
          model3dAssetPath: 'assets/3d/generic_motorcycle.glb',
          identificationConfidence: result.confidenceScore >= 1.0
              ? UniversalIdentificationConfidence.exactVinMatch
              : UniversalIdentificationConfidence.partialMatch,
          identificationSource: IdentificationSource.vinManualInput,
          isVerified: true,
          identifiedAt: DateTime.now(),
        );
      }
    });
  }

  void _runOcrParse() {
    final text = _ocrTextController.text;
    final matches = _ocrEngine.parseOcrText(text);
    setState(() {
      _ocrMatches = matches;
      if (matches.isNotEmpty && matches.first.decodeResult.isValid) {
        final best = matches.first;
        final d = best.decodeResult.decodedDetails!;
        _identifiedProfile = UniversalVehicleProfile(
          vehicleId: 'veh_ocr_${best.candidateVin}',
          vin: best.candidateVin,
          domain: d.domainType,
          manufacturer: d.manufacturer,
          model: best.decodeResult.resolvedVehicleModel ?? 'Model ${d.vds}',
          generation: 'Gen from OCR',
          year: d.modelYear,
          variant: 'Standard',
          propulsionType: PropulsionType.internalCombustion,
          engineOrMotorCode: 'OEM ENGINE',
          fuelType: FuelType.petrol98,
          transmission: TransmissionType.manual,
          displacementCc: 998,
          maxPowerHp: 200.0,
          maxTorqueNm: 113.3,
          tankOrBatteryCapacity: 17.0,
          ecuProfileId: 'ISO_15765_4',
          diagnosticProfileId: 'OBD2_STANDARD',
          supportedTransports: const [PhysicalTransportType.bluetoothLowEnergy],
          supportedProtocols: const [DiagnosticProtocolType.iso15765_4_Can_11bit_500k],
          capabilities: const UniversalVehicleCapabilities(),
          model3dAssetPath: 'assets/3d/generic_motorcycle.glb',
          identificationConfidence: best.isExactChecksumVerified
              ? UniversalIdentificationConfidence.exactVinMatch
              : UniversalIdentificationConfidence.partialMatch,
          identificationSource: IdentificationSource.vinOcrScan,
          isVerified: true,
          identifiedAt: DateTime.now(),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoadOSColors.deepSpaceBlack,
      appBar: AppBar(
        backgroundColor: RoadOSColors.cardSurface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UNIVERSAL VEHICLE IDENTIFIER', style: RoadOSTypography.screenTitle.copyWith(fontSize: 16)),
            Text(
              'Phase 16 Engine • Multi-Domain Auto-Discovery',
              style: RoadOSTypography.caption(color: RoadOSColors.roadCyan),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: RoadOSColors.roadCyan,
          labelColor: RoadOSColors.roadCyan,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.bolt, size: 20), text: 'Smart Scan'),
            Tab(icon: Icon(Icons.pin, size: 20), text: 'VIN Decoder'),
            Tab(icon: Icon(Icons.camera_alt, size: 20), text: 'OCR Scanner'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: RoadOSColors.errorCrimson.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: RoadOSColors.errorCrimson),
                ),
                child: Text(_errorMessage!, style: const TextStyle(color: RoadOSColors.errorCrimson, fontSize: 11)),
              ),
            ],
            SizedBox(
              height: 230,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSmartScanTab(),
                  _buildVinDecoderTab(),
                  _buildOcrScannerTab(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_isScanning) _buildScanningProgress(),
            if (_identifiedProfile != null) _buildIdentifiedProfileCard(_identifiedProfile!),
          ],
        ),
      ),
    );
  }



  Widget _buildSmartScanTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Automated Diagnostic Gateway Scan', style: RoadOSTypography.cardTitle),
          const SizedBox(height: 6),
          Text(
            'Probes BLE GATT, Mode \$09 VIN, and reads ECU Calibration ID to resolve exact vehicle profile.',
            style: RoadOSTypography.caption(color: Colors.white70),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RoadOSColors.roadCyan,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _isScanning ? null : () => _runSmartScan('Yamaha'),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('SCAN (YAMAHA)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RoadOSColors.hyperOrange,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _isScanning ? null : () => _runSmartScan('Ducati'),
                  icon: const Icon(Icons.two_wheeler, size: 18),
                  label: const Text('SCAN (DUCATI)', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVinDecoderTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _vinInputController,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', letterSpacing: 2.0),
            decoration: InputDecoration(
              labelText: 'ENTER 17-CHARACTER VIN',
              labelStyle: const TextStyle(color: RoadOSColors.roadCyan, fontSize: 12),
              filled: true,
              fillColor: RoadOSColors.deepSpaceBlack,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: RoadOSColors.roadCyan,
              foregroundColor: Colors.black,
            ),
            onPressed: _decodeManualVin,
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('VALIDATE & DECODE VIN'),
          ),
          if (_vinResult != null && !_vinResult!.isValid) ...[
            const SizedBox(height: 6),
            Text(
              _vinResult!.unresolvedReason ?? 'Invalid VIN',
              style: const TextStyle(color: RoadOSColors.errorCrimson, fontSize: 11),
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildOcrScannerTab() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _ocrTextController,
            style: const TextStyle(color: Colors.white, fontSize: 12),
            decoration: InputDecoration(
              hintText: 'PASTE CAMERA OCR RECOGNIZED TEXT...',
              hintStyle: const TextStyle(color: Colors.white38, fontSize: 11),
              filled: true,
              fillColor: RoadOSColors.deepSpaceBlack,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: RoadOSColors.electricIndigo,
              foregroundColor: Colors.white,
            ),
            onPressed: _runOcrParse,
            icon: const Icon(Icons.document_scanner),
            label: const Text('PARSE OCR TEXT FOR VINS'),
          ),
          if (_ocrMatches.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('FOUND ${_ocrMatches.length} VIN CANDIDATES', style: const TextStyle(color: RoadOSColors.apexEmerald, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildScanningProgress() {
    return StreamBuilder<SmartScanProgressState>(
      stream: _orchestrator.stateStream,
      initialData: _orchestrator.currentState,
      builder: (context, snapshot) {
        final data = snapshot.data ?? _orchestrator.currentState;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RoadOSColors.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RoadOSColors.roadCyan.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(data.currentStep.stepTitle, style: RoadOSTypography.cardTitle.copyWith(fontSize: 12, color: RoadOSColors.roadCyan)),
                  Text('${(data.progressFraction * 100).toInt()}%', style: RoadOSTypography.caption(color: Colors.white)),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: data.progressFraction,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(RoadOSColors.roadCyan),
              ),
              if (data.queriedVin != null) ...[
                const SizedBox(height: 8),
                Text('MODE \$09 VIN: ${data.queriedVin}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
              ],
              if (data.queriedEcuCalId != null) ...[
                const SizedBox(height: 4),
                Text('ECU CAL ID: ${data.queriedEcuCalId}', style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace')),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildIdentifiedProfileCard(UniversalVehicleProfile profile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: RoadOSColors.apexEmerald, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: RoadOSColors.apexEmerald.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  profile.identificationConfidence.label,
                  style: const TextStyle(color: RoadOSColors.apexEmerald, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
              Text(
                profile.identificationSource.label,
                style: const TextStyle(color: Colors.white60, fontSize: 10, fontFamily: 'monospace'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${profile.manufacturer} ${profile.model}',
            style: RoadOSTypography.screenTitle.copyWith(fontSize: 20),
          ),
          Text(
            '${profile.year} • ${profile.variant} • ${profile.domain.label}',
            style: RoadOSTypography.caption(color: Colors.white70),
          ),
          const Divider(color: Colors.white12, height: 24),
          _buildSpecRow('VIN (ISO 3779)', profile.vin ?? 'N/A (Manual Selection)'),
          _buildSpecRow('Engine / Powertrain', '${profile.engineOrMotorCode} (${profile.maxPowerHp} HP / ${profile.maxTorqueNm} Nm)'),
          _buildSpecRow('Fuel / Transmission', '${profile.fuelType.name.toUpperCase()} • ${profile.transmission.name}'),
          _buildSpecRow('ECU Profile', profile.ecuProfileId),
          _buildSpecRow('Diagnostic Profile', profile.diagnosticProfileId),
          const SizedBox(height: 12),
          const Text('CAPABILITY PROFILE', style: TextStyle(color: RoadOSColors.roadCyan, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildCapabilityChip('DIAGNOSTICS', profile.capabilities.supportsDiagnostics),
              _buildCapabilityChip('LIVE TELEMETRY', profile.capabilities.supportsTelemetry),
              _buildCapabilityChip('NAVIGATION HUD', profile.capabilities.supportsNavigation),
              _buildCapabilityChip('CLUSTER PROJECTION', profile.capabilities.supportsScreenProjection),
              _buildCapabilityChip('HANDS-FREE CALLS', profile.capabilities.supportsCalling),
              _buildCapabilityChip('BLE GATT', profile.capabilities.supportsBLE),
              _buildCapabilityChip('ANDROID AUTO', profile.capabilities.supportsAndroidAuto),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityChip(String title, bool isSupported) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSupported ? RoadOSColors.roadCyan.withValues(alpha: 0.15) : Colors.white10,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isSupported ? RoadOSColors.roadCyan : Colors.white24,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSupported ? Icons.check_circle : Icons.cancel_outlined,
            size: 12,
            color: isSupported ? RoadOSColors.roadCyan : Colors.white38,
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              color: isSupported ? Colors.white : Colors.white38,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
