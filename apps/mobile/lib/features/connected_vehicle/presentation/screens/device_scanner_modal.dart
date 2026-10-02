import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class DeviceScannerModal extends StatefulWidget {
  const DeviceScannerModal({super.key});

  @override
  State<DeviceScannerModal> createState() => _DeviceScannerModalState();
}

class _DeviceScannerModalState extends State<DeviceScannerModal> {
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    FlutterBluePlus.scanResults.listen((results) {
      if (mounted) setState(() => _scanResults = results);
    });
    FlutterBluePlus.isScanning.listen((state) {
      if (mounted) setState(() => _isScanning = state);
    });
    _startScan();
  }

  Future<void> _startScan() async {
    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    } catch (e) {
      debugPrint("Scan Error: \$e");
    }
  }

  @override
  void dispose() {
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      height: 400,
      child: Column(
        children: [
          Text('Select Device', style: Theme.of(context).textTheme.titleLarge),
          if (_isScanning) const LinearProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _scanResults.length,
              itemBuilder: (c, i) {
                final r = _scanResults[i];
                return ListTile(
                  title: Text(r.device.platformName.isNotEmpty ? r.device.platformName : 'Unknown Device'),
                  subtitle: Text(r.device.remoteId.str),
                  onTap: () {
                    FlutterBluePlus.stopScan();
                    Navigator.pop(context, r.device);
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: _isScanning ? null : _startScan,
            child: const Text('Rescan'),
          ),
        ],
      ),
    );
  }
}
