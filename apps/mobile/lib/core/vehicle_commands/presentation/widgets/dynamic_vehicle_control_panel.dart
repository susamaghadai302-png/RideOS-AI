import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../design_system/roados_tokens.dart';
import '../../../bluetooth/bluetooth_engine.dart';
import '../../../vehicle_capabilities/models/vehicle_capabilities.dart';
import '../../models/command_result.dart';
import '../../models/vehicle_command.dart';
import '../../services/vehicle_command_pipeline.dart';
import 'vehicle_control_card.dart';

class DynamicVehicleControlPanel extends ConsumerStatefulWidget {
  const DynamicVehicleControlPanel({super.key});

  @override
  ConsumerState<DynamicVehicleControlPanel> createState() => _DynamicVehicleControlPanelState();
}

class _DynamicVehicleControlPanelState extends ConsumerState<DynamicVehicleControlPanel> {
  final Map<VehicleCommandType, bool> _executingMap = {};
  final Map<VehicleCommandType, CommandResult> _lastResults = {};
  String _selectedRidingMode = 'SPORT';

  @override
  void initState() {
    super.initState();
    VehicleCommandPipeline().initialize(ref);
  }

  Future<void> _handleCommand(VehicleCommandType type, dynamic parameter) async {
    setState(() {
      _executingMap[type] = true;
    });

    final command = VehicleCommand(type: type, parameter: parameter);
    final result = await VehicleCommandPipeline().execute(command);

    if (mounted) {
      setState(() {
        _executingMap[type] = false;
        _lastResults[type] = result;
      });

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: RoadOSColors.apexEmerald,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bluetoothStateProvider);
    final adapter = ref.watch(activeAdapterProvider);
    final isConnected = state.isConnected;
    final capabilities = adapter?.capabilities ?? VehicleCapabilities.empty();

    final List<Widget> controlCards = [];

    // 1. Riding Mode Control
    if (capabilities.hasControl(ControlCapability.controlRidingMode)) {
      controlCards.add(
        VehicleControlCard(
          title: 'Riding Mode',
          description: 'Adjust ECU ignition timing & throttle mapping',
          icon: Icons.tune_rounded,
          isSupported: true,
          isConnected: isConnected,
          isExecuting: _executingMap[VehicleCommandType.setRidingMode] ?? false,
          lastResult: _lastResults[VehicleCommandType.setRidingMode],
          customTrailing: Column(
            children: [
              SizedBox(
                height: 32,
                child: Row(
                  children: ['RAIN', 'ROAD', 'SPORT', 'TRACK'].map((mode) {
                    final isSel = _selectedRidingMode == mode;
                    return Expanded(
                      child: GestureDetector(
                        onTap: isConnected
                            ? () {
                                setState(() => _selectedRidingMode = mode);
                                _handleCommand(VehicleCommandType.setRidingMode, mode);
                              }
                            : null,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: isSel ? Colors.white : RoadOSColors.cardSurface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSel ? Colors.white : RoadOSColors.borderTranslucent,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              mode,
                              style: TextStyle(
                                color: isSel ? Colors.black : RoadOSColors.textMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 2. Hazard Lights Control
    if (capabilities.hasControl(ControlCapability.controlHazard)) {
      controlCards.add(
        VehicleControlCard(
          title: 'Emergency Hazards',
          description: 'Synchronized dual flasher strobe',
          icon: Icons.warning_amber_rounded,
          isSupported: true,
          isConnected: isConnected,
          isExecuting: _executingMap[VehicleCommandType.triggerHazard] ?? false,
          lastResult: _lastResults[VehicleCommandType.triggerHazard],
          onTrigger: () => _handleCommand(VehicleCommandType.triggerHazard, true),
        ),
      );
    }

    // 3. Headlight / Auxiliary Control
    if (capabilities.hasControl(ControlCapability.controlLights)) {
      controlCards.add(
        VehicleControlCard(
          title: 'Headlight Auxiliary',
          description: 'Toggle auxiliary LED driving lights',
          icon: Icons.lightbulb_outline_rounded,
          isSupported: true,
          isConnected: isConnected,
          isExecuting: _executingMap[VehicleCommandType.toggleHeadlight] ?? false,
          lastResult: _lastResults[VehicleCommandType.toggleHeadlight],
          onTrigger: () => _handleCommand(VehicleCommandType.toggleHeadlight, true),
        ),
      );
    }

    // 4. Remote Lock Control (Protected by Safety System)
    if (capabilities.hasControl(ControlCapability.controlLock)) {
      controlCards.add(
        VehicleControlCard(
          title: 'Smart Keyless Lock',
          description: 'Secure ignition lock (Blocked when in motion)',
          icon: Icons.lock_outline_rounded,
          isSupported: true,
          isConnected: isConnected,
          isExecuting: _executingMap[VehicleCommandType.toggleLock] ?? false,
          lastResult: _lastResults[VehicleCommandType.toggleLock],
          onTrigger: () => _handleCommand(VehicleCommandType.toggleLock, true),
        ),
      );
    }

    // 5. Diagnostic Fault Code Clearing
    if (capabilities.hasControl(ControlCapability.clearFaultCodes)) {
      controlCards.add(
        VehicleControlCard(
          title: 'Clear Stored DTCs',
          description: 'Transmit OBD-II Mode 04 clear request to ECU',
          icon: Icons.cleaning_services_rounded,
          isSupported: true,
          isConnected: isConnected,
          isExecuting: _executingMap[VehicleCommandType.clearFaultCodes] ?? false,
          lastResult: _lastResults[VehicleCommandType.clearFaultCodes],
          onTrigger: () => _handleCommand(VehicleCommandType.clearFaultCodes, null),
        ),
      );
    }

    if (controlCards.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF070B18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1A2035)),
        ),
        child: Column(
          children: [
            const Icon(Icons.shield_outlined, color: RoadOSColors.textMuted, size: 36),
            const SizedBox(height: 12),
            const Text(
              'READ-ONLY TELEMETRY PROTOCOL ACTIVE',
              style: TextStyle(
                color: RoadOSColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isConnected
                  ? 'The connected ${adapter?.adapterId ?? "GATT"} bus provides verified passive telemetry streaming. Direct remote actuations are restricted by manufacturer firmware.'
                  : 'Connect a compatible vehicle ECU or diagnostic gateway to inspect supported control actuators.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: RoadOSColors.textMuted, fontSize: 11, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'VERIFIED VEHICLE ACTUATORS',
                style: TextStyle(
                  color: RoadOSColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              Text(
                '${controlCards.length} CONTROLS DISCOVERED',
                style: const TextStyle(
                  color: Color(0xFF00E676),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 600 ? 2 : 1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: MediaQuery.of(context).size.width > 600 ? 2.2 : 2.0,
          children: controlCards,
        ),
      ],
    );
  }
}
