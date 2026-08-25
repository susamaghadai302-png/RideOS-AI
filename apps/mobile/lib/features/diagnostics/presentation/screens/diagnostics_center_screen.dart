import 'dart:convert';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard, RoadOSThemeEngine;

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/theme_engine.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/bluetooth/bluetooth_engine.dart';
import '../../../../core/vehicle_commands/services/vehicle_command_pipeline.dart';
import '../../../../core/vehicle_commands/models/vehicle_command_log.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  DIAGNOSTICS CENTER SCREEN — Luxury upgrade
//  All original logic (telemetry subscription, packet rate, export, command
//  logs, live terminal) fully preserved.
// ─────────────────────────────────────────────────────────────────────────────

class DiagnosticsCenterScreen extends ConsumerStatefulWidget {
  const DiagnosticsCenterScreen({super.key});
  @override
  ConsumerState<DiagnosticsCenterScreen> createState() => _DiagnosticsCenterScreenState();
}

class _DiagnosticsCenterScreenState extends ConsumerState<DiagnosticsCenterScreen>
    with SingleTickerProviderStateMixin {

  // ── Original state ──────────────────────────────────────────────────────
  int _packetCount = 0;
  DateTime? _lastPacketTime;
  double _packetRateHz = 0.0;
  final List<String> _diagnosticLogs = [];

  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _subscribeToTelemetry();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Original logic ──────────────────────────────────────────────────────
  void _subscribeToTelemetry() {
    final engine = BluetoothEngine();
    engine.telemetryStream.listen((telemetry) {
      if (mounted) {
        setState(() {
          _packetCount++;
          final now = DateTime.now();
          if (_lastPacketTime != null) {
            final diffMs = now.difference(_lastPacketTime!).inMilliseconds;
            if (diffMs > 0) _packetRateHz = 1000.0 / diffMs;
          }
          _lastPacketTime = now;
          final logEntry =
              '[${now.toIso8601String().substring(11, 19)}] PKT #$_packetCount: '
              'Speed=${telemetry.speed.available ? "${telemetry.speed.value} km/h" : "N/A"}, '
              'RPM=${telemetry.rpm.available ? telemetry.rpm.value : "N/A"}, '
              'Latency=${telemetry.speed.latencyMs}ms';
          _diagnosticLogs.insert(0, logEntry);
          if (_diagnosticLogs.length > 50) _diagnosticLogs.removeLast();
        });
      }
    });
  }

  void _exportDiagnostics() {
    final state       = ref.read(bluetoothStateProvider);
    final commandLogs = ref.read(vehicleCommandLogProvider);
    final engine      = BluetoothEngine();
    final device      = engine.connectionManager.connectedDevice;

    final report = {
      'exportTimestamp': DateTime.now().toIso8601String(),
      'connectionState': state.name,
      'device': {'name': device?.advName ?? 'None', 'remoteId': device?.remoteId.str ?? 'N/A'},
      'activeAdapter': engine.currentAdapter?.adapterId ?? 'None',
      'statistics': {
        'totalPacketsReceived': _packetCount,
        'packetRateHz': _packetRateHz.toStringAsFixed(1),
        'lastPacketTimestamp': _lastPacketTime?.toIso8601String() ?? 'N/A',
      },
      'recentCommandLogs': commandLogs.map((e) => e.toJson()).toList(),
      'recentPacketLogs': _diagnosticLogs,
    };

    Clipboard.setData(ClipboardData(text: const JsonEncoder.withIndent('  ').convert(report)));
    HapticFeedback.mediumImpact();
    showLuxSnack(context, 'Diagnostic report copied to clipboard (JSON)', variant: LuxSnackVariant.success);
  }

  // ── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final state       = ref.watch(bluetoothStateProvider);
    final commandLogs = ref.watch(vehicleCommandLogProvider);
    final engine      = BluetoothEngine();
    final device      = engine.connectionManager.connectedDevice;
    final adapter     = engine.currentAdapter;
    final isDark      = LuxThemeEngine().isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF000000) : const Color(0xFFF4F6FA),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 56, left: 20, right: 20, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ShaderMask(
                        shaderCallback: (b) => const LinearGradient(
                          colors: [Color(0xFF00F2FE), Color(0xFF0066FF)],
                        ).createShader(b),
                        child: Text('DIAGNOSTICS CENTER',
                            style: GoogleFonts.outfit(
                              color: Colors.white, fontSize: 18,
                              fontWeight: FontWeight.w900, letterSpacing: 1,
                            )),
                      ),
                      const SizedBox(height: 3),
                      Text('REAL-TIME PROTOCOL BUS & GATT INSPECTION',
                          style: GoogleFonts.robotoMono(
                            color: const Color(0xFF64748B),
                            fontSize: 9.5, fontWeight: FontWeight.w700, letterSpacing: 1,
                          )),
                    ]),
                  ),
                  _LuxPressBtn(
                    label: 'EXPORT',
                    icon: Icons.download_rounded,
                    accentColor: const Color(0xFF00F2FE),
                    onTap: _exportDiagnostics,
                  ),
                ],
              ),
            ),
          ),

          // ── KPI cards ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(children: [
                Expanded(child: _buildKpiCard('STATUS', state.name.toUpperCase(),
                    state.isStreaming ? const Color(0xFF00E676) : const Color(0xFF64748B), Icons.sensors_rounded, isDark)),
                const SizedBox(width: 10),
                Expanded(child: _buildKpiCard('PACKET RATE', '${_packetRateHz.toStringAsFixed(1)} Hz',
                    const Color(0xFF00F2FE), Icons.speed_rounded, isDark)),
                const SizedBox(width: 10),
                Expanded(child: _buildKpiCard('COMMANDS', '${commandLogs.length}',
                    const Color(0xFF8A2BE2), Icons.terminal_rounded, isDark)),
              ]),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Hardware & Protocol config card ──────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: RoadOSCard(
                padding: const EdgeInsets.all(20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('HARDWARE & PROTOCOL LINK',
                      style: GoogleFonts.robotoMono(color: const Color(0xFF00F2FE), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                  const SizedBox(height: 14),
                  _buildConfigRow('Connected Device', device?.advName ?? '—', isDark),
                  const SizedBox(height: 8),
                  _buildConfigRow('Remote MAC', device?.remoteId.str ?? '—', isDark),
                  const SizedBox(height: 8),
                  _buildConfigRow('Active Adapter', adapter?.adapterId ?? 'None', isDark),
                  const SizedBox(height: 8),
                  _buildConfigRow('Total Packets', '$_packetCount', isDark),
                  const SizedBox(height: 8),
                  _buildConfigRow('Last Packet', _lastPacketTime != null
                      ? _lastPacketTime!.toIso8601String().substring(11, 19)
                      : 'N/A', isDark),
                ]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Command log ──────────────────────────────────────────────────
          if (commandLogs.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: RoadOSCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('COMMAND LOG (LAST ${commandLogs.take(5).length})',
                        style: GoogleFonts.robotoMono(color: const Color(0xFF8A2BE2), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 14),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: commandLogs.take(5).length,
                      separatorBuilder: (_, __) => Divider(
                        color: Colors.white.withValues(alpha: 0.06), height: 16,
                      ),
                      itemBuilder: (_, i) {
                        final log = commandLogs[i];
                        final isSuccess = log.status.name == 'success';
                        final statusColor = isSuccess ? const Color(0xFF00E676) : const Color(0xFFFF3B5C);
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(log.commandType.name.toUpperCase(),
                                  style: GoogleFonts.outfit(color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      fontWeight: FontWeight.w800, fontSize: 12)),
                              Text(log.message,
                                  style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 10)),
                            ]),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
                              ),
                              child: Text('${log.status.name.toUpperCase()} (${log.latencyMs}ms)',
                                  style: GoogleFonts.robotoMono(color: statusColor, fontSize: 9, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        );
                      },
                    ),
                  ]),
                ),
              ),
            ),

          if (commandLogs.isNotEmpty) const SliverToBoxAdapter(child: SizedBox(height: 20)),

          // ── Live packet terminal ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF00E676).withValues(alpha: 0.20)),
                  boxShadow: [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.06), blurRadius: 20)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Row(children: [
                        AnimatedBuilder(
                          animation: _pulseCtrl,
                          builder: (_, __) => Container(
                            width: 8, height: 8, margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF00E676),
                              boxShadow: [BoxShadow(
                                color: const Color(0xFF00E676).withValues(alpha: 0.5 + _pulseCtrl.value * 0.4),
                                blurRadius: 8,
                              )],
                            ),
                          ),
                        ),
                        Text('LIVE PACKET LOG',
                            style: GoogleFonts.robotoMono(color: const Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      ]),
                      Text('${_diagnosticLogs.length} SAMPLES',
                          style: GoogleFonts.robotoMono(color: const Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: _diagnosticLogs.isEmpty
                        ? Center(child: Text(
                            'Awaiting live incoming vehicle packets…\n(Connect a real BLE or OBD device to begin stream capture)',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12, height: 1.5)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            physics: const BouncingScrollPhysics(),
                            itemCount: _diagnosticLogs.length,
                            itemBuilder: (_, i) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(_diagnosticLogs[i],
                                  style: GoogleFonts.robotoMono(color: const Color(0xFF94A3B8), fontSize: 10.5)),
                            ),
                          ),
                  ),
                ]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String label, String value, Color valueColor, IconData icon, bool isDark) {
    return RoadOSCard(
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: GoogleFonts.robotoMono(color: const Color(0xFF64748B), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
          Icon(icon, color: valueColor.withValues(alpha: 0.65), size: 14),
        ]),
        const SizedBox(height: 10),
        Text(value,
            style: GoogleFonts.outfit(color: valueColor, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
      ]),
    );
  }

  Widget _buildConfigRow(String label, String value, bool isDark) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label,
          style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w600)),
      Flexible(child: Text(value, textAlign: TextAlign.end,
          style: GoogleFonts.robotoMono(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontSize: 11, fontWeight: FontWeight.w700,
          ))),
    ]);
  }
}

// ── Private button ───────────────────────────────────────────────────────────
class _LuxPressBtn extends StatefulWidget {
  final String label; final IconData icon; final Color accentColor; final VoidCallback onTap;
  const _LuxPressBtn({required this.label, required this.icon, required this.accentColor, required this.onTap});
  @override State<_LuxPressBtn> createState() => _LuxPressBtnState();
}
class _LuxPressBtnState extends State<_LuxPressBtn> {
  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.lightImpact(); setState(() => _scale = 0.92); },
      onTapUp: (_) { setState(() => _scale = 1.0); widget.onTap(); },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale, duration: const Duration(milliseconds: 110), curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [widget.accentColor, widget.accentColor.withValues(alpha: 0.70)]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: widget.accentColor.withValues(alpha: 0.40), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, color: Colors.white, size: 14),
            const SizedBox(width: 5),
            Text(widget.label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
          ]),
        ),
      ),
    );
  }
}
