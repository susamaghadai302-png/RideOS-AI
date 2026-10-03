import 'package:flutter/material.dart';
import '../../../../core/vehicle_connectivity/services/smart_display_connection_manager.dart';
import '../../../../core/vehicle_connectivity/models/display_device_profile.dart';

class SmartDisplaySettingsScreen extends StatefulWidget {
  const SmartDisplaySettingsScreen({super.key});

  @override
  State<SmartDisplaySettingsScreen> createState() => _SmartDisplaySettingsScreenState();
}

class _SmartDisplaySettingsScreenState extends State<SmartDisplaySettingsScreen> {
  final _manager = SmartDisplayConnectionManager();
  bool _isAutoConnecting = false;

  @override
  void initState() {
    super.initState();
    _manager.stateStream.listen((state) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _handleAutoConnect() async {
    setState(() => _isAutoConnecting = true);
    await _manager.autoConnect();
    if (mounted) setState(() => _isAutoConnecting = false);
  }

  Future<void> _handleDisconnect() async {
    await _manager.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Smart Display'), backgroundColor: Colors.black, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 24),
            _buildAutoDiscoverButton(),
            const SizedBox(height: 32),
            if (_manager.activeProfile != null) ...[
              _buildActiveDeviceSection(),
              const SizedBox(height: 24),
              _buildCapabilitiesSection(),
              const SizedBox(height: 24),
              _buildDiagnosticsSection(),
              const SizedBox(height: 24),
              _buildLivePreviewSection(),
            ],
            if (_manager.lastScanResults.isNotEmpty && _manager.activeProfile == null)
              _buildScanResults(),
            if (_manager.failureReason != null) ...[
              const SizedBox(height: 16),
              _buildErrorSection(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader() {
    final state = _manager.currentState;
    Color color = Colors.grey;
    IconData icon = Icons.bluetooth_disabled;
    String text = 'Disconnected';

    switch (state) {
      case SmartDisplayState.disconnected:
        break;
      case SmartDisplayState.discovering:
      case SmartDisplayState.candidateFound:
      case SmartDisplayState.identifying:
        color = Colors.blue;
        icon = Icons.bluetooth_searching;
        text = 'Discovering...';
        break;
      case SmartDisplayState.connecting:
      case SmartDisplayState.probing:
      case SmartDisplayState.handshaking:
      case SmartDisplayState.negotiating:
        color = Colors.amber;
        icon = Icons.bluetooth_connected;
        text = 'Connecting...';
        break;
      case SmartDisplayState.connected:
      case SmartDisplayState.streaming:
        color = Colors.green;
        icon = Icons.motorcycle;
        text = 'Connected & Streaming';
        break;
      case SmartDisplayState.degraded:
      case SmartDisplayState.reconnecting:
        color = Colors.orange;
        icon = Icons.warning;
        text = state == SmartDisplayState.degraded ? 'Connection Degraded' : 'Reconnecting...';
        break;
      case SmartDisplayState.unsupported:
        color = Colors.red;
        icon = Icons.error_outline;
        text = 'Unsupported Device';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          if (state == SmartDisplayState.unsupported)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Device does not support RideOS Display Protocol or Generic BLE/SPP modes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAutoDiscoverButton() {
    final isConnected = _manager.currentState == SmartDisplayState.connected ||
        _manager.currentState == SmartDisplayState.streaming;

    if (isConnected) {
      return ElevatedButton.icon(
        onPressed: _handleDisconnect,
        icon: const Icon(Icons.close),
        label: const Text('Disconnect'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.withValues(alpha: 0.2),
          foregroundColor: Colors.red,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: _isAutoConnecting ? null : _handleAutoConnect,
      icon: _isAutoConnecting
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.search),
      label: Text(_isAutoConnecting ? 'Discovering...' : 'Auto Discover Smart Display'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildActiveDeviceSection() {
    final profile = _manager.activeProfile!;
    final diag = _manager.diagnostics;
    return _buildSection(
      title: 'DETECTED DEVICE',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Model', profile.model),
          _infoRow('Manufacturer', profile.manufacturer),
          _infoRow('Transport', diag.transportType.isNotEmpty ? diag.transportType : profile.transportType),
          _infoRow('Protocol', diag.protocolVersion.isNotEmpty ? diag.protocolVersion : profile.protocolType),
          _infoRow('Mode', profile.displayMode.name),
          _infoRow('Verification', profile.verificationStatus.name),
        ],
      ),
    );
  }

  Widget _buildCapabilitiesSection() {
    final negotiated = _manager.negotiatedCapabilities;
    if (negotiated.isEmpty) return const SizedBox.shrink();
    return _buildSection(
      title: 'NEGOTIATED CAPABILITIES',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: negotiated.map((cap) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
            ),
            child: Text(cap.name, style: const TextStyle(color: Colors.greenAccent, fontSize: 12)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDiagnosticsSection() {
    final diag = _manager.diagnostics;
    return _buildSection(
      title: 'CONNECTION DIAGNOSTICS',
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.grey.shade900, borderRadius: BorderRadius.circular(12)),
        child: Column(
          children: [
            Row(children: [
              Expanded(child: _diagMetric('Packets Sent', '${diag.packetsSent}')),
              Expanded(child: _diagMetric('Bytes Sent', '${diag.bytesSent}')),
              Expanded(child: _diagMetric('Failed', '${diag.packetsFailed}')),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: _diagMetric('RSSI', '${diag.rssi} dBm')),
              Expanded(child: _diagMetric('Reconnects', '${diag.reconnectAttempts}')),
              Expanded(child: _diagMetric('Acked', '${diag.packetsAcked}')),
            ]),
            const SizedBox(height: 8),
            _infoRow('Protocol', diag.protocolVersion),
            if (diag.lastHandshakeTime != null)
              _infoRow('Last Handshake', _fmtTime(diag.lastHandshakeTime!)),
            if (diag.lastPacketTime != null)
              _infoRow('Last Packet', _fmtTime(diag.lastPacketTime!)),
            if (diag.lastErrorReason != null)
              _infoRow('Last Error', diag.lastErrorReason!),
          ],
        ),
      ),
    );
  }

  Widget _diagMetric(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(color: Colors.cyanAccent, fontSize: 16, fontWeight: FontWeight.bold)),
      Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
    ]);
  }

  String _fmtTime(DateTime dt) =>
      '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

  Widget _buildLivePreviewSection() {
    if (_manager.currentState != SmartDisplayState.streaming) return const SizedBox.shrink();
    return _buildSection(
      title: 'LIVE PREVIEW (HUD MODE)',
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: const Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.turn_right, size: 48, color: Colors.blueAccent),
            SizedBox(height: 8),
            Text('250 m', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            Text('Main Street', style: TextStyle(color: Colors.white70, fontSize: 14)),
          ]),
        ),
      ),
    );
  }

  Widget _buildScanResults() {
    return _buildSection(
      title: 'SCAN RESULTS',
      child: Column(
        children: _manager.lastScanResults.map((d) {
          final isSkip = d.classification == DeviceClassification.phoneOrPc ||
              d.classification == DeviceClassification.unknown ||
              d.classification == DeviceClassification.projectionDevice;
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(isSkip ? Icons.devices : Icons.motorcycle, color: isSkip ? Colors.grey : Colors.blueAccent),
            title: Text(d.name.isEmpty ? 'Unknown Device' : d.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text('${d.transport} • ${d.classification.name} • ${d.rssi} dBm',
                style: TextStyle(color: isSkip ? Colors.grey : Colors.blueAccent.shade100, fontSize: 12)),
            trailing: isSkip
                ? const Text('Skip', style: TextStyle(color: Colors.redAccent, fontSize: 12))
                : const Text('Candidate', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
        const SizedBox(width: 8),
        Expanded(child: Text(_manager.failureReason ?? '', style: const TextStyle(color: Colors.redAccent, fontSize: 12))),
      ]),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1)),
      const SizedBox(height: 12),
      child,
    ]);
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        Flexible(child: Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.end)),
      ]),
    );
  }
}
