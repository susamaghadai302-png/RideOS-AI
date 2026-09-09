import 'package:flutter/material.dart';

/// Provides a global normalized pointer coordinate (-1.0 to 1.0) for 3D parallax effects.
class GlobalPointerProvider extends InheritedNotifier<ValueNotifier<Offset>> {
  const GlobalPointerProvider({
    super.key,
    required super.notifier,
    required super.child,
  });

  static ValueNotifier<Offset>? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GlobalPointerProvider>()?.notifier;
  }

  static Offset of(BuildContext context) {
    return Offset.zero;
  }
}

/// A wrapper placed at the root of the app/scaffold. Maintains a stable resting position.
class GlobalPointerTracker extends StatefulWidget {
  final Widget child;
  const GlobalPointerTracker({super.key, required this.child});

  @override
  State<GlobalPointerTracker> createState() => _GlobalPointerTrackerState();
}

class _GlobalPointerTrackerState extends State<GlobalPointerTracker> {
  final ValueNotifier<Offset> _pointerPosition = ValueNotifier(Offset.zero);

  @override
  void dispose() {
    _pointerPosition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlobalPointerProvider(
      notifier: _pointerPosition,
      child: widget.child,
    );
  }
}
