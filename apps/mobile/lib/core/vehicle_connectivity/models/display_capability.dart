// ─────────────────────────────────────────────────────────────────────────────
//  DISPLAY CAPABILITY — Exhaustive capability enumeration
//
//  Each capability represents a single data field or feature that a connected
//  display may or may not support.  The SmartDisplayConnectionManager will only
//  stream fields whose matching capability was successfully negotiated.
// ─────────────────────────────────────────────────────────────────────────────

enum DisplayCapability {
  // Navigation
  turnByTurnNavigation,
  nextTurn,
  distanceToTurn,
  distanceToDestination,
  eta,
  streetName,
  mapBitmap,       // Raster map frame (JPEG/PNG tile)
  vectorMap,       // Vector map data (GeoJSON, MVT, etc.)

  // Telemetry
  speed,
  compass,
  tripDistance,
  rideTime,

  // Environment
  clock,
  weather,
  temperature,
  rainWarning,
  dayNightMode,

  // Phone / Notification
  phoneBattery,
  callNotification,
  messageNotification,
  genericNotification,
  musicControl,

  // Safety
  overspeedWarning,
  routeDeviation,
  arrivalAlert,
  rerouteAlert,
  emergencySos,
  connectionLostAlert,

  // Projection (only valid for MODE C)
  screenMirroring,
  androidAutoProjection,
  carPlayProjection,
}
