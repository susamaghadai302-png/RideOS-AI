

class PidDecoder {
  /// Decodes raw ELM327 hex strings based on SAE J1979 standard formulas.
  /// Throws FormatException if the input is malformed.
  static dynamic decode(String pid, String hexResponse) {
    final cleanHex = hexResponse.replaceAll(RegExp(r'\s+'), '');
    
    // Validate minimal length for a response (Service 01 usually prefixes 41)
    if (cleanHex.length < 4) {
      throw const FormatException('Response too short');
    }
    
    // Strip the mode/pid echo if present (e.g., '41 0C' for mode 01 pid 0C)
    String dataBytesHex = cleanHex;
    final expectedPrefix = '41${pid.substring(2)}';
    if (cleanHex.startsWith(expectedPrefix)) {
      dataBytesHex = cleanHex.substring(expectedPrefix.length);
    }
    
    final bytes = _hexToBytes(dataBytesHex);
    if (bytes.isEmpty) {
      throw const FormatException('No data bytes');
    }

    final A = bytes.isNotEmpty ? bytes[0] : 0;
    final B = bytes.length > 1 ? bytes[1] : 0;

    switch (pid) {
      case '010C': // RPM
        return ((A * 256.0) + B) / 4.0;
      case '010D': // Speed
        return A;
      case '0105': // Coolant Temp
        return A - 40;
      case '010F': // Intake Air Temp
        return A - 40;
      case '0111': // Throttle Position
        return (A * 100.0) / 255.0;
      default:
        throw UnimplementedError('No decoder for PID $pid');
    }
  }

  static List<int> _hexToBytes(String hex) {
    final result = <int>[];
    for (int i = 0; i < hex.length; i += 2) {
      if (i + 2 <= hex.length) {
        result.add(int.parse(hex.substring(i, i + 2), radix: 16));
      }
    }
    return result;
  }
}
