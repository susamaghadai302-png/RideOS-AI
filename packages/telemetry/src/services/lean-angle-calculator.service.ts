export class LeanAngleCalculatorService {
  /**
   * Calculates motorcycle lean angle in degrees from IMU accelerometer inputs (ay, az)
   */
  public static calculateLeanFromImu(ay: number, az: number): number {
    if (az === 0) return 0;
    const rad = Math.atan2(ay, az);
    const degrees = (rad * 180) / Math.PI;
    return Math.round(Math.abs(degrees) * 10) / 10;
  }
}
