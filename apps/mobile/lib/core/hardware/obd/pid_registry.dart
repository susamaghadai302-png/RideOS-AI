enum PidSupport {
  supported,
  unsupported,
  timeout,
  invalidResponse,
  parseError,
  unavailable,
  unverified,
}

class PidDefinition {
  final String pid;
  final String description;
  final String unit;
  
  const PidDefinition(this.pid, this.description, this.unit);
}

class PidRegistry {
  static const PidDefinition rpm = PidDefinition('010C', 'Engine RPM', 'RPM');
  static const PidDefinition speed = PidDefinition('010D', 'Vehicle Speed', 'km/h');
  static const PidDefinition coolantTemp = PidDefinition('0105', 'Coolant Temperature', '°C');
  static const PidDefinition intakeTemp = PidDefinition('010F', 'Intake Air Temperature', '°C');
  static const PidDefinition throttlePos = PidDefinition('0111', 'Throttle Position', '%');
  
  static final Map<String, PidDefinition> knownPids = {
    rpm.pid: rpm,
    speed.pid: speed,
    coolantTemp.pid: coolantTemp,
    intakeTemp.pid: intakeTemp,
    throttlePos.pid: throttlePos,
  };
}
