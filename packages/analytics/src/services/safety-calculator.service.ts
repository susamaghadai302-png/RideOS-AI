export class SafetyCalculatorService {
  /**
   * Calculates composite safety score from trip telemetry parameters
   */
  public static calculateSafetyScore(
    hardBrakingEvents: number,
    totalDistanceKm: number,
    avgLeanAngle: number,
  ): number {
    if (totalDistanceKm <= 0) return 100;
    const penaltyPerHardBrake = 5;
    const deduction = (hardBrakingEvents / (totalDistanceKm / 50)) * penaltyPerHardBrake;
    const score = Math.max(0, Math.min(100, 100 - deduction));
    return Math.round(score);
  }
}
