import 'package:flutter/material.dart';
import '../../../design_system/roados_tokens.dart';
import '../../models/transport_types.dart';
import '../../models/transport_device.dart';
import '../../services/transport_manager.dart';
import '../../../vehicle_identification/services/smart_scan_orchestrator.dart';

/// Multi-Transport Connectivity Screen.
///
/// Polished RoadOS HUD showing all transport channels (BLE, SPP, USB, Wi-Fi),
/// discovered devices, active connection status, and scan/connect controls.
class MultiTransportConnectivityScreen extends StatefulWidget {
  const MultiTransportConnectivityScreen({super.key});

  @override
  State<MultiTransportConnectivityScreen> createState() =>
      _MultiTransportConnectivityScreenState();
}

class _MultiTransportConnectivityScreenState
    extends State<MultiTransportConnectivityScreen>
    with SingleTickerProviderStateMixin {
  final TransportManager _manager = TransportManager.instance;

  late TabController _tabController;
  bool _isScanning = false;
  SmartScanExecutionMode executionMode = SmartScanExecutionMode.realHardware;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    executionMode = _manager.executionMode;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);
    await _manager.discoverDevices();
    if (mounted) setState(() => _isScanning = false);
  }

  Future<void> _connectDevice(TransportDevice device) async {
    try {
      await _manager.connectToDevice(device);
      if (mounted) setState(() {});
    } on TransportError catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: RoadOSColors.errorCrimson,
          ),
        );
      }
    }
  }

  Future<void> _disconnect() async {
    await _manager.disconnect();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoadOSColors.deepSpaceBlack,
      appBar: AppBar(
        backgroundColor: RoadOSColors.midnightNavy,
        title: const Text('MULTI-TRANSPORT CONNECTIVITY',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              letterSpacing: 1.5,
              color: Colors.white,
            )),
        centerTitle: true,

        bottom: TabBar(
          controller: _tabController,
          indicatorColor: RoadOSColors.roadCyan,
          labelColor: RoadOSColors.roadCyan,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.0),
          tabs: const [
            Tab(icon: Icon(Icons.bluetooth, size: 18), text: 'BLE'),
            Tab(icon: Icon(Icons.bluetooth_audio, size: 18), text: 'SPP'),
            Tab(icon: Icon(Icons.usb, size: 18), text: 'USB'),
            Tab(icon: Icon(Icons.wifi, size: 18), text: 'WI-FI'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildActiveConnectionBanner(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransportTab(TransportType.bluetoothLowEnergy),
                _buildTransportTab(TransportType.bluetoothClassicSpp),
                _buildTransportTab(TransportType.usbOtgSerial),
                _buildTransportTab(TransportType.wifiTcp),
              ],
            ),
          ),
          _buildControlBar(),
        ],
      ),
    );
  }



  Widget _buildActiveConnectionBanner() {
    final conn = _manager.activeConnection;
    if (conn == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RoadOSColors.apexEmerald.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: RoadOSColors.apexEmerald.withValues(alpha: 0.5)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: RoadOSColors.apexEmerald,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ACTIVE CONNECTION',
                    style: TextStyle(
                        color: RoadOSColors.apexEmerald,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        letterSpacing: 1.5)),
                const SizedBox(height: 2),
                Text(
                  '${conn.device.transportType.displayName} • ${conn.device.displayName}',
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  'State: ${conn.state.name.toUpperCase()} • Diagnostic Channel: READY',
                  style: const TextStyle(color: Colors.white60, fontSize: 10),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _disconnect,
            child: const Text('DISCONNECT',
                style: TextStyle(color: RoadOSColors.errorCrimson, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildTransportTab(TransportType type) {
    final devices = _manager.discoveredDevices
        .where((d) => d.transportType == type)
        .toList();
    final caps = _manager.currentManagerState.transportAvailability[type];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTransportStatusCard(type, caps, devices.length),
          const SizedBox(height: 16),
          if (devices.isEmpty)
            _buildEmptyState(type)
          else
            ...devices.map((d) => _buildDeviceCard(d)),
        ],
      ),
    );
  }

  Widget _buildTransportStatusCard(
      TransportType type, TransportCapabilities? caps, int deviceCount) {
    final icon = switch (type) {
      TransportType.bluetoothLowEnergy => Icons.bluetooth,
      TransportType.bluetoothClassicSpp => Icons.bluetooth_audio,
      TransportType.usbOtgSerial => Icons.usb,
      TransportType.wifiTcp => Icons.wifi,
    };
    final color = switch (type) {
      TransportType.bluetoothLowEnergy => RoadOSColors.roadCyan,
      TransportType.bluetoothClassicSpp => RoadOSColors.electricIndigo,
      TransportType.usbOtgSerial => RoadOSColors.hyperOrange,
      TransportType.wifiTcp => RoadOSColors.apexEmerald,
    };

    final isActive = _manager.activeConnection?.device.transportType == type;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RoadOSColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? RoadOSColors.apexEmerald : color.withValues(alpha: 0.3),
          width: isActive ? 1.5 : 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 2),
                Text(type.description,
                    style: const TextStyle(color: Colors.white54, fontSize: 10)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildStatusChip(
                      isActive ? 'ACTIVE' : (deviceCount > 0 ? 'AVAILABLE' : 'IDLE'),
                      isActive
                          ? RoadOSColors.apexEmerald
                          : (deviceCount > 0 ? color : Colors.white38),
                    ),
                    const SizedBox(width: 6),
                    _buildStatusChip('$deviceCount devices', Colors.white54),
                    if (caps != null) ...[
                      const SizedBox(width: 6),
                      _buildStatusChip(
                        caps.isFullyReady ? 'READY' : 'NOT READY',
                        caps.isFullyReady ? RoadOSColors.apexEmerald : RoadOSColors.warningAmber,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(TransportDevice device) {
    final isConnected = _manager.activeConnection?.device.deviceId == device.deviceId;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: RoadOSColors.obsidianSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isConnected
              ? RoadOSColors.apexEmerald.withValues(alpha: 0.6)
              : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(device.displayName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                const SizedBox(height: 2),
                Text(device.address,
                    style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 10,
                        fontFamily: 'monospace')),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (device.signalStrengthDbm != null)
                      _buildStatusChip(
                          'Signal: ${device.signalQuality}',
                          device.signalStrengthDbm! > -60
                              ? RoadOSColors.apexEmerald
                              : RoadOSColors.warningAmber),
                    const SizedBox(width: 6),
                    _buildStatusChip(
                        device.connectionState.name.toUpperCase(),
                        isConnected ? RoadOSColors.apexEmerald : Colors.white38),
                    if (device.manufacturer != null) ...[
                      const SizedBox(width: 6),
                      _buildStatusChip(device.manufacturer!, Colors.white54),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (!isConnected)
            ElevatedButton(
              onPressed: () => _connectDevice(device),
              style: ElevatedButton.styleFrom(
                backgroundColor: RoadOSColors.roadCyan.withValues(alpha: 0.2),
                foregroundColor: RoadOSColors.roadCyan,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                  side: const BorderSide(color: RoadOSColors.roadCyan, width: 0.5),
                ),
              ),
              child: const Text('CONNECT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: RoadOSColors.apexEmerald.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text('CONNECTED',
                  style: TextStyle(
                      color: RoadOSColors.apexEmerald,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(TransportType type) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RoadOSColors.obsidianSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off, color: Colors.white24, size: 42),
          const SizedBox(height: 12),
          Text(
            'No ${type.displayName} devices found',
            style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap SCAN to search for nearby diagnostic adapters',
            style: TextStyle(color: Colors.white30, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5),
      ),
      child: Text(label,
          style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }

  Widget _buildControlBar() {
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
              onPressed: _isScanning ? null : _startScan,
              icon: _isScanning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.radar, size: 18),
              label: Text(_isScanning ? 'SCANNING...' : 'SCAN FOR DEVICES',
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
          if (_manager.activeConnection != null)
            ElevatedButton.icon(
              onPressed: _disconnect,
              icon: const Icon(Icons.link_off, size: 18),
              label: const Text('DISCONNECT',
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
