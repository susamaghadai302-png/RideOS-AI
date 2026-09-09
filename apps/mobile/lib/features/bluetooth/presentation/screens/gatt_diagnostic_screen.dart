import 'package:flutter/material.dart';
import '../../../../core/bluetooth/bluetooth_engine.dart';

class GattDiagnosticScreen extends StatelessWidget {
  const GattDiagnosticScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final diagnosticMap = BluetoothEngine().gattManager.diagnosticMap;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('GATT Diagnostics', style: TextStyle(color: Colors.orangeAccent)),
        elevation: 0,
      ),
      body: diagnosticMap.isEmpty
          ? const Center(child: Text('No GATT data available. Connect to a device first.', style: TextStyle(color: Colors.white54)))
          : ListView.builder(
              itemCount: diagnosticMap.length,
              itemBuilder: (context, index) {
                final service = diagnosticMap[index];
                return ExpansionTile(
                  title: Text('Service: ${service.uuid}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  children: service.characteristics.map((c) {
                    return ListTile(
                      title: Text('Char: ${c.uuid}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                      subtitle: Row(
                        children: [
                          _buildPropBadge('READ', c.canRead, Colors.blue),
                          const SizedBox(width: 8),
                          _buildPropBadge('WRITE', c.canWrite, Colors.red),
                          const SizedBox(width: 8),
                          _buildPropBadge('NOTIFY', c.canNotify, Colors.green),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
    );
  }

  Widget _buildPropBadge(String label, bool active, Color activeColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: active ? activeColor.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.1),
        border: Border.all(color: active ? activeColor : Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? activeColor : Colors.grey,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
