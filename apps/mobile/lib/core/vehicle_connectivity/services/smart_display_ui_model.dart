import '../models/display_capability.dart';
import '../models/rideos_display_packet.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SMART DISPLAY UI MODEL — Rider-safe glanceable display schema
//
//  Defines what a connected display should show at any given moment.
//  The layout is priority-based: PRIMARY fields always shown, SECONDARY
//  fields shown when space allows, ALERT fields override everything.
// ─────────────────────────────────────────────────────────────────────────────

enum DisplayFieldPriority { primary, secondary, alert }

class DisplayField {
  final String fieldId;
  final String label;
  final dynamic value;
  final DisplayFieldPriority priority;
  final DisplayCapability requiredCapability;

  const DisplayField({
    required this.fieldId,
    required this.label,
    required this.value,
    required this.priority,
    required this.requiredCapability,
  });
}

/// Represents the current visual state that should be rendered on the display.
class SmartDisplayUiState {
  final List<DisplayField> primaryFields;
  final List<DisplayField> secondaryFields;
  final List<DisplayField> alertFields;
  final DateTime generatedAt;

  const SmartDisplayUiState({
    required this.primaryFields,
    required this.secondaryFields,
    required this.alertFields,
    required this.generatedAt,
  });

  bool get hasActiveAlert => alertFields.isNotEmpty;
  bool get hasNavigation => primaryFields.any((f) => f.fieldId == 'maneuver');
}

/// Builds a [SmartDisplayUiState] from a [RideOSDisplayPacket], filtered by
/// the negotiated capabilities.
class SmartDisplayUiBuilder {
  final Set<DisplayCapability> negotiatedCapabilities;

  SmartDisplayUiBuilder(this.negotiatedCapabilities);

  SmartDisplayUiState build(RideOSDisplayPacket packet) {
    final primary = <DisplayField>[];
    final secondary = <DisplayField>[];
    final alerts = <DisplayField>[];

    // ── PRIMARY ──────────────────────────────────────────────────────────
    if (_has(DisplayCapability.nextTurn) && packet.maneuverType != null) {
      primary.add(DisplayField(
        fieldId: 'maneuver',
        label: 'Turn',
        value: packet.maneuverType,
        priority: DisplayFieldPriority.primary,
        requiredCapability: DisplayCapability.nextTurn,
      ));
    }

    if (_has(DisplayCapability.distanceToTurn) && packet.maneuverDistanceMeters != null) {
      primary.add(DisplayField(
        fieldId: 'maneuver_distance',
        label: 'Distance',
        value: _formatDistance(packet.maneuverDistanceMeters!),
        priority: DisplayFieldPriority.primary,
        requiredCapability: DisplayCapability.distanceToTurn,
      ));
    }

    if (_has(DisplayCapability.streetName) && packet.streetName != null) {
      primary.add(DisplayField(
        fieldId: 'road_name',
        label: 'Road',
        value: packet.streetName,
        priority: DisplayFieldPriority.primary,
        requiredCapability: DisplayCapability.streetName,
      ));
    }

    if (_has(DisplayCapability.eta) && packet.eta != null) {
      primary.add(DisplayField(
        fieldId: 'eta',
        label: 'ETA',
        value: packet.eta,
        priority: DisplayFieldPriority.primary,
        requiredCapability: DisplayCapability.eta,
      ));
    }

    if (_has(DisplayCapability.speed) && packet.speedKmh != null) {
      primary.add(DisplayField(
        fieldId: 'speed',
        label: 'Speed',
        value: '${packet.speedKmh!.round()} km/h',
        priority: DisplayFieldPriority.primary,
        requiredCapability: DisplayCapability.speed,
      ));
    }

    // ── SECONDARY ────────────────────────────────────────────────────────
    if (_has(DisplayCapability.clock) && packet.clockTime != null) {
      secondary.add(DisplayField(
        fieldId: 'clock',
        label: 'Time',
        value: packet.clockTime,
        priority: DisplayFieldPriority.secondary,
        requiredCapability: DisplayCapability.clock,
      ));
    }

    if (_has(DisplayCapability.weather) && packet.weatherCondition != null) {
      secondary.add(DisplayField(
        fieldId: 'weather',
        label: 'Weather',
        value: '${packet.weatherCondition} ${packet.temperatureC?.round() ?? "—"}°C',
        priority: DisplayFieldPriority.secondary,
        requiredCapability: DisplayCapability.weather,
      ));
    }

    if (_has(DisplayCapability.phoneBattery) && packet.phoneBattery != null) {
      secondary.add(DisplayField(
        fieldId: 'phone_battery',
        label: 'Battery',
        value: '${packet.phoneBattery}%',
        priority: DisplayFieldPriority.secondary,
        requiredCapability: DisplayCapability.phoneBattery,
      ));
    }

    // ── ALERTS ───────────────────────────────────────────────────────────
    if (_has(DisplayCapability.overspeedWarning) && packet.safetyAlert == 'overspeed') {
      alerts.add(DisplayField(
        fieldId: 'overspeed',
        label: 'OVERSPEED',
        value: 'Reduce speed — limit ${packet.speedLimitKmh?.round() ?? "?"} km/h',
        priority: DisplayFieldPriority.alert,
        requiredCapability: DisplayCapability.overspeedWarning,
      ));
    }

    if (_has(DisplayCapability.routeDeviation) && packet.safetyAlert == 'route_deviation') {
      alerts.add(const DisplayField(
        fieldId: 'route_deviation',
        label: 'REROUTING',
        value: 'Off route — recalculating',
        priority: DisplayFieldPriority.alert,
        requiredCapability: DisplayCapability.routeDeviation,
      ));
    }

    if (_has(DisplayCapability.callNotification) && packet.incomingCallContact != null) {
      alerts.add(DisplayField(
        fieldId: 'incoming_call',
        label: 'CALL',
        value: packet.incomingCallContact,
        priority: DisplayFieldPriority.alert,
        requiredCapability: DisplayCapability.callNotification,
      ));
    }

    if (_has(DisplayCapability.emergencySos) && packet.safetyAlert == 'sos') {
      alerts.add(const DisplayField(
        fieldId: 'sos',
        label: 'SOS',
        value: 'Emergency alert triggered',
        priority: DisplayFieldPriority.alert,
        requiredCapability: DisplayCapability.emergencySos,
      ));
    }

    if (_has(DisplayCapability.connectionLostAlert) && packet.connectionStatus == 'DISCONNECTED') {
      alerts.add(const DisplayField(
        fieldId: 'connection_lost',
        label: 'DISCONNECTED',
        value: 'Bluetooth connection lost',
        priority: DisplayFieldPriority.alert,
        requiredCapability: DisplayCapability.connectionLostAlert,
      ));
    }

    return SmartDisplayUiState(
      primaryFields: primary,
      secondaryFields: secondary,
      alertFields: alerts,
      generatedAt: packet.timestamp,
    );
  }

  bool _has(DisplayCapability cap) => negotiatedCapabilities.contains(cap);

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }
}
