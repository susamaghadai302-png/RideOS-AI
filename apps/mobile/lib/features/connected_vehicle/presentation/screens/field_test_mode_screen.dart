import 'dart:convert';
import 'package:rideos_mobile/core/design_system/lux_components.dart' hide RoadOSButton, RoadOSCard;

import 'package:flutter/material.dart';
import '../../../../core/design_system/premium_navigation.dart';
import '../../../../core/design_system/roados_tokens.dart';
import '../../../../core/vehicle_connectivity/models/production_field_test_models.dart';
import '../../../../core/vehicle_connectivity/services/field_connection_state_machine.dart';
import '../../../../core/vehicle_connectivity/transports/mock_vehicle_transport.dart';

class FieldTestModeScreen extends StatefulWidget {
  const FieldTestModeScreen({super.key});

  @override
  State<FieldTestModeScreen> createState() => _FieldTestModeScreenState();
}

class _FieldTestModeScreenState extends State<FieldTestModeScreen> {
  final _stateMachine = FieldConnectionStateMachine();
  final _mockTransport = MockVehicleTransport();
  bool _isConnecting = false;

  @override
  void initState() {
    super.initState();
    _mockTransport.initialize();
  }

  @override
  void dispose() {
    _mockTransport.dispose();
    super.dispose();
  }

  Future<void> _startFieldTest() async {
    setState(() => _isConnecting = true);
    await _stateMachine.executeConnectionFlow(
      deviceName: 'Yamaha_R15M_CCU_FieldTest',
      macAddress: 'AA:BB:CC:DD:EE:FF',
      transport: _mockTransport,
      hasPermissions: true,
      isBluetoothAvailable: true,
      isSimulated: true,
    );
    if (mounted) {
      setState(() => _isConnecting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoadOSColors.deepSpaceBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.satellite_alt_rounded, color: RoadOSColors.electricBlue, size: 20),
            SizedBox(width: 8),
            Text(
              'FIELD TEST MODE',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<FieldConnectionState>(
        stream: _stateMachine.stateStream,
        initialData: _stateMachine.currentState,
        builder: (context, snapshot) {
          final state = snapshot.data ?? _stateMachine.currentState;
          final session = _stateMachine.activeSessionLog;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildDisclaimerBanner(),
              const SizedBox(height: 16),
              _buildStateCard(state),
              const SizedBox(height: 16),
              if (session != null) ...[
                _buildFieldMetricsCard(session),
                const SizedBox(height: 16),
              ],
              _buildActionButtons(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDisclaimerBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'PHYSICAL VALIDATION PENDING — Software field-readiness bench mode active.',
              style: TextStyle(color: Colors.amber, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStateCard(FieldConnectionState state) {
    Color stateColor = RoadOSColors.electricBlue;
    if (state == FieldConnectionState.streaming || state == FieldConnectionState.connected) {
      stateColor = RoadOSColors.apexEmerald;
    } else if (state == FieldConnectionState.error || state == FieldConnectionState.permissionRequired || state == FieldConnectionState.bluetoothUnavailable) {
      stateColor = Colors.redAccent;
    } else if (state == FieldConnectionState.reconnecting) {
      stateColor = Colors.amber;
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: stateColor.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('16-STATE LIFECYCLE PHASE', style: TextStyle(color: RoadOSColors.textMuted, fontSize: 10, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stateColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  state.name.toUpperCase(),
                  style: TextStyle(color: stateColor, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(state.userMessage, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildFieldMetricsCard(FieldTestSessionLog session) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: RoadOSColors.borderTranslucent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(session.deviceName, style: const TextStyle(color: RoadOSColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(session.verificationLevel.badgeLabel, style: const TextStyle(color: RoadOSColors.electricBlue, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('RSSI', '${session.rssi} dBm'),
              _buildStat('MTU', '${session.mtu} B'),
              _buildStat('RATE', '${session.notificationFrequencyHz} Hz'),
              _buildStat('LOSS', '${session.packetLossPercent.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String title, String val) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(val, style: const TextStyle(color: RoadOSColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionButtons(FieldConnectionState state) {
    return Column(
      children: [
        ElevatedButton.icon(
          icon: Icon(_isConnecting ? Icons.hourglass_top_rounded : Icons.play_arrow_rounded),
          label: Text(
            _isConnecting ? 'EXECUTING LIFECYCLE...' : 'EXECUTE FIELD CONNECTION',
            style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: RoadOSColors.electricBlue,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: _isConnecting ? null : _startFieldTest,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: RoadOSColors.textPrimary,
                  side: const BorderSide(color: RoadOSColors.borderTranslucent),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => _stateMachine.disconnect(),
                child: const Text('DISCONNECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: RoadOSColors.electricBlue,
                  side: const BorderSide(color: RoadOSColors.electricBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  final log = _stateMachine.activeSessionLog;
                  if (log != null) {
                    final jsonStr = const JsonEncoder.withIndent('  ').convert(log.toJson());
                    showLuxSnack(context, 'Exported Field Report (${jsonStr.length} bytes)', variant: LuxSnackVariant.info);
                  }
                },
                child: const Text('EXPORT REPORT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
