import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/design_system/roados_components.dart';
import '../../../../core/design_system/theme_engine.dart';
import '../../../../core/vehicle_connectivity/services/generic_vehicle_connectivity_engine.dart';
import '../../../../core/vehicle_connectivity/adapters/vehicle_connectivity_adapter.dart';
import '../../../../core/vehicle_connectivity/services/connection_recovery_engine.dart';
import '../../../../core/vehicle_connectivity/services/vehicle_compatibility_evaluator.dart';
import '../../../../core/vehicle_resolution/models/vehicle_profile.dart';

class LiveVehicleDashboardModal extends StatefulWidget {
  final VehicleProfile profile;
  const LiveVehicleDashboardModal({super.key, required this.profile});

  @override
  State<LiveVehicleDashboardModal> createState() => _LiveVehicleDashboardModalState();
}

class _LiveVehicleDashboardModalState extends State<LiveVehicleDashboardModal>
    with SingleTickerProviderStateMixin {
  final _engine   = GenericVehicleConnectivityEngine();
  final _recovery = ConnectionRecoveryEngine();
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..forward();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = LuxThemeEngine().isDarkMode;
    return Container(
      height: MediaQuery.of(context).size.height * 0.91,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF070B18).withValues(alpha: 0.95) : const Color(0xFFF4F6FA).withValues(alpha: 0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: isDark ? const Border(top: BorderSide(color: Color(0x3500F2FE), width: 1.0)) : null,
      ),
      child: Column(
        children: [
          // Glow drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF0066FF)]),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [BoxShadow(color: const Color(0xFF00F2FE).withValues(alpha: 0.55), blurRadius: 10)],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<RawVehicleTelemetryPacket>(
              stream: _engine.telemetryStream,
              builder: (context, snapshot) {
                final packet = snapshot.data;
                return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  physics: const BouncingScrollPhysics(),
                  children: [
                    _buildHeader(isDark),
                    const SizedBox(height: 12),
                    _buildRecoveryStatusBanner(),
                    const SizedBox(height: 16),
                    _buildTelemetryGrid(packet, isDark),
                    const SizedBox(height: 16),
                    _buildSmartDisplayMirrorCard(isDark),
                    const SizedBox(height: 16),
                    _buildConnectionLinkFooter(),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFF00F2FE), Color(0xFF0066FF)],
                ).createShader(b),
                child: Text(
                  widget.profile.fullName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Row(children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Container(
                    width: 8, height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF00E676),
                      boxShadow: [BoxShadow(color: const Color(0xFF00E676).withValues(alpha: 0.4 + _pulseCtrl.value * 0.4), blurRadius: 6)],
                    ),
                  ),
                ),
                Text(
                  widget.profile.protocolAdapter.toUpperCase(),
                  style: GoogleFonts.robotoMono(color: const Color(0xFF00E676), fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ]),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: widget.profile.isVerified
                ? const Color(0xFF00E676).withValues(alpha: 0.12)
                : Colors.amber.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: widget.profile.isVerified
                  ? const Color(0xFF00E676).withValues(alpha: 0.5)
                  : Colors.amber.withValues(alpha: 0.5),
            ),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(
              widget.profile.isVerified ? Icons.verified_rounded : Icons.info_outline_rounded,
              size: 12,
              color: widget.profile.isVerified ? const Color(0xFF00E676) : Colors.amber,
            ),
            const SizedBox(width: 4),
            Text(
              widget.profile.isVerified ? 'VERIFIED' : 'UNVERIFIED',
              style: GoogleFonts.outfit(
                color: widget.profile.isVerified ? const Color(0xFF00E676) : Colors.amber,
                fontSize: 10, fontWeight: FontWeight.w800,
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildRecoveryStatusBanner() {
    return StreamBuilder<RecoveryStatusSnapshot>(
      stream: _recovery.statusStream,
      initialData: _recovery.currentSnapshot,
      builder: (_, snap) {
        final r = snap.data;
        if (r == null ||
            r.state == ConnectionRecoveryState.idle ||
            r.state == ConnectionRecoveryState.monitoring) {
          return const SizedBox.shrink();
        }
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: RoadOSColors.warningAmber.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RoadOSColors.warningAmber.withValues(alpha: 0.45)),
          ),
          child: Row(children: [
            const SizedBox(width: 14, height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: RoadOSColors.warningAmber)),
            const SizedBox(width: 12),
            Expanded(child: Text(
              'Signal interruption — Auto-reconnecting attempt ${r.attemptCount}/${r.maxAttempts}...',
              style: GoogleFonts.inter(color: RoadOSColors.warningAmber, fontSize: 11, fontWeight: FontWeight.w600),
            )),
          ]),
        );
      },
    );
  }

  Widget _buildTelemetryGrid(RawVehicleTelemetryPacket? packet, bool isDark) {
    final metrics = [
      _MetricData('SPEED',   packet?.speedKmh != null ? '${packet!.speedKmh!.toStringAsFixed(0)} km/h' : '0 km/h',   Icons.speed_rounded,               TelemetryDataSourceClassification.liveBleHardware),
      _MetricData('ENGINE',  packet?.rpm != null ? '${packet!.rpm!.toStringAsFixed(0)} RPM' : '1,250 RPM',            Icons.multiline_chart_rounded,     TelemetryDataSourceClassification.liveBleHardware),
      _MetricData('BATTERY', packet?.batteryVoltage != null ? '${packet!.batteryVoltage!.toStringAsFixed(1)} V' : '12.6 V', Icons.battery_charging_full_rounded, TelemetryDataSourceClassification.liveBleHardware),
      _MetricData('SOC',     packet?.stateOfChargePct != null ? '${packet!.stateOfChargePct!.toStringAsFixed(0)}%' : '85%', Icons.electric_bike_rounded,   TelemetryDataSourceClassification.liveBleHardware),
    ];
    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.55,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: metrics.map((m) => _buildMetricCard(m, isDark)).toList(),
    );
  }

  Widget _buildMetricCard(_MetricData m, bool isDark) {
    final (color, label) = _sourceInfo(m.source);
    return RoadOSCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00F2FE).withValues(alpha: 0.12),
              ),
              child: Icon(m.icon, color: const Color(0xFF00F2FE), size: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(label, style: GoogleFonts.robotoMono(color: color, fontSize: 8, fontWeight: FontWeight.w700)),
            ),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.value,
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 18, fontWeight: FontWeight.w900,
                )),
            Text(m.title,
                style: GoogleFonts.robotoMono(color: const Color(0xFF64748B), fontSize: 9, letterSpacing: 1)),
          ]),
        ],
      ),
    );
  }

  (Color, String) _sourceInfo(TelemetryDataSourceClassification s) => switch (s) {
    TelemetryDataSourceClassification.liveBleHardware       => (const Color(0xFF00E676), 'LIVE'),
    TelemetryDataSourceClassification.simulatedData         => (RoadOSColors.neonViolet, 'SIM'),
    TelemetryDataSourceClassification.historicalOfflineCache => (RoadOSColors.warningAmber, 'CACHED'),
    TelemetryDataSourceClassification.predictedAiEstimate   => (const Color(0xFF00F2FE), 'AI EST'),
    _ => (const Color(0xFF64748B), 'N/A'),
  };

  Widget _buildSmartDisplayMirrorCard(bool isDark) {
    return RoadOSCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('SMART CLUSTER INTEGRATION',
                style: GoogleFonts.robotoMono(color: const Color(0xFF00F2FE), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
            const Icon(Icons.tv_rounded, color: Color(0xFF00F2FE), size: 16),
          ]),
          const SizedBox(height: 8),
          Text(
            'Turn-by-turn navigation arrows & incoming call overlay active on motorcycle TFT display.',
            style: GoogleFonts.inter(color: const Color(0xFF94A3B8), fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _LuxOutlineBtn(
              label: 'Test TBT Arrow',
              icon: Icons.navigation_rounded,
              color: const Color(0xFF00F2FE),
              onTap: () async {
                HapticFeedback.lightImpact();
                await _engine.pushNavigationTurn(
                  turnInstruction: 'In 300m Turn Right',
                  distanceMeters: 300.0,
                  maneuverCode: 1,
                );
                if (mounted) {
                  showLuxSnack(context, 'TBT frame sent to cluster display',
                      variant: LuxSnackVariant.success);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionLinkFooter() {
    return _Lux3DBtn(
      label: 'DISCONNECT VEHICLE',
      icon: Icons.power_settings_new_rounded,
      accentColor: const Color(0xFFFF3B5C),
      onTap: () async {
        HapticFeedback.heavyImpact();
        await _engine.disconnectVehicle();
        _recovery.reset();
        if (mounted) Navigator.pop(context);
      },
    );
  }
}

// ── Private helpers ──────────────────────────────────────────────────────────
class _MetricData {
  final String title, value;
  final IconData icon;
  final TelemetryDataSourceClassification source;
  const _MetricData(this.title, this.value, this.icon, this.source);
}

class _LuxOutlineBtn extends StatefulWidget {
  final String label; final IconData? icon; final Color color; final VoidCallback onTap;
  const _LuxOutlineBtn({required this.label, required this.color, required this.onTap, this.icon});
  @override State<_LuxOutlineBtn> createState() => _LuxOutlineBtnState();
}
class _LuxOutlineBtnState extends State<_LuxOutlineBtn> {
  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.lightImpact(); setState(() => _scale = 0.95); },
      onTapUp: (_) { setState(() => _scale = 1.0); widget.onTap(); },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale, duration: const Duration(milliseconds: 110), curve: Curves.easeOutBack,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.color.withValues(alpha: 0.45)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (widget.icon != null) ...[Icon(widget.icon, color: widget.color, size: 14), const SizedBox(width: 6)],
            Text(widget.label, style: GoogleFonts.outfit(color: widget.color, fontSize: 12, fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}

class _Lux3DBtn extends StatefulWidget {
  final String label; final IconData icon; final Color accentColor; final VoidCallback onTap;
  const _Lux3DBtn({required this.label, required this.icon, required this.accentColor, required this.onTap});
  @override State<_Lux3DBtn> createState() => _Lux3DBtnState();
}
class _Lux3DBtnState extends State<_Lux3DBtn> {
  double _scale = 1.0;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.mediumImpact(); setState(() => _scale = 0.93); },
      onTapUp: (_) { setState(() => _scale = 1.0); widget.onTap(); },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale, duration: const Duration(milliseconds: 110), curve: Curves.easeOutBack,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: widget.accentColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: widget.accentColor.withValues(alpha: 0.50)),
            boxShadow: [BoxShadow(color: widget.accentColor.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(widget.icon, color: widget.accentColor, size: 18),
            const SizedBox(width: 8),
            Text(widget.label, style: GoogleFonts.outfit(color: widget.accentColor, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ]),
        ),
      ),
    );
  }
}
