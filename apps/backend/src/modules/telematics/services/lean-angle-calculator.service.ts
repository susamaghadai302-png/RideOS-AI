import { Injectable } from '@nestjs/common';

@Injectable()
export class LeanAngleCalculatorService {
  /**
   * Computes roll/lean angle from IMU accelerometer vector components (ay, az)
   * Formula: theta = atan2(ay, az) * (180 / PI)
   */
  calculateLeanAngle(accelY: number, accelZ: number): number {
    if (accelZ === 0) return accelY >= 0 ? 90.0 : -90.0;
    const radians = Math.atan2(accelY, accelZ);
    const degrees = radians * (180.0 / Math.PI);
    return parseFloat(degrees.toFixed(1));
  }
}
