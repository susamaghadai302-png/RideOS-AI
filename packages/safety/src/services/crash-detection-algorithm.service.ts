import { CrashSeverity } from '../models/crash-incident.model';

export class CrashDetectionAlgorithmService {
  private static readonly IMPACT_G_THRESHOLD = 4.5;
  private static readonly TILT_ANGLE_THRESHOLD_DEGREES = 65;

  /**
   * Analyzes sensor data to evaluate if a motorcycle crash or fall event has occurred
   */
  public static evaluateSensors(
    accelG: number,
    tiltAngleDegrees: number,
    currentSpeedKmh: number,
    previousSpeedKmh: number,
  ): { isCrashDetected: boolean; severity?: CrashSeverity } {
    const isImpactDetected = accelG >= this.IMPACT_G_THRESHOLD;
    const isHorizontalFall = tiltAngleDegrees >= this.TILT_ANGLE_THRESHOLD_DEGREES;
    const isRapidDeceleration = previousSpeedKmh - currentSpeedKmh > 35;

    if (isImpactDetected && isHorizontalFall && isRapidDeceleration) {
      return { isCrashDetected: true, severity: 'CRITICAL' };
    }

    if (isImpactDetected || (isHorizontalFall && currentSpeedKmh === 0)) {
      return { isCrashDetected: true, severity: 'HIGH' };
    }

    return { isCrashDetected: false };
  }
}
