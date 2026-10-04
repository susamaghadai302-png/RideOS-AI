// ─────────────────────────────────────────────────────────────────────────────
//  CONNECTION DIAGNOSTICS — Live telemetry counters for Smart Display
//
//  Tracks packet counts, bytes, latency, reconnect attempts, RSSI,
//  and error diagnostics. All values are real — no synthetic data.
// ─────────────────────────────────────────────────────────────────────────────

class ConnectionDiagnostics {
  int packetsSent = 0;
  int packetsAcked = 0;
  int packetsFailed = 0;
  int bytesSent = 0;
  int reconnectAttempts = 0;
  int reconnectSuccesses = 0;
  int rssi = -100;
  DateTime? lastPacketTime;
  DateTime? lastHandshakeTime;
  Duration? lastRoundTripLatency;
  String? lastErrorReason;
  String protocolVersion = '';
  String transportType = '';

  void recordPacketSent(int bytes) {
    packetsSent++;
    bytesSent += bytes;
    lastPacketTime = DateTime.now();
  }

  void recordPacketAcked() {
    packetsAcked++;
  }

  void recordPacketFailed(String reason) {
    packetsFailed++;
    lastErrorReason = reason;
  }

  void recordReconnectAttempt() {
    reconnectAttempts++;
  }

  void recordReconnectSuccess() {
    reconnectSuccesses++;
  }

  void recordHandshake(String protocol) {
    lastHandshakeTime = DateTime.now();
    protocolVersion = protocol;
  }

  void updateRssi(int value) {
    rssi = value;
  }

  void recordTransport(String transport) {
    transportType = transport;
  }

  void reset() {
    packetsSent = 0;
    packetsAcked = 0;
    packetsFailed = 0;
    bytesSent = 0;
    reconnectAttempts = 0;
    reconnectSuccesses = 0;
    rssi = -100;
    lastPacketTime = null;
    lastHandshakeTime = null;
    lastRoundTripLatency = null;
    lastErrorReason = null;
    protocolVersion = '';
    transportType = '';
  }

  Map<String, dynamic> toJson() => {
    'packetsSent': packetsSent,
    'packetsAcked': packetsAcked,
    'packetsFailed': packetsFailed,
    'bytesSent': bytesSent,
    'reconnectAttempts': reconnectAttempts,
    'reconnectSuccesses': reconnectSuccesses,
    'rssi': rssi,
    'lastPacketTime': lastPacketTime?.toIso8601String(),
    'lastHandshakeTime': lastHandshakeTime?.toIso8601String(),
    'lastRoundTripLatencyMs': lastRoundTripLatency?.inMilliseconds,
    'lastErrorReason': lastErrorReason,
    'protocolVersion': protocolVersion,
    'transportType': transportType,
  };
}
