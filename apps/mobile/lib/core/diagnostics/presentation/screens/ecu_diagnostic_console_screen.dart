import 'package:flutter/material.dart';
import '../../../design_system/roados_tokens.dart';
import '../../models/diagnostic_types.dart';
import '../../models/dtc_record.dart';
import '../../models/pid_definition.dart';
import '../../services/ecu_diagnostic_manager.dart';

/// Phase 18: RoadOS Multi-ECU Diagnostic Console Screen.
class EcuDiagnosticConsoleScreen extends StatefulWidget {
  const EcuDiagnosticConsoleScreen({super.key});

  @override
  State<EcuDiagnosticConsoleScreen> createState() => _EcuDiagnosticConsoleScreenState();
}

class _EcuDiagnosticConsoleScreenState extends State<EcuDiagnosticConsoleScreen>
    with SingleTickerProviderStateMixin {
  final EcuDiagnosticManager _diagManager = EcuDiagnosticManager.instance;

  late TabController _tabController;
  bool _isScanning = false;
  bool _isClearing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Start live PID polling automatically in simulator/active mode
    _diagManager.startLiveTelemetryPolling();
  }

  @override
  void dispose() {
    _diagManager.stopLiveTelemetryPolling();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runFullScan() async {
    setState(() => _isScanning = true);
    await _diagManager.performFullEcuScan();
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _confirmClearDtcs() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: RoadOSColors.midnightNavy,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: RoadOSColors.warningAmber, size: 24),
            SizedBox(width: 10),
            Text('RESET DTC MEMORY?',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ],
        ),
        content: const Text(
          'This will execute an OBD-II Mode \$04 command to clear all confirmed and pending diagnostic trouble codes across all ECUs.\n\n'
          'SAFETY RULE: The vehicle must be completely stationary (Speed = 0 km/h).',
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('CANCEL', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: RoadOSColors.errorCrimson.withValues(alpha: 0.2),
              foregroundColor: RoadOSColors.errorCrimson,
              side: const BorderSide(color: RoadOSColors.errorCrimson, width: 0.5),
            ),
            child: const Text('CONFIRM CLEAR', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isClearing = true);
      try {
        await _diagManager.clearAllDiagnosticFaults(forceConfirmation: true);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('DTC memory successfully cleared across all ECUs.'),
              backgroundColor: RoadOSColors.apexEmerald,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to clear DTCs: $e'),
              backgroundColor: RoadOSColors.errorCrimson,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isClearing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoadOSColors.deepSpaceBlack,
      appBar: AppBar(
        backgroundColor: RoadOSColors.midnightNavy,
        title: const Text('MULTI-ECU DIAGNOSTICS',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              letterSpacing: 1.5,
              color: Colors.white,
            )),
        centerTitle: true,
        actions: [
          _buildProtocolBadge(),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: RoadOSColors.roadCyan,
          labelColor: RoadOSColors.roadCyan,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0),
          tabs: const [
            Tab(icon: Icon(Icons.hub_outlined, size: 18), text: 'ECU BUS'),
            Tab(icon: Icon(Icons.speed, size: 18), text: 'LIVE PIDS'),
            Tab(icon: Icon(Icons.bug_report_outlined, size: 18), text: 'FAULTS'),
            Tab(icon: Icon(Icons.terminal, size: 18), text: 'ISO-TP LOG'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildBusStatusBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildEcuBusTab(),
                _buildLivePidsTab(),
                _buildFaultsTab(),
                _buildIsoTpTerminalTab(),
              ],
            ),
          ),
          _buildControlFooter(),
        ],
      ),
    );
  }

  Widget _buildProtocolBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: RoadOSColors.roadCyan.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: RoadOSColors.roadCyan, width: 0.5),
      ),
      child: Text(
        _diagManager.activeProtocol.name.split('_').first.toUpperCase(),
        style: const TextStyle(color: RoadOSColors.roadCyan, fontSize: 9, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildBusStatusBar() {
    final faultCount = _diagManager.allActiveFaults.length;
    final activeModules = _diagManager.moduleResults.values.where((r) => r.isResponding).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: RoadOSColors.obsidianSurface,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: faultCount > 0 ? RoadOSColors.warningAmber : RoadOSColors.apexEmerald,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'DIAGNOSTIC BUS: ${_diagManager.sessionState.name.toUpperCase()}',
                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          Row(
            children: [
              Text('$activeModules ECUs ONLINE',
                  style: const TextStyle(color: RoadOSColors.roadCyan, fontSize: 10, fontWeight: FontWeight.w700)),
              const SizedBox(width: 8),
              Text('$faultCount DTCs',
                  style: TextStyle(
                    color: faultCount > 0 ? RoadOSColors.warningAmber : RoadOSColors.apexEmerald,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  )),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // Tab 1: Multi-ECU Bus Scanner
  // =========================================================================

  Widget _buildEcuBusTab() {
    const allModules = [
      EcuModule.engineControlModule_ECM,
      EcuModule.antiLockBraking_ABS,
      EcuModule.batteryManagementSystem_BMS,
      EcuModule.transmissionControlUnit_TCU,
      EcuModule.instrumentCluster_IPC,
      EcuModule.bodyControlModule_BCM,
      EcuModule.tractionControl_IMU,
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allModules.length,
      itemBuilder: (context, idx) {
        final module = allModules[idx];
        final result = _diagManager.moduleResults[module];
        final isOnline = result?.isResponding ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: RoadOSColors.cardSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isOnline
                  ? (result!.activeDtcCount > 0
                      ? RoadOSColors.warningAmber.withValues(alpha: 0.5)
                      : RoadOSColors.apexEmerald.withValues(alpha: 0.4))
                  : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isOnline ? RoadOSColors.roadCyan : Colors.white24).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isOnline ? Icons.memory : Icons.memory_outlined,
                  color: isOnline ? RoadOSColors.roadCyan : Colors.white30,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(module.displayName,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      'Address: ${module.hexAddress} (Resp: 0x${module.responseAddress.toRadixString(16).toUpperCase()})',
                      style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                    ),
                    if (result?.calibrationId != null) ...[
                      const SizedBox(height: 2),
                      Text('Calibration: ${result!.calibrationId}',
                          style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (isOnline ? RoadOSColors.apexEmerald : Colors.white12).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isOnline ? 'ONLINE' : 'OFFLINE',
                      style: TextStyle(
                        color: isOnline ? RoadOSColors.apexEmerald : Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (result != null && result.activeDtcCount > 0) ...[
                    const SizedBox(height: 4),
                    Text('${result.activeDtcCount} Faults',
                        style: const TextStyle(color: RoadOSColors.warningAmber, fontSize: 10, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================================
  // Tab 2: Live PIDs Dashboard
  // =========================================================================

  Widget _buildLivePidsTab() {
    return StreamBuilder<Map<int, DecodedPidMeasurement>>(
      stream: _diagManager.pidStream,
      initialData: _diagManager.latestPidValues,
      builder: (context, snapshot) {
        final pids = snapshot.data ?? {};

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.4,
          ),
          itemCount: DiagnosticPid.standardPids.length,
          itemBuilder: (context, idx) {
            final pid = DiagnosticPid.standardPids[idx];
            final measurement = pids[pid.pid];
            final val = measurement?.value;

            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RoadOSColors.cardSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(pid.code,
                          style: const TextStyle(color: RoadOSColors.roadCyan, fontSize: 10, fontFamily: 'monospace')),
                      Text(pid.category, style: const TextStyle(color: Colors.white38, fontSize: 9)),
                    ],
                  ),
                  Text(
                    val != null ? val.toStringAsFixed(1) : '--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          pid.name,
                          style: const TextStyle(color: Colors.white60, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(pid.unit, style: const TextStyle(color: RoadOSColors.hyperOrange, fontSize: 10, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // Tab 3: DTC Fault Diagnostic Center
  // =========================================================================

  Widget _buildFaultsTab() {
    return StreamBuilder<List<DiagnosticFaultRecord>>(
      stream: _diagManager.faultsStream,
      initialData: _diagManager.allActiveFaults,
      builder: (context, snapshot) {
        final faults = snapshot.data ?? [];

        if (faults.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, color: RoadOSColors.apexEmerald, size: 48),
                SizedBox(height: 12),
                Text('NO ACTIVE FAULT CODES',
                    style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
                SizedBox(height: 4),
                Text('All ECUs reporting nominal status. Tap SCAN to refresh.',
                    style: TextStyle(color: Colors.white38, fontSize: 11)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: faults.length,
          itemBuilder: (context, idx) {
            final fault = faults[idx];
            final severityColor = switch (fault.severity) {
              DtcSeverity.criticalStopEngine => RoadOSColors.errorCrimson,
              DtcSeverity.confirmedActive => RoadOSColors.warningAmber,
              DtcSeverity.pending => RoadOSColors.hyperOrange,
              _ => RoadOSColors.roadCyan,
            };

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: RoadOSColors.cardSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: severityColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(fault.code,
                              style: TextStyle(
                                  color: severityColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace')),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: severityColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(fault.severity.label,
                                style: TextStyle(color: severityColor, fontSize: 8, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      Text(fault.module.name.split('_').last,
                          style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(fault.title,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(fault.description,
                      style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.3)),
                  const Divider(color: Colors.white10, height: 16),
                  Text('Probable Cause: ${fault.probableCause}',
                      style: const TextStyle(color: Colors.white54, fontSize: 10)),
                  const SizedBox(height: 2),
                  Text('Remedy: ${fault.recommendedRemedy}',
                      style: const TextStyle(color: RoadOSColors.roadCyan, fontSize: 10, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // =========================================================================
  // Tab 4: ISO-TP & Terminal Transaction Log
  // =========================================================================

  Widget _buildIsoTpTerminalTab() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RoadOSColors.obsidianSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white10),
      ),
      child: const SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ISO 15765-2 / ISO 14229 RAW TRANSACTION LOG',
                style: TextStyle(color: RoadOSColors.roadCyan, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
            SizedBox(height: 8),
            Text('TX > 0x7E0: 02 01 00 AA AA AA AA AA [SF: Mode 01 PID 00 Supported PIDs]',
                style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
            Text('RX < 0x7E8: 06 41 00 BE 3F B8 13 AA [SF: Mode 41 PID 00 OK]',
                style: TextStyle(color: RoadOSColors.apexEmerald, fontSize: 10, fontFamily: 'monospace')),
            SizedBox(height: 4),
            Text('TX > 0x7E0: 02 09 02 AA AA AA AA AA [SF: Mode 09 PID 02 Request VIN]',
                style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
            Text('RX < 0x7E8: 10 14 49 02 01 4A 59 41 [FF: Mode 49 PID 02 len=20 bytes]',
                style: TextStyle(color: RoadOSColors.roadCyan, fontSize: 10, fontFamily: 'monospace')),
            Text('TX > 0x7E0: 30 00 00 AA AA AA AA AA [FC: ContinueToSend BS=0 STmin=0]',
                style: TextStyle(color: RoadOSColors.warningAmber, fontSize: 10, fontFamily: 'monospace')),
            Text('RX < 0x7E8: 21 52 4E 33 39 45 35 46 [CF: seq=1 "RN39E5F"]',
                style: TextStyle(color: RoadOSColors.roadCyan, fontSize: 10, fontFamily: 'monospace')),
            Text('RX < 0x7E8: 22 41 30 30 30 31 30 31 [CF: seq=2 "A000101"]',
                style: TextStyle(color: RoadOSColors.roadCyan, fontSize: 10, fontFamily: 'monospace')),
            SizedBox(height: 4),
            Text('TX > 0x7E0: 02 10 03 AA AA AA AA AA [UDS \$10: DiagnosticSessionControl Extended]',
                style: TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace')),
            Text('RX < 0x7E8: 06 50 03 00 32 01 F4 AA [UDS \$50: Positive Response P2=50ms P2*=5000ms]',
                style: TextStyle(color: RoadOSColors.apexEmerald, fontSize: 10, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // Control Footer
  // =========================================================================

  Widget _buildControlFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: RoadOSColors.midnightNavy,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
      ),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _isScanning ? null : _runFullScan,
              icon: _isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.radar, size: 18),
              label: Text(_isScanning ? 'SCANNING ECUs...' : 'SCAN ALL ECUS',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
              style: ElevatedButton.styleFrom(
                backgroundColor: RoadOSColors.roadCyan.withValues(alpha: 0.2),
                foregroundColor: RoadOSColors.roadCyan,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: RoadOSColors.roadCyan, width: 0.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _isClearing ? null : _confirmClearDtcs,
            icon: const Icon(Icons.delete_sweep_outlined, size: 18),
            label: const Text('CLEAR DTCs',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.0)),
            style: ElevatedButton.styleFrom(
              backgroundColor: RoadOSColors.errorCrimson.withValues(alpha: 0.2),
              foregroundColor: RoadOSColors.errorCrimson,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: const BorderSide(color: RoadOSColors.errorCrimson, width: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
