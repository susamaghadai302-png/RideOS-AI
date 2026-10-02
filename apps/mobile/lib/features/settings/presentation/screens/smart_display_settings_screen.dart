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
    // Subscribe to state changes to rebuild
    _manager.stateStream.listen((state) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _handleAutoConnect() async {
    setState(() => _isAutoConnecting = true);
    await _manager.autoConnect();
    if (mounted) {
      setState(() => _isAutoConnecting = false);
    }
  }

  Future<void> _handleDisconnect() async {
    await _manager.disconnect();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Premium dark mode
      appBar: AppBar(
        title: const Text('Smart Display'),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
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
              _buildLivePreviewSection(),
            ],
            if (_manager.lastScanResults.isNotEmpty && _manager.activeProfile == null)
              _buildScanResults(),
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
      case SmartDisplayState.idle:
      case SmartDisplayState.disconnected:
        break;
      case SmartDisplayState.scanning:
      case SmartDisplayState.deviceFound:
      case SmartDisplayState.identifying:
        color = Colors.blue;
        icon = Icons.bluetooth_searching;
        text = 'Scanning...';
        break;
      case SmartDisplayState.connecting:
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
      case SmartDisplayState.reconnecting:
        color = Colors.orange;
        icon = Icons.warning;
        text = 'Reconnecting...';
        break;
      case SmartDisplayState.unsupported:
      case SmartDisplayState.handshakeFailed:
      case SmartDisplayState.timeout:
        color = Colors.red;
        icon = Icons.error_outline;
        text = state == SmartDisplayState.handshakeFailed
            ? 'Handshake Failed'
            : state == SmartDisplayState.timeout
                ? 'Connection Timeout'
                : 'Unsupported Device';
        break;
      case SmartDisplayState.error:
        color = Colors.red;
        icon = Icons.error;
        text = 'Connection Error';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 48),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (state == SmartDisplayState.unsupported)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'The detected device does not support the RideOS Display Protocol or Generic BLE/SPP modes.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            )
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
          backgroundColor: Colors.red.withOpacity(0.2),
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
    return _buildSection(
      title: 'Detected Device',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow('Model', profile.model),
          _infoRow('Manufacturer', profile.manufacturer),
          _infoRow('Transport', profile.transportType),
          _infoRow('Protocol', profile.protocolType),
          _infoRow('Mode', profile.displayMode.name),
        ],
      ),
    );
  }

  Widget _buildCapabilitiesSection() {
    final negotiated = _manager.negotiatedCapabilities;
    if (negotiated.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return _buildSection(
      title: 'Negotiated Capabilities',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: negotiated.map((cap) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.withOpacity(0.5)),
            ),
            child: Text(
              cap.name,
              style: const TextStyle(color: Colors.greenAccent, fontSize: 12),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLivePreviewSection() {
    // Only show live preview if we are streaming
    if (_manager.currentState != SmartDisplayState.streaming) {
      return const SizedBox.shrink();
    }
    
    return _buildSection(
      title: 'Live Preview (HUD Mode)',
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.turn_right, size: 48, color: Colors.blueAccent),
              SizedBox(height: 8),
              Text('250 m', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              Text('Main Street', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanResults() {
    return _buildSection(
      title: 'Scan Results',
      child: Column(
        children: _manager.lastScanResults.map((d) {
          final isUnsupported = d.classification == DeviceClassification.phoneOrPc ||
              d.classification == DeviceClassification.unknown ||
              d.classification == DeviceClassification.projectionDevice;
          
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              isUnsupported ? Icons.devices : Icons.motorcycle,
              color: isUnsupported ? Colors.grey : Colors.blueAccent,
            ),
            title: Text(d.name.isEmpty ? 'Unknown Device' : d.name, style: const TextStyle(color: Colors.white)),
            subtitle: Text(
              '${d.transport} • ${d.classification.name}',
              style: TextStyle(color: isUnsupported ? Colors.grey : Colors.blueAccent.shade100, fontSize: 12),
            ),
            trailing: isUnsupported 
                ? const Text('Unsupported', style: TextStyle(color: Colors.redAccent, fontSize: 12))
                : null,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white54, fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 1),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
