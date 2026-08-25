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
    final notifier = maybeOf(context);
    return notifier?.value ?? Offset.zero;
  }
}

/// A wrapper to be placed at the root of the app/scaffold to track the mouse.
class GlobalPointerTracker extends StatefulWidget {
  final Widget child;
  const GlobalPointerTracker({super.key, required this.child});

  @override
  State<GlobalPointerTracker> createState() => _GlobalPointerTrackerState();
}

class _GlobalPointerTrackerState extends State<GlobalPointerTracker> {
  final ValueNotifier<Offset> _pointerPosition = ValueNotifier(Offset.zero);

  void _updatePointer(PointerEvent event, Size size) {
    if (size.isEmpty) return;
    // Normalize to -1.0 to 1.0 based on screen center
    final dx = (event.position.dx / size.width) * 2 - 1;
    final dy = (event.position.dy / size.height) * 2 - 1;
    _pointerPosition.value = Offset(dx, dy);
  }

  @override
  void dispose() {
    _pointerPosition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return MouseRegion(
      onHover: (event) => _updatePointer(event, size),
      child: Listener(
        onPointerMove: (event) => _updatePointer(event, size),
        onPointerDown: (event) => _updatePointer(event, size),
        child: GlobalPointerProvider(
          notifier: _pointerPosition,
          child: widget.child,
        ),
      ),
    );
  }
}
