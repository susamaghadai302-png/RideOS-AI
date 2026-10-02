import 'package:flutter/material.dart';
import 'package:rideos_mobile/core/vehicle_connectivity/services/smart_display_connection_manager.dart';

void main() {
  runApp(const MaterialApp(home: Phase3AValidationRunner()));
}

class Phase3AValidationRunner extends StatefulWidget {
  const Phase3AValidationRunner({super.key});
  @override
  _Phase3AValidationRunnerState createState() => _Phase3AValidationRunnerState();
}

class _Phase3AValidationRunnerState extends State<Phase3AValidationRunner> {
  String _status = "Starting validation...";
  final _manager = SmartDisplayConnectionManager();

  @override
  void initState() {
    super.initState();
    _manager.stateStream.listen((state) {
      setState(() => _status = state.name.toUpperCase());
      if (state == SmartDisplayState.streaming || state == SmartDisplayState.unsupported || state == SmartDisplayState.error) {
        print("PHASE3A_RESULT: DONE");
      }
    });
    _runValidation();
  }

  Future<void> _runValidation() async {
    try {
      print("==== PHASE 3A SMART DISPLAY VALIDATION START ====");
      await _manager.autoConnect();
    } catch (e, stack) {
      print("PHASE3A_RESULT: ERROR - $e\n$stack");
      setState(() => _status = "ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text("Phase 3A: $_status", textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}
